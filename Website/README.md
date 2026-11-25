# Syndicate website

Publish `public/` at `https://synmessenger.com/`. Website stays front end; [GitHub Releases](https://github.com/dakotasnapshot/syndicate-releases/releases) serves installer payloads.

Keep extensionless privacy/terms/support routes working. OAuth client information remains at `/apps/ios.html` and `/apps/ios/index.html`; preserve registered public HTTPS client URIs. Never publish review credentials. Serve `.well-known/apple-app-site-association` as JSON without redirects.

Production uses Apache behind TLS ingress. Supplied vhost examples describe the original deployment, not necessarily current hosting. Mail stays separate.

## Release delivery

- Use exact versioned GitHub release asset URLs. Never replace published bytes; changed contents need a new version.
- Publish validated native packages, corresponding source, SHA256SUMS and package manifests. Verify GitHub digests, public whole-file delivery and restricted off-host recovery copies before linking new assets or advancing signed channels.
- Keep `/downloads/` as the platform front end. Preserve historical links/checksums. Current Loader metadata includes `file`, `version`, `sha256`, `description` and its GitHub `url`; static HTML fallback must match. Do not let Loader JS rewrite a valid GitHub URL into a local path.
- Existing managed0.1.10 clients require direct same-origin installer URLs and reject redirects. Keep their old installer paths and signed feeds operational until a compatible bridge client ships. New-source GitHub updater support alone is not a shipped update.
- OS signing status is unchanged by migration. Keep Windows preview and IPA installation requirements accurate.

## iOS release orchestration

Use `Tools/Release/release.py` and its runbook. The mobile section and `downloads/ios-release.json` are generated from the verified canonical GitHub release manifest. `ios-release.js` fills only the mobile link, version and checksum; generated static HTML remains usable without JavaScript or metadata access. Do not hand-edit iOS release numbers/hashes or clone dated publishing scripts. The runner preserves other platforms, historical checksums, Loader metadata and counter state, deploys metadata before HTML with CAS/rollback, and verifies live readback.

## Download counters

`download-counter.py` retains private SQLite/salt state for legacy Apache download-session estimates and reads public GitHub release-asset counters. The five-minute timer remains unchanged. Public `downloads/download-counts.json` separates `legacy_files` and `github_files`; `files` is the labeled combined recorded total. Homepage totals and seven current badges use that aggregate; history shows both components.

Legacy estimates count positive-body GET200/206 responses, excluding known bots/CLI checks and deduplicating client/file/fixed30-minute windows. Only salted HMAC client keys stay in private state; never publish IPs/user agents. Existing retained log coverage starts October5,2026; older history is unknown.

GitHub counts asset requests, including possible retries, partial transfers and automation—not installs, completed transfers or unique people. A fixed private `github-baseline.json`, captured after initial migration verification, excludes that initial verification traffic. New versions use their own GitHub counters without inventing earlier history. Anonymous release-list API refreshes need no stored GitHub token. API failures reuse the last verified cache, expose `github_stale`, and preserve usable download links; first refresh without a cache must fail rather than invent zero counts.

Run with `--state PRIVATE_DIRECTORY --downloads PUBLIC_DOWNLOAD_DIRECTORY` and repeatable `--logs 'GLOB'`. State directory0700; SQLite/salt/baseline/cache0600; public aggregate JSON0644. Preserve all private state in backups. JSON replacement is atomic. Inspect existing timer/service status and journal; do not create duplicate schedules or reset counters to repair display problems.

Rollback only reviewed frontend/counter files from their matching before-state. Preserve payloads, historical links, SQLite, salt, baseline and cache. No gateway restart or account-storage reset is part of release delivery.

## SYN Web

`/chat/` must use the customized Syndicate renderer from the [desktop/web source](https://github.com/dakotasnapshot/syn-messenger-desktop), never an upstream prebuilt Element archive. Follow `docs/SYN_WEB_RELEASE.md` there. Build with the intended version before compilation; baked WebPlatform version and served marker must agree. Preserve live browser server/device configuration, deployment settings, SYN PWA/icons and pre-bundle mobile full-web bootstrap. Existing `element-web-*` configuration/bootstrap filenames are compatibility paths, not authority to restore upstream branding or binaries.

Publish assets before index/version metadata; keep old hashed bundles and restricted rollback copies. Verify public desktop/mobile loading, sign-in entry, branded startup/error screens and absence of reload loops/JavaScript errors. Never clear account or encryption databases during updates. Preserve required upstream license notices and publish matching source.

## Branded promo and self-hosting site (2026-11-05)

Home, `/start/`, `/self-host/`, `/downloads/` and `/support.html` share local `assets/site.css` and `site.js`; no third-party fonts, trackers, or demo-message services. The room/theme demo is local, ephemeral, synthetic UI—not a real Matrix session or cryptographic demonstration. Federation animation is explanatory. Reduced-motion settings suppress animation. Screenshots are real app screens with synthetic conversations.

The self-hosting guide links official Synapse/Docker/PostgreSQL/Caddy images and upstream Kubernetes charts, including their separate account-management models. The clean starter ZIP is immutable in GitHub tag `self-host-starter-20261105`; its source is `self-host/starter` in the release repository. No accounts, signing keys, credentials or database image are shipped. Disposable Linux startup/user/deactivation/backup-format checks passed; public DNS/TLS/federation, Windows/macOS Docker Desktop, Kubernetes and full restore remain explicitly unverified deployment tasks. New starter contents require a new dated release, manifest and checksum; do not overwrite published bytes.

UpCloud pricing is dated and linked to official sources; entry/2GB pricing is not an all-inclusive $5 promise. Preserve referral URL/code858PV7 and the adjacent referral-credit disclosure, and recheck pricing when updating. Existing legal, OAuth, app-association, `/chat/`, legacy updater, historical installers and private counter state are outside this visual deployment. Deploy assets first and entry pages last with before-hash checks and scoped rollback copies. Preserve all account/encryption storage.

Windows/Linux0.1.11 download links match the verified GitHub bridge. Legacy0.1.10 managed clients receive direct-origin0.1.11 bridge installers; the bridge uses signed GitHub discovery/payload delivery afterward. Native macOS/EXE feed compatibility remains; iOS/Mac/Loader packages were not rebuilt for this website release.
