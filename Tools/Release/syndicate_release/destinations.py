"""Private operational adapters. Addresses and credential references live outside git."""
import base64
import hashlib
import json
from pathlib import Path
import shlex
import subprocess

from .core import Blocked, canonical, digest, request, run


def remote(host, code):
    return json.loads(run(['ssh', '-o', 'BatchMode=yes', host, 'python3 -c ' + shlex.quote(code)]))


def recovery(release, read_only=False):
    r = release
    cfg = r.config['recovery']
    files = [r.ipa(), r.directory / 'SHA256SUMS.txt', r.directory / 'public-manifest.json']
    target = r.state.get('recoveryDirectory') or cfg['directory'].rstrip('/') + '/' + r.manifest['tag']
    receipts = {}
    for file in files:
        name = r.manifest['ipa']['name'] if file == files[0] else ('release-manifest.json' if file.name == 'public-manifest.json' else file.name)
        sha, size = digest(file), file.stat().st_size
        spec = {'mount': cfg['mount'], 'mount_identity': cfg['mount_identity'], 'directory': target,
                'name': name, 'sha': sha, 'bytes': size}
        prefix = '''from pathlib import Path
import hashlib,json,subprocess,shutil,os
s=json.loads(%r)
v=Path(s['mount']);assert v.is_mount()
assert s['mount_identity'] in subprocess.check_output(['mount'],text=True)
p=Path(s['directory']);assert p.resolve().is_relative_to(v.resolve());p.mkdir(parents=True,exist_ok=True,mode=0o700)
q=p/s['name']
def sha(path):
 h=hashlib.sha256()
 with path.open('rb') as f:
  for b in iter(lambda:f.read(1048576),b''):h.update(b)
 return h.hexdigest()
''' % json.dumps(spec)
        if read_only:
            prefix = prefix.replace("p.mkdir(parents=True,exist_ok=True,mode=0o700)", "None;assert p.is_dir()")
        state = remote(cfg['host'], prefix + "\nprint(json.dumps({'exists':q.exists(),'matches':q.exists() and q.stat().st_size==s['bytes'] and sha(q)==s['sha'],'free':shutil.disk_usage(v).free}))")
        if state['exists'] and not state['matches']:
            raise Blocked('Conflicting recovery file; never overwrite it')
        if not state['matches']:
            if read_only:
                raise Blocked('Recovery read-only audit found a missing file')
            if state['free'] < size * 2:
                raise Blocked('Recovery destination lacks admitted free space')
            partial = target + '/' + name + '.partial-' + sha[:12]
            run(['scp', '-q', str(file), cfg['host'] + ':' + partial])
            remote(cfg['host'], prefix + "\nt=Path(" + repr(partial) + ");assert t.stat().st_size==s['bytes'] and sha(t)==s['sha'];t.chmod(0o600);t.replace(q);print(json.dumps({'copied':True}))")
        receipts[name] = remote(cfg['host'], prefix + "\nassert q.stat().st_size==s['bytes'] and sha(q)==s['sha'];print(json.dumps({'sha256':s['sha'],'bytes':s['bytes'],'freshReadback':True,'mountVerified':True}))")
    r.receipt('recovery', receipts)


def source(release):
    r = release
    cfg = r.config['source']
    repo = Path(cfg['public_checkout'])
    commit = r.manifest['source']['commit']
    if subprocess.run(['git', 'merge-base', '--is-ancestor', commit, 'HEAD'], cwd=repo, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
        raise Blocked('Candidate source is not an ancestor of the public checkout')
    remote_head = run(['git', 'ls-remote', cfg['remote'], cfg['ref']], cwd=repo).split()[0]
    head = run(['git', 'rev-parse', 'HEAD'], cwd=repo)
    # Require an ordinary fast-forward; never force or overwrite a concurrent source push.
    if subprocess.run(['git', 'merge-base', '--is-ancestor', remote_head, head], cwd=repo, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
        raise Blocked('Public source changed concurrently; reconcile before pushing')
    import os
    env = os.environ.copy()
    env.update(GIT_ASKPASS=str(Path(__file__).parents[1] / 'git-askpass.py'), GIT_TERMINAL_PROMPT='0', SYNDICATE_RELEASE_CONFIG=r.config['_config_path'])
    run(['git', '-c', 'credential.helper=', 'push', cfg['remote'], 'HEAD:' + cfg['ref']], cwd=repo, env=env, log=r.directory / 'source-push.log')
    public = r.manifest['source']['repository']
    for name in cfg['verify_files']:
        url = public.replace('https://github.com/', 'https://raw.githubusercontent.com/') + '/' + commit + '/' + name
        from .site import fetch
        original = subprocess.check_output(['git', 'show', commit + ':' + name], cwd=repo)
        if fetch(url) != original:
            raise Blocked('Public source readback mismatch')
    r.receipt('source', {'commit': commit, 'pushedHead': head, 'anonymousReadback': True})


def website(release, manifest):
    from .site import prepare, fetch
    r = release
    cfg = r.config['website']
    payloads = prepare(r, manifest)
    # Store a replayable compare-and-swap plan before any remote write.
    revision = r.state.get('siteRevision')
    plan_path = r.directory / ('website-plan' + ('-' + revision if revision else '') + '.json')
    if plan_path.exists():
        plan = json.loads(plan_path.read_text())
    else:
        plan = {'directory': cfg['directory'], 'rollback': cfg['rollback_directory'] + '/' + r.manifest['tag'], 'files': []}
        for name, data in payloads.items():
            previous = remote(cfg['host'], "from pathlib import Path;import hashlib,json;p=Path(" + repr(cfg['directory'] + '/' + name) + ");print(json.dumps({'sha':hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None}))")['sha']
            plan['files'].append({'name': name, 'before': previous, 'after': hashlib.sha256(data).hexdigest(),
                                  'base64': base64.b64encode(data).decode()})
        protected = cfg['protected_files']
        plan['protected'] = remote(cfg['host'], "from pathlib import Path;import hashlib,json;p=Path(" + repr(cfg['directory']) + ");print(json.dumps({n:hashlib.sha256((p/n).read_bytes()).hexdigest() for n in " + repr(protected) + "}))")
        from .core import atomic
        atomic(plan_path, plan)
    code = '''from pathlib import Path
import hashlib,json,base64,os,stat,shutil
plan=json.loads(%r);root=Path(plan['directory']);rollback=Path(plan['rollback'])
assert {f['name'] for f in plan['files']}=={'index.html','SHA256SUMS.txt','ios-release.json','ios-release.js'}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
assert {n:sha(root/n) for n in plan['protected']}==plan['protected'],'Protected platform metadata changed'
for f in plan['files']:assert sha(root/f['name']) in [f['before'],f['after']],'Concurrent frontend change'
rollback.mkdir(parents=True,exist_ok=True,mode=0o700)
# Metadata/assets first, HTML last. A partial replay accepts only the exact planned after-state.
for f in sorted(plan['files'],key=lambda f:f['name']=='index.html'):
 p=root/f['name'];data=base64.b64decode(f['base64']);assert hashlib.sha256(data).hexdigest()==f['after']
 if sha(p)==f['after']:continue
 backup=rollback/f['name']
 if p.exists() and not backup.exists():shutil.copy2(p,backup)
 info=p.stat() if p.exists() else root.stat();t=p.with_name('.'+p.name+'.release-partial')
 with t.open('wb') as out:out.write(data);out.flush();os.fsync(out.fileno())
 t.chmod(stat.S_IMODE(info.st_mode) if p.exists() else 0o644);os.chown(t,info.st_uid,info.st_gid);t.replace(p)
 assert sha(p)==f['after']
assert {n:sha(root/n) for n in plan['protected']}==plan['protected']
print(json.dumps({'saved':True}))
''' % json.dumps(plan)
    argv = ['ssh', '-o', 'BatchMode=yes', cfg['host'], ('sudo -n ' if cfg.get('sudo') else '') + 'python3 -c ' + shlex.quote(code)]
    run(argv, log=r.directory / 'website-deploy.log')
    proof = {}
    for file in plan['files']:
        url = cfg['public_url'].rstrip('/') + '/' + ('' if file['name'] == 'index.html' else file['name'])
        if hashlib.sha256(fetch(url)).hexdigest() != file['after']:
            raise Blocked('Live frontend readback mismatch: ' + file['name'])
        proof[file['name']] = file['after']
    r.receipt('website', {'publicReadback': proof, 'protectedFilesUnchanged': True})


def wiki(release):
    r = release
    cfg = r.config['wiki']
    token = Path(cfg['token_file']).expanduser().read_text().strip()
    def gql(query, variables=None):
        result = request(cfg['url'].rstrip('/') + '/graphql', 'POST', {'query': query, 'variables': variables or {}},
                         {'Authorization': 'Bearer ' + token})
        if result.get('errors'):
            raise Blocked('Wiki GraphQL request failed')
        return result['data']
    gql('query{pages{search(query:"Syndicate"){results{id path title}}}}')
    query = 'query($id:Int!){pages{single(id:$id){id path title description editor content isPublished isPrivate locale tags{tag}}}}'
    page = gql(query, {'id': cfg['page_id']})['pages']['single']
    if page['path'] != cfg['page_path']:
        raise Blocked('Wiki operational page identity mismatch')
    m = r.manifest
    block = f"""
<!-- syndicate-release-runner:start -->
## Current iOS release and delivery lane

Syndicate **{m['version']} ({m['build']})**: VALID / IN_BETA_TESTING; existing internal group verified.

Canonical assets, checksum and source: https://github.com/{r.config['github']['releases_repository']}/releases/tag/{m['tag']}

Operational runbook: {m['source']['repository']}/blob/syn/main/Tools/Release/README.md

- Architecture: committed development/tests → immutable signed candidate → resumable native delivery. GitHub is the public release authority; the website is a generated snapshot, not a separate hand-maintained version store.
- Private profile: `~/.config/syndicate-release/config.json`; it contains credential references, never publish it. Private environment, stable public-source checkout and per-release state: `~/.local/share/syndicate-release/`. Existing Apple/GitHub/wiki credentials remain outside git.
- Status: run the private environment's Python with `Tools/Release/release.py --state ~/.local/share/syndicate-release/releases/<tag> status`. `audit` performs fresh Apple/public/recovery reconciliation without a new upload. Inspect `status.json`, destination logs and immutable website CAS plans for blockers.
- Future delivery worker: dedicated user LaunchAgent `app.syn.release.<tag>` in `~/Library/LaunchAgents/`, installed only for a validated/admitted candidate. It survives chat termination, retries transient waits for at most 24 hours and exits cleanly on deliberate blocks. It does not change/restart OpenClaw or add a cron/model poller. Inspect with `launchctl print gui/<uid>/app.syn.release.<tag>`; resume only after inspecting its receipts.
- Dependencies: Xcode/signing tools, private Python environment with PyJWT/cryptography, GitHub/App Store Connect, SSH access to the existing recovery and web hosts, and this wiki. Partial failures preserve the candidate and receipts; accepted uploads are never blindly repeated.
- Storage: archive/export/evidence and the adopted immutable IPA stay private/local; verified IPA/checksum/manifest copies remain on the existing mounted recovery destination. Mount identity, capacity admission and fresh whole-file hashes are required. No automatic deletion/pruning or backup-schedule change is introduced.
- Website: same-origin `ios-release.json` plus generated static mobile fallback; browsers do not call GitHub APIs. Only mobile metadata/assets/index and historical checksum manifest are written. Loader, desktop, counters and account data remain protected. Newer server/static build numbers reject stale-release downgrades.
- Rollback: use the candidate's private `website-plan*.json` and reviewed before-state copies on the web host under `{r.config['website']['rollback_directory']}/<tag>`. Restore only matching metadata after checking current hashes; preserve immutable GitHub assets and historical releases. A conflicting before-hash stops deployment.
- Acceptance limits: the existing completed build was reconciled without another build/upload. Worker crash/intent/locking behavior is covered by synthetic tests; the first future real upload through the new LaunchAgent is not yet observed. Physical-device acceptance is recorded per candidate and cannot be inferred from simulator tests.
<!-- syndicate-release-runner:end -->
"""

    import re
    pattern = r'\n<!-- syndicate-release-runner:start -->.*?<!-- syndicate-release-runner:end -->\n'
    content = re.sub(pattern, lambda _: block, page['content'], flags=re.S) if re.search(pattern, page['content'], re.S) else page['content'] + block
    if content != page['content']:
        if gql(query, {'id': cfg['page_id']})['pages']['single']['content'] != page['content']:
            raise Blocked('Concurrent wiki change')
        values = {key: page[key] for key in ['id', 'path', 'title', 'description', 'editor', 'isPublished', 'isPrivate', 'locale']}
        values.update(tags=[item['tag'] for item in page['tags']], content=content)
        mutation = 'mutation($id:Int!,$path:String!,$title:String!,$description:String!,$editor:String!,$isPublished:Boolean!,$isPrivate:Boolean!,$locale:String!,$tags:[String]!,$content:String!){pages{update(id:$id,path:$path,title:$title,description:$description,editor:$editor,isPublished:$isPublished,isPrivate:$isPrivate,locale:$locale,tags:$tags,content:$content){responseResult{succeeded}}}}'
        if not gql(mutation, values)['pages']['update']['responseResult']['succeeded']:
            raise Blocked('Wiki save failed')
    if gql(query, {'id': cfg['page_id']})['pages']['single']['content'] != content:
        raise Blocked('Wiki saved-content readback mismatch')
    r.receipt('wiki', {'url': cfg['url'].rstrip('/') + '/en/' + page['path'], 'savedReadback': True})
