# Syndicate 11.24.26 (50) — adaptive conversations

## Changes

- Drag the Chats sidebar edge handle narrower for an avatar rail and an actions dropdown; widen it to restore conversation previews. Search, invitations, unread indicators and selected-room controls remain usable.
- Message focus uses purple/blue highlighting.
- Select and copy part of a message directly with native text-selection handles.
- Full-height rounded conversation list, soft bottom fade and conversation-pane composer fix retained. No account reset, encryption-store change or message migration.

## Verified delivery

- 22 effective checks passed: six light iPad, dark resize, five compact iPhone, iOS 27.1 wide-inner composer and nine keyboard/fold unit checks. The compact sidebar-resize case is intentionally skipped. The phone Copy test uses a measured first-word point rather than center whitespace in wrapped text; its superseded harness failure is retained in private test evidence.
- Watch Debug/Release, signed archive/export, all five exported App Store component profiles/signatures, icons, orientations and deployment configuration passed inspection. Apple validation passed.
- Apple delivery `741364f7-5e2c-484f-9afa-a3322a9d5f59`: COMPLETE / VALID / IN_BETA_TESTING, exact existing Internal-group membership and test notes verified. No App Review or external-beta-review submission.
- [Public IPA](https://github.com/dakotasnapshot/syndicate-releases/releases/download/ios-11.24.26-build50/Syndicate-11.24.26-build50.ipa) — 135,303,286 bytes; complete public download and embedded version/build verified. SHA-256: `feed39a94a0318a9b6e1d287e307a4d982ad7ed6a1a1227c1cbe635e04c0fdb6`. [Checksums and manifest](https://github.com/dakotasnapshot/syndicate-releases/releases/tag/ios-11.24.26-build50).
- [Matching app source](https://github.com/dakotasnapshot/syn-messenger-ios/tree/c7304b53b3d2292ef6e783840f248bc0e7db2eec); website download/checksum readback verified, historical files and Loader preserved.

The affected physical iPad was unavailable. Native simulator checks and fresh active-display captures do not establish physical-device acceptance. Installation from the IPA requires appropriate local signing/provisioning.

See [the layout contract](CONVERSATION_LIST_LAYOUT.md) and [release receipt](RELEASE_11.24.26_BUILD50_RECEIPT.json).
