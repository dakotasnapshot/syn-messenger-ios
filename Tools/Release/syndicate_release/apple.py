"""Apple submission uses a durable intent before the one irreversible upload."""
import json
import math
from pathlib import Path
import re
import subprocess
import time

from .core import Blocked, Pending, request


class Apple:
    def __init__(self, release):
        self.release = release
        self.config = release.config['apple']

    def api(self, path, method='GET', body=None):
        import jwt
        token = jwt.encode({'iss': self.config['issuer'], 'iat': int(time.time()),
                            'exp': int(time.time()) + 600, 'aud': 'appstoreconnect-v1'},
                           Path(self.config['key_file']).expanduser().read_text(), algorithm='ES256',
                           headers={'kid': self.config['key_id']})
        return request('https://api.appstoreconnect.apple.com/v1/' + path, method, body,
                       {'Authorization': 'Bearer ' + token})

    def builds(self):
        m = self.release.manifest
        return self.api(f"builds?filter[app]={self.config['app_id']}&filter[version]={m['build']}")['data']

    def upload(self):
        r = self.release
        existing = r.state['steps'].get('apple_upload')
        builds = self.builds()
        if existing:
            delivery = existing['evidence'].get('deliveryUUID')
            if delivery:
                return delivery
            # An ambiguous transfer is never repeated, even if Apple has not registered it yet.
            if len(builds) == 1:
                delivery = builds[0]['id']
                self.api('buildUploads/' + delivery)
                r.receipt('apple_upload', {'deliveryUUID': delivery, 'reconciled': True})
                return delivery
            raise Pending('Upload intent exists; waiting for Apple registration. Never reupload.')
        if builds:
            raise Blocked('Build already exists without this candidate receipt; explicitly adopt it')
        quiet = r.state.get('quiet', {})
        if not all(isinstance(quiet.get(key), (float, int)) and math.isfinite(quiet[key]) for key in ('announcedAt', 'latestUserAt', 'checkedAt')):
            raise Blocked('Invalid quiet admission timestamps')
        if not quiet.get('requestsReconciled') or time.time() - quiet.get('checkedAt', 0) > 90:
            raise Blocked('Fresh conversation review required before upload (90-second maximum age)')
        if time.time() - max(quiet.get('announcedAt', time.time()), quiet.get('latestUserAt', time.time())) < 120:
            raise Pending('Two-minute quiet gate has not elapsed')
        ipa = r.ipa()
        r.intent('apple_upload', {'sha256': r.manifest['ipa']['sha256'], 'startedAt': time.time()})
        log = r.directory / 'apple-upload.log'
        with log.open('w') as output:
            result = subprocess.run(['xcrun', 'altool', '--upload-app', '-f', str(ipa), '--type', 'ios',
                                     '--apiKey', self.config['key_id'], '--apiIssuer', self.config['issuer']],
                                    stdout=output, stderr=subprocess.STDOUT)
        text = log.read_text()
        match = re.search(r'Delivery UUID:\s*([a-fA-F0-9-]{36})', text)
        if result.returncode or 'UPLOAD SUCCEEDED' not in text or not match:
            raise Blocked('Upload outcome uncertain; inspect apple-upload.log and reconcile, never retry transfer')
        delivery = match[1]
        r.receipt('apple_upload', {'deliveryUUID': delivery, 'sha256': r.manifest['ipa']['sha256']})
        return delivery

    def verify(self, delivery, write_notes=True):
        r = self.release
        upload = self.api('buildUploads/' + delivery)['data']['attributes']['state']
        if upload['state'] in ('FAILED', 'INVALID'):
            raise Blocked('Apple rejected delivery; inspect App Store Connect')
        builds = self.builds()
        if not builds:
            raise Pending('Apple processing; build not registered')
        if len(builds) != 1:
            raise Blocked('Ambiguous Apple build identity')
        build = builds[0]
        identifier = build['id']
        attrs = build['attributes']
        if attrs['processingState'] in ('INVALID', 'FAILED'):
            raise Blocked('Apple rejected build processing')
        detail = self.api('builds/' + identifier + '/buildBetaDetail')['data']['attributes']
        group = self.config['internal_group']
        members = self.api('betaGroups/' + group + '/builds?limit=200')['data']
        if not (upload['state'] == 'COMPLETE' and attrs['processingState'] == 'VALID'
                and detail['internalBuildState'] == 'IN_BETA_TESTING'
                and any(item['id'] == identifier for item in members)):
            raise Pending('Waiting for VALID / IN_BETA_TESTING / internal-group membership')
        localizations = self.api('builds/' + identifier + '/betaBuildLocalizations')['data']
        english = next((item for item in localizations if item['attributes']['locale'] == 'en-US'), None)
        notes = r.manifest['notes']
        if write_notes and (not english or english['attributes']['whatsNew'] != notes):
            data = {'type': 'betaBuildLocalizations', 'attributes': {'locale': 'en-US', 'whatsNew': notes}}
            if english:
                data['id'] = english['id']
                data['attributes'] = {'whatsNew': notes}
                self.api('betaBuildLocalizations/' + english['id'], 'PATCH', {'data': data})
            else:
                data['relationships'] = {'build': {'data': {'type': 'builds', 'id': identifier}}}
                self.api('betaBuildLocalizations', 'POST', {'data': data})
            localizations = self.api('builds/' + identifier + '/betaBuildLocalizations')['data']
            english = next(item for item in localizations if item['attributes']['locale'] == 'en-US')
        if not english or english['attributes']['whatsNew'] != notes:
            raise Blocked('Test notes differ from candidate')
        evidence = {'deliveryUUID': delivery, 'buildId': identifier, 'processingState': attrs['processingState'],
                    'internalBuildState': detail['internalBuildState'], 'internalGroupMembershipVerified': True,
                    'notesReadbackVerified': True}
        r.receipt('testflight', evidence)
        return evidence
