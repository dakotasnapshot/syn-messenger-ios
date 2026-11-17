# Syndicate 11.16.26 (48) — suspension safety

## Changes

- Give every asynchronous client shutdown its own UIKit background assertion. Release only that assertion when its work finishes or iOS expires it.
- Keep pending database shutdown protected when the app returns to the foreground. Do not cancel the shutdown or release its protection before completion.
- Do not skip a new background shutdown merely because an earlier one is still pending, or let an old completion release a newer assertion.
- Acquire background protection before resuming services for an incoming VoIP call, retaining it through the subsequent pause.
- Keep the foreground sync-state observer when an older background pause finishes after foregrounding.

## Scope

This addresses concrete lifecycle races relevant to suspension-time file-lock terminations. It does not establish a fix for every sync stall, Wi-Fi reconnection issue, SDK search-index merge, or database-lock termination. No account reset, logout, database deletion, encryption-key migration, SDK replacement, or search-feature removal is included.

The existing development-only notification schedule editor remains Debug-only. This release does not enable or claim notification filtering/scheduling acceptance.

## Verification

- 24 focused tests in three suites passed, including overlapping shutdown completion, expiration, invalid assertion allocation, presence, and reachability behavior.
- iPhone and iPad native smoke tests each passed five Home/foreground transitions followed by working sign-in navigation. A final activation-animation settle prevents an automation tap from landing during SpringBoard animation; the initial timing failure is not counted as a passing test.
- Watch Debug and Release builds passed. Signed Release archive/export and all five App Store distribution signatures/profiles passed; versions, iPhone/iPad support/orientations, production push, compiled icon opacity and bundled GIF configuration verified.
- Apple validation passed; delivery `6527d8e0-bc0e-4202-a2b1-16ace65760f9` completed. Build **VALID**, **IN_BETA_TESTING**, with exact existing Internal group membership and release notes verified. No App Review or external-beta-review submission; storefront configuration unchanged.
- [Matching public IPA](https://github.com/dakotasnapshot/syndicate-releases/releases/download/ios-11.16.26-build48/Syndicate-11.16.26-build48.ipa), full 135,200,373-byte public download, embedded version/build and SHA-256 verified. [Release checksums and manifest](https://github.com/dakotasnapshot/syndicate-releases/releases/tag/ios-11.16.26-build48). SHA-256: `6608bab31babc17474eda5691637839fd124c7251b42517b3b0a12cd4ccf8ba8`.
- [Corresponding app source](https://github.com/dakotasnapshot/syn-messenger-ios/tree/b0980dc6043eb51f04aae336a0be7f7afdea38a3) published and read back. Restricted off-host release recovery copies passed fresh whole-file verification. Downloads page/checksums read back publicly; historical build 47 and Loader metadata retained.

See [the terminal release receipt](RELEASE_11.16.26_BUILD48_RECEIPT.json).

Physical-device reproduction of suspension with an authenticated account remains a follow-up acceptance check. Simulator smoke checks do not reproduce iOS physical-device suspension enforcement.
