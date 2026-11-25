"""Generate the mobile front end from a verified GitHub manifest, never hand-edited versions."""
import json
import re
import urllib.request

from .core import Blocked, canonical


def metadata(manifest, repository):
    version, build = str(manifest['version']), str(manifest['build'])
    if not re.fullmatch(r'[0-9]+(?:\.[0-9]+){2}', version) or not build.isdigit():
        raise Blocked('Invalid public release identity')
    name = f'Syndicate-{version}-build{build}.ipa'
    ipa = next(item for item in manifest['files'] if item['name'] == name)
    if not re.fullmatch('[a-f0-9]{64}', ipa['sha256']) or not isinstance(ipa['size'], int) or ipa['size'] <= 0:
        raise Blocked('Invalid public release artifact')
    if not re.fullmatch('[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repository):
        raise Blocked('Invalid release repository')
    tag = f'ios-{version}-build{build}'
    return {'schema': 1, 'version': version, 'build': build, 'sha256': ipa['sha256'], 'bytes': ipa['size'],
            'url': f'https://github.com/{repository}/releases/download/{tag}/{name}',
            'release': f'https://github.com/{repository}/releases/tag/{tag}',
            'manifest': f'https://github.com/{repository}/releases/download/{tag}/release-manifest.json',
            'source': manifest['source']}


def render(html, data):
    match = re.search(r'<section class="download" id="ios-download">.*?</section>', html, re.S)
    if not match:
        raise Blocked('Mobile download section not found exactly once')
    if len(re.findall(r'<section class="download" id="ios-download">', html)) != 1:
        raise Blocked('Ambiguous mobile download section')
    section = match.group()
    section, count = re.subn(r'<a class="button"[^>]*href="[^"]*"[^>]*>Download iPhone / iPad IPA</a>',
                            '<a class="button" data-ios-download href="' + data['url'] + '">Download iPhone / iPad IPA</a>', section)
    if count != 1:
        raise Blocked('Mobile download link not found')
    section, count = re.subn(r'<p(?: data-ios-version)?>Version [^<]+</p>',
                            f'<p data-ios-version>Version {data["version"]} · Build {data["build"]}</p>', section)
    if count != 1:
        raise Blocked('Mobile version label not found')
    section, count = re.subn(r'IPA SHA-256: <code(?: data-ios-sha256)?>[a-f0-9]{64}</code>',
                            'IPA SHA-256: <code data-ios-sha256>' + data['sha256'] + '</code>', section)
    if count != 1:
        raise Blocked('Mobile checksum not found')
    result = html[:match.start()] + section + html[match.end():]
    script = '<script src="/downloads/ios-release.js" defer></script>'
    if script not in result:
        result = result.replace('<script src="/downloads/loader-release.js">', script + '<script src="/downloads/loader-release.js">')
    return result


def fetch(url):
    with urllib.request.urlopen(url, timeout=60) as response:
        return response.read()


def prepare(release, manifest):
    r = release
    config = r.config['website']
    base = config['public_url'].rstrip('/')
    html = fetch(base + '/').decode()
    sums = fetch(base + '/SHA256SUMS.txt').decode()
    data = metadata(manifest, r.config['github']['releases_repository'])
    current_section = re.search(r'<section class="download" id="ios-download">.*?</section>', html, re.S)
    current = re.search(r'Version [0-9.]+ · Build (\d+)', current_section.group()) if current_section else None
    if current and int(current.group(1)) > int(data['build']):
        raise Blocked('A newer mobile release is already published; do not roll it back')
    name = r.manifest['ipa']['name']
    line = data['sha256'] + '  ' + name
    entries = [entry for entry in sums.splitlines() if entry.endswith('  ' + name)]
    if entries and entries != [line]:
        raise Blocked('Historical checksum conflicts with canonical artifact')
    if not entries:
        sums = sums.rstrip() + '\n' + line + '\n'
    from pathlib import Path
    script = Path(__file__).parents[3] / 'Website/public/downloads/ios-release.js'
    return {'index.html': render(html, data).encode(), 'SHA256SUMS.txt': sums.encode(),
            'ios-release.json': canonical(data), 'ios-release.js': script.read_bytes()}
