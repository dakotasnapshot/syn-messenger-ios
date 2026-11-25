# Syndicate 11.25.26 (52) — uniform focused-message highlight

The focused-message background is now one uniform indigo fill, replacing the stacked indigo/purple gradient and separate top stroke. Dark/light opacity is retained; focus selection and account/message storage are unchanged.

Verification: focused-message native iPad UI test passed once in dark and once in light appearance; screenshots inspected. SwiftFormat and SwiftLint passed. Signed archive and App Store export verified all five app/Watch/extension identities, distribution profiles, signatures, device families, orientations, icons and Giphy configuration. Apple validation passed. Physical iPad coverage is not claimed.

TestFlight delivery 0d619bc7-fa40-4096-b216-7361721f8048: COMPLETE/VALID, existing Internal group membership and IN_BETA_TESTING verified. No App Store review submission.

Public installer: https://synmessenger.com/downloads/ ; SHA256 `bbd57fb1df6d652bbfe05b6006656fb6256753b1c4bec0fb2a2c2ca011a548e2`. Corresponding source: https://github.com/dakotasnapshot/syn-messenger-ios/tree/1aa3bbba1976e7bafd339412785a07771494496c . Exact public IPA whole-file checksum and embedded version/build verified. IPA sideloading requires appropriate re-signing/provisioning; TestFlight is the ready-to-install route.

Existing release artifacts retained. Previous build51 remains available; no account reset or store migration. Desktop/web/Android unchanged.
