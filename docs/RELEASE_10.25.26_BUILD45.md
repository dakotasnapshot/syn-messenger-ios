# Syndicate 10.25.26 (45)

Full-width conversations on the open Duo display; full-width cover content with floating navigation controls and measured large-text scroll clearance. Selecting a room focuses its detail view; the native sidebar toggle restores navigation. Active display divisions retain system clearances rather than promising edge-to-edge partial-fold content.

The inverted timeline resizes using bounds and center, and hosted message cells do not apply keyboard/container insets a second time. Restored Markdown mentions retain SDK-compatible Matrix URIs internally, preserving intentional-mention metadata.

## Verification

- Signed iPhone Debug and Watch Debug/Release builds passed.
- 100 focused tests across 6 suites passed, including navigation, fold layout, Home, Spaces, draft and composer checks. The three previously failing restored-user-mention cases now pass without changing their expected message/mention metadata.
- Native acceptance passed: open 951pt / closed 466pt conversations, retained drafts and keyboard across repeated transitions, sidebar access, safe partial-fold Send controls, accessibility-sized Home/Spaces reachability, and ordinary iOS 27.0 navigation. Fresh inner-portrait rotation was blocked by simulator input; prior portrait evidence is historical. Physical tent posture remains unverified.
- An apparent blank-timeline PNG preview was not a proven app defect: opaque pixel checks and encoding-only JPEG decoding showed the message content. Earlier provisional screenshot interpretations were corrected.
- Distribution delivery is recorded in the release receipt after verification. This document alone is not proof of upload or tester availability.
- Physical tent posture and prior third-party OAuth/call/permission App Review evidence remain separate and unverified. No App Store review submission is authorized by this TestFlight release task.

## Verified delivery

- Signed archive/export, all five component signatures and deep/strict verification passed; App Store icon has no alpha. Apple validation and upload succeeded with no errors.
- Delivery `98c8a0bb-4ccd-484f-b00f-8e6ddbf4e149`: COMPLETE / VALID / Internal IN_BETA_TESTING. Internal group membership and test-note readback verified.
- Runtime source `1844c10a7`; matching public source checkpoint `8baa7d61589a0d1201b2c61ba56eae03824eecd9`, remote verified.
- [Public IPA](https://synmessenger.com/downloads/Syndicate-10.25.26-build45.ipa): 135,127,547 bytes. Full HTTPS download matches the export and embeds 10.25.26 (45). Live latest link/checksum manifest verified; build 44 retained.
- SHA-256: `60a9a64901a937a5f10459692798b4fcaf9f6055959e1fe67287c083c46a3e02`.
- Prepared App Store version 10.25.26 now selects build 45, remains PREPARE_FOR_SUBMISSION / MANUAL; existing UNRESOLVED_ISSUES retained. Review notes updated/read back with credential/contact fields unchanged. No App Review submission. Existing live screenshot galleries unchanged; preferred new Duo captures are local supplemental evidence.
