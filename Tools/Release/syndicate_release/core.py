"""Release identity, durable state and transport primitives. No shell command templates."""
import contextlib
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import urllib.request


class Pending(RuntimeError):
    """An external system has not finished; retry reconciliation, not the mutation."""


class Blocked(RuntimeError):
    """An operator must resolve an ambiguous or conflicting state."""


def digest(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def canonical(value):
    return (json.dumps(value, sort_keys=True, indent=2) + '\n').encode()


def atomic(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, temporary = tempfile.mkstemp(dir=path.parent, prefix='.' + path.name)
    try:
        with os.fdopen(fd, 'wb') as output:
            output.write(canonical(value))
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, path)
        directory = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def run(argv, cwd=None, log=None, env=None):
    if log:
        with Path(log).open('a') as stream:
            result = subprocess.run(argv, cwd=cwd, env=env, stdout=stream, stderr=subprocess.STDOUT)
        if result.returncode:
            raise Blocked(f'{argv[0]} failed ({result.returncode}); inspect {Path(log).name}')
        return ''
    return subprocess.check_output(argv, cwd=cwd, env=env, text=True).strip()


def request(url, method='GET', body=None, headers=None, timeout=90):
    headers = dict(headers or {})
    if body is not None:
        body = json.dumps(body).encode()
        headers['Content-Type'] = 'application/json'
    with urllib.request.urlopen(urllib.request.Request(url, data=body, method=method,
                                                       headers=headers), timeout=timeout) as response:
        return json.load(response) if response.status != 204 else None


class Release:
    def __init__(self, config, directory):
        self.config = config
        self.config_hash = hashlib.sha256(canonical({k: v for k, v in config.items() if not k.startswith('_')})).hexdigest()
        self.directory = Path(directory).expanduser().resolve()
        self.directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        self.manifest_path = self.directory / 'candidate.json'
        self.state_path = self.directory / 'status.json'
        self.manifest = json.loads(self.manifest_path.read_text()) if self.manifest_path.exists() else None
        self.state = json.loads(self.state_path.read_text()) if self.state_path.exists() else {'schema': 1, 'steps': {}}
        if self.manifest:
            self.validate_identity()
            if self.state.get('configSHA256') != self.config_hash:
                raise Blocked('Operational configuration changed; reconcile before resuming')
            if self.state.get('candidateSHA256') != digest(self.manifest_path):
                raise Blocked('Candidate identity changed; never edit a candidate in place')

    def validate_identity(self):
        import re
        m = self.manifest
        if not re.fullmatch(r'[0-9]+(?:\.[0-9]+){2}', m['version']) or not str(m['build']).isdigit():
            raise Blocked('Invalid version/build')
        tag = f"ios-{m['version']}-build{m['build']}"
        if m['tag'] != tag or m['ipa']['name'] != f"Syndicate-{m['version']}-build{m['build']}.ipa":
            raise Blocked('Artifact identity does not match release tag')
        if not re.fullmatch(r'[a-f0-9]{64}', m['ipa']['sha256']) or m['ipa']['bytes'] <= 0:
            raise Blocked('Invalid artifact digest/size')

    @contextlib.contextmanager
    def lock(self):
        with (self.directory / '.lock').open('a') as stream:
            try:
                fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError as error:
                raise Blocked('Another worker owns this release') from error
            if self.state_path.exists():
                self.state = json.loads(self.state_path.read_text())
            try:
                yield
            except (Blocked, Pending) as error:
                self.state['blocked' if isinstance(error, Blocked) else 'waiting'] = str(error)
                self.save()
                raise

    def save(self):
        atomic(self.state_path, self.state)

    def receipt(self, name, evidence):
        self.state['steps'][name] = {'status': 'verified', 'evidence': evidence}
        self.state.pop('blocked', None)
        self.state.pop('waiting', None)
        self.save()

    def intent(self, name, evidence):
        self.state['steps'][name] = {'status': 'intent', 'evidence': evidence}
        self.save()

    def evidence(self, name):
        return self.state['steps'].get(name, {}).get('evidence', {})

    def ipa(self):
        path = Path(self.state['artifact']).expanduser()
        expected = self.manifest['ipa']
        if path.stat().st_size != expected['bytes'] or digest(path) != expected['sha256']:
            raise Blocked('Local IPA no longer matches the immutable candidate')
        return path

    def create(self, manifest, artifact, evidence):
        if self.manifest_path.exists():
            raise Blocked('Candidate already exists; resume it instead')
        self.manifest = manifest
        self.validate_identity()
        atomic(self.manifest_path, manifest)
        self.state.update(candidateSHA256=digest(self.manifest_path), configSHA256=self.config_hash, artifact=str(Path(artifact).resolve()),
                          verification=evidence)
        self.save()
        self.ipa()
