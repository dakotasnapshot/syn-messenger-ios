"""GitHub is the canonical public release; published bytes are immutable."""
import hashlib
import json
from pathlib import Path
import urllib.error
import urllib.parse
import urllib.request
import zipfile
import plistlib

from .core import Blocked, canonical, digest, request


class GitHub:
    def __init__(self, release):
        self.release = release
        self.repository = release.config['github']['releases_repository']
        self.headers = {'Accept': 'application/vnd.github+json', 'User-Agent': 'Syndicate-Release/1'}

    def authenticate(self):
        config = self.release.config['github']
        credentials = Path(config['credentials_file']).expanduser().read_text().splitlines()
        credential = next((urllib.parse.urlsplit(line) for line in credentials
                           if urllib.parse.urlsplit(line).hostname == 'github.com'
                           and urllib.parse.urlsplit(line).username == config['username']), None)
        if not credential or not credential.password:
            raise Blocked('GitHub credential unavailable')
        self.headers['Authorization'] = 'Bearer ' + urllib.parse.unquote(credential.password)

    def api(self, path, method='GET', body=None):
        return request('https://api.github.com/repos/' + self.repository + '/' + path,
                       method, body, self.headers)

    def release_info(self):
        return self.api('releases/tags/' + self.release.manifest['tag'])

    def public_manifest(self):
        r = self.release
        if r.state.get('adopted'):
            return json.loads((r.directory / 'public-manifest.json').read_text())
        m = r.manifest
        return {'schema': 1, 'version': m['version'], 'build': m['build'], 'platform': 'iOS / iPadOS / watchOS',
                'source': m['source'], 'files': [{'name': m['ipa']['name'], 'size': m['ipa']['bytes'],
                                               'sha256': m['ipa']['sha256']}],
                'verification': m['verification'], 'notes': m['notes'],
                'distribution': 'App Store Connect IPA; direct installation requires appropriate re-signing/provisioning.'}

    def draft(self):
        r = self.release
        self.authenticate()
        previous = r.state['steps'].get('github_draft')
        known_id = (previous or {}).get('evidence', {}).get('id')
        if known_id:
            release = self.api('releases/' + str(known_id))
        else:
            try:
                release = self.release_info()
            except urllib.error.HTTPError as error:
                if error.code != 404:
                    raise
                if previous:
                    raise Blocked('GitHub creation intent exists but no release can be found; reconcile before creating another')
                r.intent('github_draft', {'tag': r.manifest['tag'], 'creationStarted': True})
                release = self.api('releases', 'POST', {'tag_name': r.manifest['tag'], 'target_commitish': 'main',
                                   'name': f"Syndicate {r.manifest['version']} ({r.manifest['build']})",
                                   'body': r.manifest['notes'] + '\n\nSource: ' + r.manifest['source']['repository']
                                   + '/tree/' + r.manifest['source']['commit'], 'draft': True, 'prerelease': False})
        if release['tag_name'] != r.manifest['tag'] and not (release['draft'] and release['tag_name'].startswith('untagged-')):
            raise Blocked('Conflicting GitHub release identity')
        r.intent('github_draft', {'id': release['id'], 'tag': r.manifest['tag']})
        files = {r.manifest['ipa']['name']: r.ipa(),
                 'SHA256SUMS.txt': r.directory / 'SHA256SUMS.txt',
                 'release-manifest.json': r.directory / 'public-manifest.json'}
        if not r.state.get('adopted'):
            files['SHA256SUMS.txt'].write_text(r.manifest['ipa']['sha256'] + '  ' + r.manifest['ipa']['name'] + '\n')
            files['release-manifest.json'].write_bytes(canonical(self.public_manifest()))
        assets = {asset['name']: asset for asset in release['assets']}
        for name, path in files.items():
            sha = digest(path)
            if name in assets:
                if assets[name].get('digest') != 'sha256:' + sha or assets[name]['size'] != path.stat().st_size:
                    raise Blocked('Conflicting GitHub asset: ' + name + '; never replace release bytes')
                continue
            if not release['draft']:
                raise Blocked('Published release is incomplete; never mutate it in place')
            with path.open('rb') as stream:
                req = urllib.request.Request(release['upload_url'].split('{')[0] + '?name=' + urllib.parse.quote(name),
                                             data=stream, method='POST', headers={**self.headers,
                                             'Content-Type': 'application/octet-stream',
                                             'Content-Length': str(path.stat().st_size)})
                with urllib.request.urlopen(req, timeout=900) as response:
                    asset = json.load(response)
            if asset.get('digest') != 'sha256:' + sha:
                raise Blocked('GitHub upload digest mismatch')
        release = self.api('releases/' + str(release['id']))
        r.receipt('github_draft', {'id': release['id'], 'assets': {a['name']: a['digest'] for a in release['assets']}})
        return release

    def publish(self):
        r = self.release
        if 'testflight' not in r.state['steps'] or 'recovery' not in r.state['steps']:
            raise Blocked('Internal TestFlight and verified recovery required before publication')
        release = self.draft()
        if release['draft']:
            release = self.api('releases/' + str(release['id']), 'PATCH', {'draft': False, 'tag_name': r.manifest['tag']})
        return self.verify_public()

    def verify_public(self):
        r = self.release
        release = self.release_info()
        if release['draft'] or release['tag_name'] != r.manifest['tag']:
            raise Blocked('Release is not publicly published')
        assets = {a['name']: a for a in release['assets']}
        ipa = r.manifest['ipa']
        files = {ipa['name']: r.directory / 'public-download.ipa',
                 'SHA256SUMS.txt': r.directory / 'public-SHA256SUMS.txt',
                 'release-manifest.json': r.directory / 'downloaded-manifest.json'}
        for name, destination in files.items():
            asset = assets[name]
            if name == ipa['name'] and (asset.get('digest') != 'sha256:' + ipa['sha256'] or asset['size'] != ipa['bytes']):
                raise Blocked('Public asset identity mismatch')
            # Always perform fresh anonymous readback; receipt alone is not delivery proof.
            partial = destination.with_suffix(destination.suffix + '.partial')
            h = hashlib.sha256()
            with urllib.request.urlopen(asset['browser_download_url'], timeout=120) as response, partial.open('wb') as out:
                for chunk in iter(lambda: response.read(1024 * 1024), b''):
                    if out.tell() + len(chunk) > asset['size']:
                        raise Blocked('Public download exceeds declared size')
                    h.update(chunk)
                    out.write(chunk)
            if 'sha256:' + h.hexdigest() != asset.get('digest') or partial.stat().st_size != asset['size']:
                raise Blocked('Anonymous public readback mismatch: ' + name)
            partial.replace(destination)
        with zipfile.ZipFile(files[ipa['name']]) as archive:
            info = plistlib.loads(archive.read('Payload/Syndicate.app/Info.plist'))
        if info['CFBundleVersion'] != r.manifest['build'] or info['CFBundleShortVersionString'] != r.manifest['version']:
            raise Blocked('Public IPA embedded version/build mismatch')
        manifest = json.loads(files['release-manifest.json'].read_text())
        expected = next(f for f in manifest['files'] if f['name'] == ipa['name'])
        if expected['sha256'] != ipa['sha256'] or manifest['source'] != r.manifest['source']:
            raise Blocked('Public manifest provenance mismatch')
        if files['SHA256SUMS.txt'].read_bytes() != (r.directory / 'SHA256SUMS.txt').read_bytes():
            raise Blocked('Public checksum manifest mismatch')
        r.receipt('public', {'url': assets[ipa['name']]['browser_download_url'], 'sha256': ipa['sha256'],
                             'freshAnonymousReadback': True, 'embeddedVersionReadback': True,
                             'manifestSHA256': assets['release-manifest.json']['digest'],
                             'checksumSHA256': assets['SHA256SUMS.txt']['digest']})
        return manifest

    def verify_metadata(self):
        r = self.release
        proof = r.evidence('public')
        if not proof.get('freshAnonymousReadback') or not proof.get('embeddedVersionReadback'):
            raise Blocked('A prior whole-file public IPA verification is required')
        info = self.release_info()
        assets = {a['name']: a for a in info['assets']}
        if r.state.get('adopted'):
            for key, name, filename in [('manifestSHA256', 'release-manifest.json', 'downloaded-manifest.json'), ('checksumSHA256', 'SHA256SUMS.txt', 'public-SHA256SUMS.txt')]:
                if key not in proof:
                    value = 'sha256:' + digest(r.directory / filename)
                    if assets[name].get('digest') != value:
                        raise Blocked('Adopted public evidence differs from canonical assets')
                    proof[key] = value
            r.receipt('public', proof)
        expected = {r.manifest['ipa']['name']: 'sha256:' + r.manifest['ipa']['sha256'],
                    'release-manifest.json': proof['manifestSHA256'], 'SHA256SUMS.txt': proof['checksumSHA256']}
        if info['draft'] or any(assets[n].get('digest') != sha for n, sha in expected.items()):
            raise Blocked('Canonical published metadata changed since verification')
        from .site import fetch
        payload = fetch(assets['release-manifest.json']['browser_download_url'])
        if 'sha256:' + hashlib.sha256(payload).hexdigest() != proof['manifestSHA256']:
            raise Blocked('Canonical manifest readback mismatch')
        return json.loads(payload)
