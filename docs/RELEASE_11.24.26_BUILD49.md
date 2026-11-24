# Syndicate 11.24.26 (49) — conversation-pane composer

## Fix

Keep the message input and attachment/Send controls inside the conversation pane when the chat sidebar is shown. The iOS27.1 full-width workaround now follows reactive split-view column visibility instead of ignoring the sidebar's safe area. Detail-only and compact layouts retain their existing behavior. No account reset, message-store change or encryption-key migration is included.

See [the layout contract and regression procedure](COMPOSER_PANE_LAYOUT.md).

## Verified delivery

- Native composer checks passed on iPadOS27.0, compact iPhone iOS27.0 and the iOS27.1 sidebar path: exact numeric draft, leading attachment control, Send, backspace and multiline wrapping. Active-display capture confirms the numeric draft starts at1 and wraps within the visible conversation pane. Simulator whole-app bounds/cover captures were not accepted as visual proof.
- Nine focused keyboard/fold tests passed in two suites. Watch Debug and Release builds passed. Signed archive/export, all five exported App Store profiles/signatures, iPhone/iPad support/orientations, icons and bundled service configuration passed inspection; Apple validation passed.
- Apple delivery `b75e7577-802f-4c03-904a-bf17c10df62d` completed. Build **VALID**, **IN_BETA_TESTING**; exact existing Internal-group membership and test-note readback verified. No App Review/external-beta-review submission or App Store publication.
- [Matching public IPA](https://github.com/dakotasnapshot/syndicate-releases/releases/download/ios-11.24.26-build49/Syndicate-11.24.26-build49.ipa); full **135,203,491-byte** download, embedded version/build and SHA-256 verified. [Release checksums and manifest](https://github.com/dakotasnapshot/syndicate-releases/releases/tag/ios-11.24.26-build49). SHA-256: `a4fbe0685de84d098df07e14ce1d2c6174ffa6a94aa032731736e7150afb8231`.
- [Corresponding build source](https://github.com/dakotasnapshot/syn-messenger-ios/tree/956bbcd265fd10dac8ca799a72111cbdcb751957) published and read back. Download-page/checksum readback passed; Loader metadata and historical build48 retained. Restricted off-host release copies passed fresh whole-file readback.

The affected physical iPad was unavailable; confirmation on that device remains a follow-up acceptance check. Older iPadOS27.0 did not reproduce the original leading-edge clipping. No physical-rotation acceptance is claimed from XCTest orientation requests alone.

See [the terminal receipt](RELEASE_11.24.26_BUILD49_RECEIPT.json).
