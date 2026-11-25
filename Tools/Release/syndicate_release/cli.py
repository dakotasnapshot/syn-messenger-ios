"""One entry point; development/build and external delivery remain separate stages."""
import argparse
import json
import math
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import time
import urllib.error

from .core import Blocked, Pending, Release, atomic, canonical, digest, run
from .apple import Apple
from .github import GitHub
from . import destinations


def deliver(r):
    r.ipa()
    delivery = Apple(r).upload()
    # Prepare/reconcile the public draft and recovery before waiting for Apple.
    GitHub(r).draft()
    destinations.recovery(r)
    destinations.source(r)
    Apple(r).verify(delivery)
    manifest = GitHub(r).publish()
    destinations.website(r, manifest)
    destinations.wiki(r)
    r.state['complete'] = True
    r.save()
    notify(r)


def notify(r, blocked=False):
    cfg = r.config.get('notify')
    key = 'blocked_notification' if blocked else 'notification'
    if not cfg or r.evidence(key).get('delivered'):
        return
    if r.state['steps'].get(key, {}).get('status') == 'intent':
        raise Blocked('Completion notification outcome uncertain; reconcile before retry')
    text = f"Syndicate {r.manifest['version']} ({r.manifest['build']}) release complete: internal TestFlight, public IPA/source, website, recovery and documentation verified."
    if blocked:
        text = f"Syndicate {r.manifest['version']} ({r.manifest['build']}) release is blocked. The candidate and receipts are preserved; inspect the private release status before retrying."
    argv = [part.replace('{message}', text) for part in cfg['argv']]
    r.intent(key, {'startedAt': time.time()})
    log = r.directory / (key + '.log')
    run(argv, log=log)
    event = confirmed_notification(log.read_text())
    if not event:
        raise Blocked('Notification command returned without a confirmed Matrix event; reconcile before retry')
    r.receipt(key, {'delivered': True, 'eventId': event})


def audit(r):
    r.ipa()
    delivery = r.evidence('apple_upload').get('deliveryUUID')
    if not delivery:
        raise Blocked('No accepted Apple upload receipt')
    Apple(r).verify(delivery, write_notes=False)
    manifest = GitHub(r).verify_public()
    destinations.recovery(r, read_only=True)
    return manifest


def adopt(r, report, recovery_directory):
    if r.manifest:
        raise Blocked('Release already adopted; use audit/status')
    report = Path(report).resolve()
    c = json.loads((report / 'candidate.json').read_text())
    final = json.loads((report / 'FINAL_RECEIPT.json').read_text())
    if final['status'] != 'COMPLETE' or final['uploadCount'] != 1:
        raise Blocked('Only terminal verified releases may be adopted')
    for name in ['watch-debug.log', 'watch-release.log', 'phone-debug.log']:
        if '** BUILD SUCCEEDED **' not in (report / name).read_text():
            raise Blocked('Existing build evidence missing: ' + name)
    test = json.loads((report / 'card-summary.json').read_text())
    if test['passedTests'] <= 0 or test['failedTests'] or test['skippedTests']:
        raise Blocked('Existing native evidence failed')
    if not json.loads((report / 'validation-receipt.json').read_text())['appleValidationPassed']:
        raise Blocked('Existing Apple validation missing')
    r.manifest = {'version': c['version'], 'build': c['build']}
    api = Apple(r)
    delivery = final['upload-receipt']['deliveryUUID']
    notes = api.api('builds/' + final['testflight-ready']['buildId'] + '/betaBuildLocalizations')['data']
    notes = next(item['attributes']['whatsNew'] for item in notes if item['attributes']['locale'] == 'en-US')
    manifest = {'schema': 1, 'version': c['version'], 'build': c['build'],
                'tag': f"ios-{c['version']}-build{c['build']}",
                'ipa': {'name': c['file'], 'bytes': c['bytes'], 'sha256': c['sha256']},
                'source': {'repository': r.config['source']['repository'], 'commit': c['publicSource']},
                'notes': notes, 'verification': {'importedCompletedRelease': True, 'nativePassedTests': test['passedTests'],
                                               'signedExport': True, 'appleValidation': True, 'physicalDevice': False}}
    r.manifest = None
    ipa = report / 'export/Syndicate.ipa'
    from .build import inspect
    inspect(ipa, r, c['version'], c['build'])
    import shutil
    stable = r.directory / manifest['ipa']['name']
    if shutil.disk_usage(r.directory).free < ipa.stat().st_size * 2:
        raise Blocked('Insufficient space to adopt the verified artifact')
    shutil.copy2(ipa, stable)
    if digest(stable) != manifest['ipa']['sha256']:
        raise Blocked('Adopted artifact copy failed verification')
    r.create(manifest, stable, {'report': str(report), 'finalReceiptSHA256': digest(report / 'FINAL_RECEIPT.json')})
    r.state.update(adopted=True, recoveryDirectory=recovery_directory)
    for original, target in [('release-manifest.json', 'public-manifest.json'), ('SHA256SUMS.txt', 'SHA256SUMS.txt')]:
        (r.directory / target).write_bytes((report / 'publish' / original).read_bytes())
    r.receipt('apple_upload', {'deliveryUUID': delivery, 'imported': True})
    r.receipt('notification', {'delivered': True, 'importedAlreadyDelivered': True})
    r.save()
    audit(r)
    r.state['complete'] = True
    r.save()


def install_worker(r, config_path):
    if not r.manifest:
        raise Blocked('Prepare a validated candidate first')
    if r.state.get('complete'):
        raise Blocked('Release already complete; no worker needed')
    label = 'app.syn.release.' + r.manifest['tag']
    path = Path.home() / 'Library/LaunchAgents' / (label + '.plist')
    command = [sys.executable, str(Path(__file__).parents[1] / 'release.py'), '--config', str(config_path),
               '--state', str(r.directory), 'worker']
    data = {'Label': label, 'ProgramArguments': command, 'RunAtLoad': True,
            'KeepAlive': {'SuccessfulExit': False}, 'ThrottleInterval': 60,
            'StandardOutPath': str(r.directory / 'worker.log'), 'StandardErrorPath': str(r.directory / 'worker-error.log')}
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        if plistlib.loads(path.read_bytes()) != data:
            raise Blocked('Worker label already has a different configuration')
        raise Blocked('Worker already installed; inspect launchctl status, do not create another')
    path.write_bytes(plistlib.dumps(data))
    path.chmod(0o600)
    r.state['worker'] = {'label': label, 'plist': str(path)}
    r.save()
    run(['launchctl', 'bootstrap', 'gui/' + str(os.getuid()), str(path)])


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', default='~/.config/syndicate-release/config.json')
    parser.add_argument('--state', required=True, help='Private per-release directory, outside the repository')
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('status')
    verify = sub.add_parser('verify'); verify.add_argument('--plan', required=True)
    prepare = sub.add_parser('prepare'); prepare.add_argument('--plan', required=True); prepare.add_argument('--version', required=True); prepare.add_argument('--build', required=True)
    candidate = sub.add_parser('candidate'); candidate.add_argument('--plan', required=True); candidate.add_argument('--version', required=True); candidate.add_argument('--build', required=True)
    sub.add_parser('deliver'); sub.add_parser('worker'); sub.add_parser('install-worker'); sub.add_parser('audit')
    quiet = sub.add_parser('quiet'); quiet.add_argument('--announced-at', type=float, required=True); quiet.add_argument('--latest-user-at', type=float, required=True); quiet.add_argument('--event', required=True); quiet.add_argument('--requests-reconciled', action='store_true')
    adopt_parser = sub.add_parser('adopt'); adopt_parser.add_argument('--report', required=True); adopt_parser.add_argument('--recovery-directory', required=True)
    site = sub.add_parser('site-refresh'); site.add_argument('--revision', required=True)
    args = parser.parse_args(argv)
    config_path = Path(args.config).expanduser().resolve()
    config = json.loads(config_path.read_text())
    config['_config_path'] = str(config_path)
    try:
        r = Release(config, args.state)
    except Blocked as error:
        print(str(error), file=sys.stderr)
        return 0 if args.command == 'worker' else 2
    repo = Path(config['source']['local']).resolve()
    if r.directory.is_relative_to(repo) or config_path.is_relative_to(repo):
        raise Blocked('Private config and release state must live outside the source repository')
    if args.command == 'status':
        print(json.dumps({'release': r.manifest['tag'] if r.manifest else None, **r.state}, indent=2)); return 0
    try:
        with r.lock():
            if args.command in ('verify', 'candidate', 'prepare'):
                from . import build
                plan = json.loads(Path(args.plan).read_text())
                if args.command == 'prepare':
                    build.verify(r, plan)
                result = build.verify(r, plan) if args.command == 'verify' else build.candidate(r, plan, args.version, args.build)
                print(json.dumps(result, indent=2))
            elif args.command == 'adopt':
                adopt(r, args.report, args.recovery_directory)
            elif args.command == 'quiet':
                if not all(math.isfinite(v) and 0 < v <= time.time() for v in (args.announced_at, args.latest_user_at)):
                    raise Blocked('Quiet admission requires finite, observed timestamps')
                if not args.requests_reconciled or not args.event.startswith('$'):
                    raise Blocked('Reconcile a fresh real conversation event before admitting upload')
                r.state['quiet'] = {'announcedAt': args.announced_at, 'latestUserAt': args.latest_user_at,
                                    'checkedAt': time.time(), 'event': args.event, 'requestsReconciled': True}
                r.save()
            elif args.command == 'install-worker':
                install_worker(r, config_path)
            elif args.command == 'site-refresh':
                if not r.state.get('complete'):
                    raise Blocked('site-refresh requires a completed release')
                import re
                if not re.fullmatch(r'[A-Za-z0-9._-]{1,80}', args.revision):
                    raise Blocked('Invalid website deployment revision')
                r.state['siteRevision'] = args.revision; r.save()
                manifest = GitHub(r).verify_metadata()
                destinations.website(r, manifest)
                destinations.wiki(r)
            elif args.command == 'audit':
                audit(r)
            elif args.command == 'deliver':
                deliver(r)
            elif args.command == 'worker':
                if r.state.get('complete'):
                    try:
                        notify(r)
                    except Blocked as error:
                        r.state['blocked'] = str(error); r.save(); return 0
                while not r.state.get('complete'):
                    try:
                        started = r.state.setdefault('workerStartedAt', time.time())
                        if time.time() - started > 86400:
                            raise Blocked('Delivery wait exceeded 24 hours; inspect the preserved candidate')
                        deliver(r)
                    except Pending as error:
                        r.state['waiting'] = str(error); r.save(); time.sleep(30)
                    except (urllib.error.URLError, TimeoutError, ConnectionError) as error:
                        if isinstance(error, urllib.error.HTTPError) and error.code not in (408, 429) and error.code < 500:
                            r.state['blocked'] = 'HTTP ' + str(error.code); r.save()
                            try:
                                notify(r, blocked=True)
                            except Exception:
                                pass
                            return 0
                        r.state['waiting'] = type(error).__name__; r.save(); time.sleep(60)
                    except Blocked as error:
                        r.state['blocked'] = str(error); r.save()
                        try:
                            notify(r, blocked=True)
                        except Exception:
                            pass
                        # Deliberate block exits successfully: launchd must not retry an unsafe mutation.
                        return 2 if not r.state.get('worker') else 0
    except (Blocked, Pending) as error:
        print(str(error), file=sys.stderr)
        return 2 if isinstance(error, Blocked) else 3
    print('Verified:', args.command)
    return 0


def confirmed_notification(text):
    decoder = json.JSONDecoder()
    for index, char in enumerate(text):
        if char != '{': continue
        try: value, _ = decoder.raw_decode(text[index:])
        except ValueError: continue
        if isinstance(value, dict) and (value.get('ok') is False or value.get('dryRun') is True): return None
        def find(item):
            if isinstance(item, dict):
                for key, val in item.items():
                    if key in ('messageId', 'eventId') and isinstance(val, str) and val.startswith('$'): return val
                    result = find(val)
                    if result: return result
            if isinstance(item, list):
                for val in item:
                    result = find(val)
                    if result: return result
            return None
        found = find(value)
        if found: return found
    return None
