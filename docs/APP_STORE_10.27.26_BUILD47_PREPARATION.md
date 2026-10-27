# Syndicate 10.27.26 (47): release and review preparation

## Delivery

- Giphy restored through bundled deployment configuration; missing configuration fails Release builds. See `GIPHY_CONFIGURATION.md`.
- Internal TestFlight: VALID / IN_BETA_TESTING, existing Internal group and test notes read back.
- Source checkpoint: `d5ee1acf80a4770dc1f5ca8e870964f51ad0aa60`. Public runtime-source checkpoint: `7377e82`.
- Public IPA: https://synmessenger.com/downloads/Syndicate-10.27.26-build47.ipa
- SHA-256: `056ed16905ad4f9fbfe0692ab88bb81c7d35bd27d32dc000007130f407608c79`; 135152070 bytes. Full public download, embedded version/build/configuration and latest metadata verified. Previous46 retained; Loader unchanged.

## Verification

- iPhone Debug; Watch Debug/Release; signed Release archive/export; five component signatures/versions; icon alpha; Apple validation passed.
- 52 composer/media tests passed. Two portrait-video byte-size tolerances updated from100 to1024bytes for the observed146byte OS-container difference; dimensions, duration, format, thumbnail and expected-size checks retained.
- One native GIF UI test passed: menu, search, selection, confirmation, download and upload preview. GIF processing test passed. Live Giphy trending/search/download checked without exposing keys.
- Simulator UI uses fictional content. No live Matrix GIF message or physical-device call/sign-in/Watch/location acceptance is claimed. Prior iPad/fold verification belongs to earlier release records, not a fresh fold test here.

## App Store draft

Version10.27.26, attached build47, PREPARE_FOR_SUBMISSION, MANUAL release. Notes read back exactly; contact and review-account fields preserved. No App Review submission, rejection-thread reply, or video waiver was made.

Ten current simulator screenshots, encoded as opaque JPEG without resizing, saved to the draft: iPhone6.7/6.9 class3, iPhone6.1 class4 (including Giphy search), iPad13 class3. All assets COMPLETE and ordering read back. Three existing Watch screenshots retained. Previous17 screenshot files backed up before replacement; loading-frame captures excluded. A stalled PNG reservation was replaced with an opaque JPEG encoding; all final assets completed processing.

The September16 rejection against0.1.5(28), provided in review correspondence, reported provider Apple sign-in error and requested physical-device demonstrations of all supported CallKit services. Notes request reassessment/current-flow clarification and distinguish Watch messaging from iOS calling. They do not claim third-party servers exempt the client or that Apple granted a waiver. Provider Apple sign-in and physical-device evidence remain unverified.

## Saved App Review notes

Syndicate (SYN Messenger) is an independent Matrix client for iPhone and iPad, with a paired Apple Watch messaging companion. Users select their Matrix homeserver. Syndicate does not operate or sell homeserver accounts; authentication and account policies are provided by the selected server.

Review access: the review account remains supplied in the dedicated App Review username and password fields. Select Sign in and matrix.org, then authenticate through the homeserver-provided sign-in page using the supplied account. There is no proprietary Syndicate account service. Authentication options vary by homeserver; the server's sign-in page is not a Syndicate-operated identity service.

The iPhone owns authentication, encryption and Matrix synchronization. The Watch receives conversation snapshots and sends replies through the paired iPhone. The Watch does not provide standalone Matrix login or calling.

Syndicate has no paid unlocks, subscriptions or digital-content sales. General homeserver purchase/account-management portal links are not surfaced by the settings model. Mainland China availability remains excluded because the app uses CallKit.

Current candidate: version 10.27.26, build 47. Restores the GIPHY GIF attachment picker and preserves the latest iPad conversation/sidebar and compact iPhone navigation refinements. To find GIFs: open a conversation, tap the attachment (+) menu, select GIFs, search, choose a GIF and confirm it to open the attachment preview before sending. GIPHY search and media retrieval use GIPHY's service; sending uses the existing Matrix attachment pipeline.

Regarding the September 16 findings against version 0.1.5 (28): please reassess applicability against this current binary. We understand that functionality offered by the client remains subject to review. Could direct testing with the supplied review account satisfy the earlier CallKit demonstration request instead of a video? If a physical-device video remains necessary, please identify the required iOS CallKit flows and any separate watchOS messaging flows. The Watch companion does not implement calling, so there are no watchOS CallKit flows to demonstrate. We request clarification of evidence requirements, not an exemption from review of client functionality.

Live location sharing is user initiated and time limited, not automatic continuous tracking. New screenshots are simulator captures with fictional conversation content, not physical-device call/permission recordings.
