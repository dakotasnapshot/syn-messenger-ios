import contextlib
import copy
import io
import json
from pathlib import Path
import shlex
import tempfile
import time
import unittest
from unittest.mock import patch

import sys
sys.path.insert(0, str(Path(__file__).parents[1]))
from syndicate_release.core import Blocked, Pending, Release, atomic, digest
from syndicate_release.apple import Apple
from syndicate_release.cli import notify, install_worker, confirmed_notification
from syndicate_release.site import metadata, render
from syndicate_release import destinations


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.ipa = self.root / 'artifact.ipa'; self.ipa.write_bytes(b'synthetic artifact')
        self.config = {'apple': {'app_id': 'synthetic', 'internal_group': 'internal', 'key_id': 'synthetic', 'issuer': 'synthetic'},
                       'github': {'releases_repository': 'example/releases'}, 'source': {'local': str(self.root / 'repo')}}
        self.manifest = {'schema': 1, 'version': '1.2.3', 'build': '4', 'tag': 'ios-1.2.3-build4',
                         'ipa': {'name': 'Syndicate-1.2.3-build4.ipa', 'bytes': self.ipa.stat().st_size,
                                 'sha256': digest(self.ipa)}, 'source': {'repository': 'https://github.com/example/source',
                                                                      'commit': 'a' * 40},
                         'notes': 'Synthetic notes', 'verification': {}}
        self.r = Release(self.config, self.root / 'state')
        self.r.create(self.manifest, self.ipa, {})

    def tearDown(self):
        self.temporary.cleanup()

    def test_candidate_tamper_rejected(self):
        value = copy.deepcopy(self.manifest); value['notes'] = 'changed'
        atomic(self.r.manifest_path, value)
        with self.assertRaises(Blocked): Release(self.config, self.r.directory)

    def test_changed_artifact_rejected(self):
        self.ipa.write_bytes(b'changed')
        with self.assertRaises(Blocked): self.r.ipa()

    def test_second_worker_cannot_acquire_lock(self):
        other = Release(self.config, self.r.directory)
        with self.r.lock():
            with self.assertRaises(Blocked):
                with other.lock(): pass

    def test_lock_reloads_latest_receipts(self):
        other = Release(self.config, self.r.directory)
        self.r.receipt('completed', {'verified': True})
        with other.lock(): self.assertTrue(other.evidence('completed')['verified'])

    def test_atomic_state_is_private(self):
        self.assertEqual(self.r.state_path.stat().st_mode & 0o777, 0o600)

    def test_existing_upload_intent_never_reuploads(self):
        self.r.intent('apple_upload', {'startedAt': time.time()})
        with patch.object(Apple, 'builds', return_value=[]), patch('subprocess.run') as command:
            with self.assertRaises(Pending): Apple(self.r).upload()
            command.assert_not_called()

    def test_missing_receipt_existing_build_requires_adoption(self):
        with patch.object(Apple, 'builds', return_value=[{'id': 'build'}]), patch('subprocess.run') as command:
            with self.assertRaises(Blocked): Apple(self.r).upload()
            command.assert_not_called()

    def test_upload_requires_fresh_conversation_review(self):
        with patch.object(Apple, 'builds', return_value=[]):
            with self.assertRaises(Blocked): Apple(self.r).upload()

    def test_nonfinite_quiet_gate_rejected(self):
        self.r.state['quiet'] = {'requestsReconciled':True,'checkedAt':time.time(),'announcedAt':float('nan'),'latestUserAt':time.time()-1000}
        with patch.object(Apple,'builds',return_value=[]), patch('subprocess.run') as command:
            with self.assertRaises(Blocked): Apple(self.r).upload()
            command.assert_not_called()

    def test_quiet_gate_cannot_be_skipped(self):
        self.r.state['quiet'] = {'requestsReconciled': True, 'checkedAt': time.time(),
                                 'announcedAt': time.time(), 'latestUserAt': time.time() - 1000}
        with patch.object(Apple, 'builds', return_value=[]), patch('subprocess.run') as command:
            with self.assertRaises(Pending): Apple(self.r).upload()
            command.assert_not_called()

    def test_interrupted_upload_is_durably_ambiguous(self):
        self.r.state['quiet'] = {'requestsReconciled': True, 'checkedAt': time.time(),
                                 'announcedAt': time.time() - 130, 'latestUserAt': time.time() - 1000}
        with patch.object(Apple, 'builds', return_value=[]), patch('subprocess.run', side_effect=OSError('synthetic interruption')):
            with self.assertRaises(OSError): Apple(self.r).upload()
        reopened = Release(self.config, self.r.directory)
        self.assertEqual(reopened.state['steps']['apple_upload']['status'], 'intent')
        with patch.object(Apple, 'builds', return_value=[]), patch('subprocess.run') as command:
            with self.assertRaises(Pending): Apple(reopened).upload()
            command.assert_not_called()

    def test_known_delivery_returns_without_upload(self):
        self.r.receipt('apple_upload', {'deliveryUUID': 'existing'})
        with patch.object(Apple, 'builds', return_value=[]), patch('subprocess.run') as command:
            self.assertEqual(Apple(self.r).upload(), 'existing'); command.assert_not_called()

    def test_processing_is_not_tester_availability(self):
        with patch.object(Apple, 'api', return_value={'data': {'attributes': {'state': {'state': 'PROCESSING'}}}}), patch.object(Apple, 'builds', return_value=[]):
            with self.assertRaises(Pending): Apple(self.r).verify('delivery')
        self.assertNotIn('testflight', self.r.state['steps'])

    def test_uncertain_notification_does_not_mark_delivery_complete(self):
        from syndicate_release.cli import deliver
        from syndicate_release.github import GitHub
        self.r.config['notify']={'argv':['synthetic','{message}']}
        self.r.intent('notification',{})
        with patch.object(Apple,'upload',return_value='existing'), patch.object(Apple,'verify'), patch.object(GitHub,'draft'), patch.object(GitHub,'publish',return_value={}), patch.object(destinations,'recovery'), patch.object(destinations,'source'), patch.object(destinations,'website'), patch.object(destinations,'wiki'):
            with self.assertRaises(Blocked): deliver(self.r)
        self.assertTrue(self.r.state['destinationsComplete'])
        self.assertFalse(self.r.state.get('complete',False))

    def test_notification_is_not_repeated(self):
        self.r.config['notify'] = {'argv': ['synthetic', '{message}']}
        self.r.receipt('notification', {'delivered': True})
        with patch('syndicate_release.cli.run') as command:
            notify(self.r); command.assert_not_called()

    def test_ambiguous_notification_is_not_retried(self):
        self.r.config['notify'] = {'argv': ['synthetic', '{message}']}
        self.r.intent('notification', {})
        with patch('syndicate_release.cli.run') as command:
            with self.assertRaises(Blocked): notify(self.r)
            command.assert_not_called()

    def test_notification_requires_real_event_not_internal_id(self):
        self.assertEqual(confirmed_notification('banner\n{"result":{"messageId":"$real"}}'), '$real')
        self.assertIsNone(confirmed_notification('{"messageId":"internal-uuid"}'))
        self.assertIsNone(confirmed_notification('{"ok":false,"messageId":"$not-delivered"}'))
        self.assertIsNone(confirmed_notification('{"dryRun":true,"messageId":"$not-delivered"}'))

    def test_worker_resumes_pending_without_chat(self):
        from syndicate_release.cli import main
        config_path = self.root / 'config.json'; config_path.write_text(json.dumps(self.config))
        calls = []
        def process(release):
            calls.append(1)
            if len(calls) == 1: raise Pending('synthetic Apple wait')
            release.state['complete'] = True; release.save()
        with patch('syndicate_release.cli.deliver', process), patch('syndicate_release.cli.time.sleep') as sleep:
            self.assertEqual(main(['--config',str(config_path),'--state',str(self.r.directory),'worker']),0)
            self.assertEqual(len(calls),2); sleep.assert_called_once_with(30)

    def test_deliberate_worker_block_does_not_restart(self):
        from syndicate_release.cli import main
        config_path = self.root / 'config.json'; config_path.write_text(json.dumps(self.config))
        self.r.state['worker'] = {'label':'synthetic'}; self.r.save()
        with patch('syndicate_release.cli.deliver', side_effect=Blocked('synthetic conflict')), patch('syndicate_release.cli.time.sleep') as sleep:
            self.assertEqual(main(['--config',str(config_path),'--state',str(self.r.directory),'worker']),0)
            sleep.assert_not_called()
        self.assertEqual(json.loads(self.r.state_path.read_text())['blocked'],'synthetic conflict')

    def test_worker_deadline_blocks_without_new_actions(self):
        from syndicate_release.cli import main
        config_path = self.root / 'config.json'; config_path.write_text(json.dumps(self.config))
        self.r.state.update(worker={'label':'synthetic'}, workerStartedAt=time.time()-86401); self.r.save()
        with patch('syndicate_release.cli.deliver') as action:
            self.assertEqual(main(['--config',str(config_path),'--state',str(self.r.directory),'worker']),0)
            action.assert_not_called()

    def test_worker_is_a_dedicated_user_agent(self):
        import plistlib
        with patch('syndicate_release.cli.Path.home',return_value=self.root), patch('syndicate_release.cli.run') as command:
            install_worker(self.r,self.root/'config.json')
            self.assertEqual(command.call_args.args[0][:2],['launchctl','bootstrap'])
            path=self.root/'Library/LaunchAgents/app.syn.release.ios-1.2.3-build4.plist'
            agent=plistlib.loads(path.read_bytes())
            self.assertEqual(agent['KeepAlive'],{'SuccessfulExit':False})
            self.assertEqual(agent['ProgramArguments'][-1],'worker')
            self.assertIn('/opt/homebrew/bin',agent['EnvironmentVariables']['PATH'])
            self.assertEqual(agent['WorkingDirectory'],self.config['source']['local'])
            self.assertNotIn('gateway',' '.join(agent['ProgramArguments']))

    def test_completed_release_does_not_install_worker(self):
        self.r.state['complete'] = True
        with self.assertRaises(Blocked): install_worker(self.r, self.root / 'config.json')

    def test_ambiguous_github_creation_never_creates_duplicate(self):
        import urllib.error
        from syndicate_release.github import GitHub
        self.r.intent('github_draft', {'creationStarted':True})
        missing=urllib.error.HTTPError('https://example.invalid',404,'missing',{},None)
        with patch.object(GitHub,'authenticate'), patch.object(GitHub,'release_info',side_effect=missing), patch.object(GitHub,'api') as mutation:
            with self.assertRaises(Blocked): GitHub(self.r).draft()
            mutation.assert_not_called()

    def test_metadata_uses_canonical_release(self):
        manifest = {'version': '1.2.3', 'build': '4', 'source': self.manifest['source'],
                    'files': [{'name': self.manifest['ipa']['name'], 'size': 12, 'sha256': 'a' * 64}]}
        data = metadata(manifest, 'example/releases')
        self.assertIn('/ios-1.2.3-build4/Syndicate-1.2.3-build4.ipa', data['url'])
        manifest['version'] = '<script>'
        with self.assertRaises(Blocked): metadata(manifest, 'example/releases')

    def test_frontend_preserves_other_platforms_and_fallback(self):
        html = '<section class="download" id="ios-download"><a class="button" href="old">Download iPhone / iPad IPA</a><p>Version 0.0.1 · Build 1</p>IPA SHA-256: <code>' + 'b' * 64 + '</code></section><section id="loader">KEEP</section><script src="/downloads/loader-release.js"></script>'
        data = {'version': '1.2.3', 'build': '4', 'url': 'https://example.invalid/artifact', 'sha256': 'a' * 64}
        result = render(html, data)
        self.assertIn('<section id="loader">KEEP</section>', result)
        self.assertIn('data-ios-download', result)
        self.assertIn('Version 1.2.3 · Build 4', result)
        self.assertEqual(render(result, data), result)

    def test_server_rejects_stale_release_downgrade(self):
        from syndicate_release.site import prepare
        self.r.config['website']={'public_url':'https://example.invalid/downloads'}
        manifest={'version':'1.2.3','build':'4','source':self.manifest['source'],'files':[{'name':self.manifest['ipa']['name'],'size':12,'sha256':'a'*64}]}
        html='<section class="download" id="ios-download"><p>Version 1.2.3 · Build 9</p></section>'.encode()
        with patch('syndicate_release.site.fetch',side_effect=[html,b'old checksums']):
            with self.assertRaises(Blocked): prepare(self.r,manifest)

    def test_frontend_fails_closed_on_unrecognized_markup(self):
        with self.assertRaises(Blocked): render('<html>unexpected</html>', {})

    def test_recovery_read_only_never_copies_missing_file(self):
        self.r.config['recovery'] = {'host': 'synthetic', 'mount': '/synthetic', 'mount_identity': 'synthetic', 'directory': '/synthetic/releases'}
        (self.r.directory / 'SHA256SUMS.txt').write_text('test')
        (self.r.directory / 'public-manifest.json').write_text('{}')
        with patch.object(destinations, 'remote', return_value={'exists': False, 'matches': False, 'free': 100000}), patch.object(destinations, 'run') as command:
            with self.assertRaises(Blocked): destinations.recovery(self.r, read_only=True)
            command.assert_not_called()

    def test_source_sync_handles_explicit_committed_deletions(self):
        import subprocess
        from syndicate_release.build import source_check
        repos=[]
        for name in ['local','public']:
            repo=self.root/name;repo.mkdir();repos.append(repo)
            def git(*args):return subprocess.check_output(['git',*args],cwd=repo,stderr=subprocess.DEVNULL)
            git('init');git('config','user.email','synthetic@example.invalid');git('config','user.name','Synthetic')
            (repo/'SYNWatch').mkdir();(repo/'SYNWatch/Old.swift').write_text('struct Old {}')
            pin=repo/'ElementX.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved';pin.parent.mkdir(parents=True);pin.write_text('{"pins":[]}')
            git('add','.');git('commit','-m','Synthetic baseline')
        local,public=repos
        subprocess.run(['git','rm','SYNWatch/Old.swift'],cwd=local,check=True,stdout=subprocess.DEVNULL)
        subprocess.run(['git','commit','-m','Remove synthetic source'],cwd=local,check=True,stdout=subprocess.DEVNULL)
        self.r.config['source'].update(local=str(local),public_checkout=str(public))
        source_check(self.r,{'source_files':[],'deleted_files':['SYNWatch/Old.swift'],'title':'Remove synthetic source'})
        self.assertFalse((public/'SYNWatch/Old.swift').exists())

    def test_partial_frontend_deploy_resumes_exact_plan(self):
        root = self.root / 'site'; root.mkdir()
        for name in ['index.html', 'SHA256SUMS.txt']: (root / name).write_bytes(b'old')
        (root / 'protected.js').write_bytes(b'keep')
        self.r.config['website'] = {'host': 'synthetic', 'directory': str(root), 'rollback_directory': str(self.root / 'rollback'),
                                    'public_url': 'https://example.invalid/downloads', 'protected_files': ['protected.js']}
        payloads = {name: ('new-' + name).encode() for name in ['index.html', 'SHA256SUMS.txt', 'ios-release.json', 'ios-release.js']}
        def local_remote(host, code):
            output = io.StringIO()
            with contextlib.redirect_stdout(output): exec(code, {})
            return json.loads(output.getvalue())
        def local_run(argv, **kwargs):
            code = shlex.split(argv[-1])[-1]
            with contextlib.redirect_stdout(io.StringIO()): exec(code, {})
            return ''
        calls = [0]
        original_replace = Path.replace
        def interrupted_replace(path, target):
            calls[0] += 1
            if calls[0] == 3: raise OSError('synthetic interruption')
            return original_replace(path, target)
        with patch('syndicate_release.site.prepare', return_value=payloads), patch.object(destinations, 'remote', local_remote), patch.object(destinations, 'run', local_run), patch('syndicate_release.site.fetch', side_effect=lambda url: (root / ('index.html' if url.endswith('/') else url.rsplit('/', 1)[1])).read_bytes()):
            with patch.object(Path, 'replace', interrupted_replace):
                with self.assertRaises(OSError): destinations.website(self.r, {})
            destinations.website(self.r, {})
            for name, data in payloads.items(): self.assertEqual((root / name).read_bytes(), data)
            self.assertEqual((root / 'protected.js').read_bytes(), b'keep')


if __name__ == '__main__': unittest.main()
