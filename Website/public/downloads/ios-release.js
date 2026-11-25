/* Generated metadata is a verified GitHub release snapshot. Static HTML remains usable on failure. */
(() => {
  'use strict';
  fetch('/downloads/ios-release.json', { cache: 'no-cache' })
    .then(response => { if (!response.ok) throw new Error('Release metadata unavailable'); return response.json(); })
    .then(release => {
      if (release.schema !== 1 || !/^\d+\.\d+\.\d+$/.test(release.version) ||
          !/^\d+$/.test(release.build) || !/^[a-f0-9]{64}$/.test(release.sha256)) return;
      const expected = `https://github.com/dakotasnapshot/syndicate-releases/releases/download/ios-${release.version}-build${release.build}/Syndicate-${release.version}-build${release.build}.ipa`;
      if (release.url !== expected) return;
      const link = document.querySelector('[data-ios-download]');
      const version = document.querySelector('[data-ios-version]');
      const checksum = document.querySelector('[data-ios-sha256]');
      if (!link || !version || !checksum) return;
      const build = Number(release.build);
      const current = version.textContent.match(/Build\s+(\d+)/);
      if (!Number.isSafeInteger(build) || build < 1 || (current && build < Number(current[1]))) return;
      link.href = expected;
      version.textContent = `Version ${release.version} · Build ${release.build}`;
      checksum.textContent = release.sha256;
    })
    .catch(() => { /* Retain the last verified, server-generated links; never substitute a guessed version. */ });
})();
