"""Development evidence -> one signed, validated candidate. No publishing here."""
import importlib.util
import json
from pathlib import Path
import plistlib
import shutil
import subprocess
import zipfile

from .core import Blocked, atomic, digest, run

REQUIRED_GATES = {'source_checks', 'native_tests', 'phone_debug', 'watch_debug', 'watch_release'}
BUNDLES = {'app.syn.messenger', 'app.syn.messenger.nse', 'app.syn.messenger.shareextension',
           'app.syn.messenger.watch', 'app.syn.messenger.watch.complications'}


def identity(repo):
    return run(['git', 'rev-parse', 'HEAD'], cwd=repo)


def source_check(release, plan):
    config = release.config
    repo, public = Path(config['source']['local']), Path(config['source']['public_checkout'])
    dirty = run(['git', 'status', '--porcelain', '--untracked-files=all'], cwd=public)
    if dirty:
        raise Blocked('Public-source checkout has uncommitted changes')
    for name in plan['source_files']:
        path = Path(name)
        if path.is_absolute() or '..' in path.parts or path.suffix in ('.p8', '.p12', '.ipa', '.mobileprovision') or path.name in ('.env', '.git-credentials', 'SyndicateServices.plist') or '.git' in path.parts or str(path).startswith('Components/Secrets/'):
            raise Blocked('Unsafe public-source file')
        import re
        for pattern in config['source'].get('private_patterns', []):
            if re.search(pattern, (repo / path).read_text(errors='replace')):
                raise Blocked('Private-string scan failed: ' + name)
        (public / path).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(repo / path, public / path)
    deleted = plan.get('deleted_files', [])
    for name in deleted:
        path = Path(name)
        if path.is_absolute() or '..' in path.parts or (repo / path).exists():
            raise Blocked('Invalid explicit source deletion')
        if (public / path).exists():
            run(['git', 'rm', '--', name], cwd=public)
    if run(['git', 'diff', '--cached', '--name-only'], cwd=public) or run(['git', 'diff', '--name-only'], cwd=public) or run(['git', 'ls-files', '--others', '--exclude-standard'], cwd=public):
        if plan['source_files']:
            run(['git', 'add', '--', *plan['source_files']], cwd=public)
        run(['git', 'commit', '-m', plan['title']], cwd=public, log=release.directory / 'source-checkpoint.log')
    for folder in ['ElementX/Sources', 'NSE/Sources', 'ShareExtension/Sources', 'SYNWatch', 'Components/SYNWatchTransport']:
        local_files = {path.relative_to(repo) for path in (repo / folder).rglob('*.swift')}
        public_files = {path.relative_to(public) for path in (public / folder).rglob('*.swift')}
        if local_files != public_files:
            raise Blocked('Local/public Swift inventory differs: ' + folder)
        for path in (repo / folder).rglob('*.swift'):
            if path.read_bytes() != (public / path.relative_to(repo)).read_bytes():
                raise Blocked('Local/public Swift mismatch: ' + str(path.relative_to(repo)))
    pins = 'ElementX.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved'
    if json.loads((repo / pins).read_text())['pins'] != json.loads((public / pins).read_text())['pins']:
        raise Blocked('Local/public dependency pins mismatch')
    return {'localCommit': identity(repo), 'publicCommit': identity(public)}


def verify(release, plan):
    repo = Path(release.config['source']['local'])
    if len(plan['gates']) != len(REQUIRED_GATES) or {gate['name'] for gate in plan['gates']} != REQUIRED_GATES:
        raise Blocked('Verification plan must include each required gate exactly once')
    clean_source(release)
    before = identity(repo)
    evidence = {'sourceCommit': before, 'planSHA256': __import__('hashlib').sha256(json.dumps(plan, sort_keys=True).encode()).hexdigest(), 'gates': {}}
    for gate in plan['gates']:
        log = release.directory / (gate['name'] + '.log')
        run(gate['argv'], cwd=repo, log=log)
        result = {'passed': True, 'logSHA256': digest(log)}
        if gate['name'] == 'native_tests':
            path = Path(gate['xcresult']).expanduser()
            summary = json.loads(run(['xcrun', 'xcresulttool', 'get', 'test-results', 'summary', '--path', str(path), '--format', 'json']))
            if summary['passedTests'] <= 0 or summary['failedTests'] or summary['skippedTests']:
                raise Blocked('Native tests must execute and pass without skips')
            result.update(passedTests=summary['passedTests'], failedTests=0, skippedTests=0)
        evidence['gates'][gate['name']] = result
    if before != identity(repo):
        raise Blocked('Source changed while verifying')
    clean_source(release)
    evidence['source'] = source_check(release, plan)
    atomic(release.directory / 'verification.json', evidence)
    return evidence


def inspect(ipa, release, version, build):
    directory = release.directory / 'inspection'
    if directory.exists():
        receipt = release.directory / 'inspection.json'
        if receipt.exists() and json.loads(receipt.read_text()) == {'sha256': digest(ipa), 'version': version, 'build': build}:
            return
        raise Blocked('Unverified inspection directory exists; preserve it and inspect before resuming')
    with zipfile.ZipFile(ipa) as archive:
        if any(Path(n).is_absolute() or '..' in Path(n).parts for n in archive.namelist()):
            raise Blocked('Unsafe IPA member')
        archive.extractall(directory)
    main = directory / 'Payload/Syndicate.app'
    found = set()
    for bundle in [main, *main.rglob('*.app'), *main.rglob('*.appex')]:
        info = plistlib.loads((bundle / 'Info.plist').read_bytes())
        identifier = info['CFBundleIdentifier']
        found.add(identifier)
        if identifier not in BUNDLES or info['CFBundleVersion'] != build or info['CFBundleShortVersionString'] != version:
            raise Blocked('Embedded bundle identity mismatch')
        run(['codesign', '--verify', '--strict', str(bundle)])
        profile = plistlib.loads(subprocess.check_output(['security', 'cms', '-D', '-i', str(bundle / 'embedded.mobileprovision')], stderr=subprocess.DEVNULL))
        import datetime
        if profile['ExpirationDate'] <= datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None):
            raise Blocked('Provisioning profile expired')
        entitlements = profile['Entitlements']
        if entitlements.get('get-task-allow') is not False or not entitlements.get('beta-reports-active'):
            raise Blocked('Export must use distribution profiles')
        if profile.get('ProvisionedDevices') or profile.get('ProvisionsAllDevices'):
            raise Blocked('Unexpected distribution method')
        expected = release.config['apple']['team'] + '.' + identifier
        signature = plistlib.loads(subprocess.check_output(['codesign', '-d', '--entitlements', ':-', str(bundle)], stderr=subprocess.DEVNULL))
        if signature.get('get-task-allow', False) or signature['application-identifier'] != expected:
            raise Blocked('Signed entitlements mismatch')
        if identifier == 'app.syn.messenger' and signature.get('aps-environment') != 'production':
            raise Blocked('Production push entitlement missing')
        if entitlements['application-identifier'] != expected:
            raise Blocked('Provisioning identity mismatch')
    if found != BUNDLES:
        raise Blocked('Required embedded components missing')
    run(['codesign', '--verify', '--deep', '--strict', str(main)])
    info = plistlib.loads((main / 'Info.plist').read_bytes())
    if info['CFBundleDisplayName'] != 'Syndicate' or set(info['UIDeviceFamily']) != {1, 2}:
        raise Blocked('Display name/device-family mismatch')
    orientations = info.get('UISupportedInterfaceOrientations~ipad', info.get('UISupportedInterfaceOrientations', []))
    if len(set(orientations)) != 4:
        raise Blocked('All iPad orientations required')
    helper = Path(release.config['source']['local']) / 'Tools/Scripts/configure-giphy.py'
    spec = importlib.util.spec_from_file_location('giphy', helper)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    key = plistlib.loads((main / 'SyndicateServices.plist').read_bytes()).get('GiphyAPIKey')
    if not key or key != module.configured_key():
        raise Blocked('Bundled service configuration missing or incorrect')
    icons = list(main.glob('AppIcon*.png'))
    if not icons or any('hasAlpha: no' not in run(['sips', '-g', 'hasAlpha', str(p)]) for p in icons):
        raise Blocked('Compiled app icons missing or transparent')

    atomic(release.directory / 'inspection.json', {'sha256': digest(ipa), 'version': version, 'build': build})


def candidate(release, plan, version, build):
    if release.manifest:
        raise Blocked('Candidate exists; resume delivery, do not rebuild')
    evidence = json.loads((release.directory / 'verification.json').read_text())
    repo = Path(release.config['source']['local'])
    clean_source(release)
    if identity(Path(release.config['source']['public_checkout'])) != evidence['source']['publicCommit']:
        raise Blocked('Public source changed since verification')
    if identity(repo) != evidence['sourceCommit']:
        raise Blocked('Source changed since verification')
    from .apple import Apple
    dummy = {'version': version, 'build': build}
    release.manifest = dummy
    if Apple(release).builds():
        raise Blocked('Build number already exists at Apple')
    release.manifest = None
    archive = release.directory / 'Syndicate.xcarchive'
    archive_done = archive.exists() and (release.directory / 'archive.log').exists() and '** ARCHIVE SUCCEEDED **' in (release.directory / 'archive.log').read_text()
    if archive.exists() and not archive_done:
        raise Blocked('Incomplete archive preserved; inspect it before choosing a fresh build directory')
    import re
    settings = (repo / 'project.yml').read_text()
    if re.search(r'CURRENT_PROJECT_VERSION:\s*(\d+)', settings).group(1) != build or re.search(r'MARKETING_VERSION:\s*([0-9.]+)', settings).group(1) != version:
        raise Blocked('Commit the intended version/build before preparing a candidate')
    apple = release.config['apple']
    auth = ['-allowProvisioningUpdates', '-authenticationKeyPath', str(Path(apple['key_file']).expanduser()),
            '-authenticationKeyID', apple['key_id'], '-authenticationKeyIssuerID', apple['issuer']]
    if not archive_done:
        run(['xcodebuild', '-project', 'ElementX.xcodeproj', '-scheme', 'ElementX', '-configuration', 'Release',
         '-destination', 'generic/platform=iOS', '-archivePath', str(archive), '-jobs', '2', *auth, 'archive'],
        cwd=repo, log=release.directory / 'archive.log')
    export = release.directory / 'export'
    if not (export / 'Syndicate.ipa').exists():
        run(['xcodebuild', '-exportArchive', '-archivePath', str(archive), '-exportPath', str(export),
         '-exportOptionsPlist', str(Path(apple['export_options']).expanduser()), *auth],
        cwd=repo, log=release.directory / 'export.log')
    ipa = export / 'Syndicate.ipa'
    inspect(ipa, release, version, build)
    run(['xcrun', 'altool', '--validate-app', '-f', str(ipa), '--type', 'ios', '--apiKey', apple['key_id'],
         '--apiIssuer', apple['issuer']], log=release.directory / 'apple-validation.log')
    if 'VERIFY SUCCEEDED' not in (release.directory / 'apple-validation.log').read_text() and 'VALIDATE SUCCEEDED' not in (release.directory / 'apple-validation.log').read_text():
        raise Blocked('Apple validation did not confirm success')
    if identity(repo) != evidence['sourceCommit']:
        raise Blocked('Source changed during archive; candidate not admitted')
    clean_source(release)
    manifest = {'schema': 1, 'version': version, 'build': build, 'tag': f'ios-{version}-build{build}',
                'ipa': {'name': f'Syndicate-{version}-build{build}.ipa', 'bytes': ipa.stat().st_size, 'sha256': digest(ipa)},
                'source': {'repository': release.config['source']['repository'], 'commit': evidence['source']['publicCommit']},
                'notes': plan['notes'], 'verification': {'gates': sorted(REQUIRED_GATES), 'signedExport': True,
                                                       'appleValidation': True, 'physicalDevice': plan.get('physical_device', False)}}
    release.create(manifest, ipa, evidence)
    return manifest


def clean_source(release):
    import fnmatch
    repo = Path(release.config['source']['local'])
    allowed = release.config['source'].get('allowed_dirty', [])
    for line in subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=all'], cwd=repo, text=True).splitlines():
        name = line[3:]
        if not any(fnmatch.fnmatchcase(name, pattern) for pattern in allowed):
            raise Blocked('Commit source before verification: ' + name)
