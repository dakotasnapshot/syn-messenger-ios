# Scheduled room notifications — iOS development checkpoint

Unreleased. Last shipped iOS build remains 10.27.26 (47). This checkpoint prepares the macOS0.1.12 contract and editor; it does **not** implement or claim iOS notification enforcement. Do not publish it as a completed scheduler.

## Portable contract

Standard Matrix per-room account data:

`GET/PUT /_matrix/client/v3/user/{userId}/rooms/{roomId}/account_data/app.syn.notification_schedule`

Use authenticated session identity/token. User and room identifiers are encoded as individual URL components. No custom Synapse endpoint, scheduler login, server module, periodic server cron, or push-rule mutation. Works with standard Matrix account-data APIs; no room-wide state change or effect on other members/clients. Existing global prototype account data is not silently migrated.

```json
{"version":1,"enabled":true,"days":[1,2,3,4,5],"start_minute":540,"end_minute":1020,"timezone":"Europe/Paris","override":"schedule"}
```

This matches released macOS0.1.12. ISO weekdays Monday1–Sunday7. Start inclusive/end exclusive. Overnight windows belong to their starting day. Fixed IANA timezone across travel; current local wall-clock evaluation handles repeated/skipped DST hours. Equal endpoints, duplicate/out-of-range days, unsupported versions/overrides, invalid zones and out-of-range minutes are rejected. A missing override defaults to `schedule` for existing documents.

Overrides `schedule`, `mute`, `normal` are indefinite, matching macOS. `normal` bypasses only schedule suppression and never unmutes a manual Matrix room preference. `mute` applies even when recurring scheduling is disabled. This defines evaluation; iOS delivery wiring remains outstanding.

## Editor and errors

Debug builds only: Room settings → Notifications → Scheduled notifications. Release builds hide these unfinished controls and do not load schedules from this screen. Edit days/hours/timezone and behavior. Save writes only this room document. GET404 is considered an empty schedule only with Matrix `M_NOT_FOUND`; authentication, proxy, malformed-data and transport failures are errors. Successful PUT returns the acknowledged draft locally, not a false decode of Matrix's empty response.

Save first compares the current server document with the loaded baseline. If another device changed it, preserve local edits and show reload guidance rather than overwrite the observed edit. Reload explicitly discards the local draft. This is an optimistic conflict check, **not** compare-and-swap: edits after the check still follow standard Matrix last-write-wins. No background job uploads an old cache. Unsaved edits are view-owned and not an offline write queue.

No reactive room-account-data cache has been added yet. The currently pinned Rust SDK does not expose arbitrary custom `RoomAccountDataEvent` payloads through its typed observer. Opening/reloading settings and pre-save GET read the server; do not claim live multi-device/background sync acceptance.

## Blocking Apple gate

As of November10,2026, the installed distribution profile for `app.syn.messenger.nse` does **not** contain `com.apple.developer.usernotifications.filtering`. The NSE manifest also intentionally does not declare it before Apple approval. Existing empty-content discard paths do not prove silent background suppression without that entitlement.

Required before release:

1. Obtain Apple notification-filtering approval and refresh the NSE distribution profile; verify actual allowed and signed entitlements.
2. Implement account-scoped, cross-process schedule caching with logout/credential isolation and canonical remote updates. Never copy Matrix tokens to Watch or put secrets into account data.
3. Wire evaluation before foreground banner/audio and NSE/CallKit preprocessing. Re-evaluate at receipt rather than relying on suspended app timers. Define/test network timeout, extension expiration, malformed remote data and offline-cache behavior.
4. Prove real-device background/suspended delivery, failure/timeout handling, multi-account isolation and cross-device edits. Simulator success is not APNs suppression acceptance.
5. Complete iPhone/iPad runtime, unit/UI, Watch Debug/Release, signed archive/export, private-string scan and Apple validation gates. Then TestFlight plus matching public IPA/source publication under the normal release workflow.

Do not substitute account-wide Matrix push rules, reactivate the retired custom Synapse module, or claim that foreground-only filtering is full scheduler parity.

## Verification

`UnitTests/Sources/RoomNotificationSettings/RoomNotificationScheduleTests.swift` covers macOS encoding, strict validation, overrides, boundary/overnight/DST behavior, encoded authenticated per-room requests and error classification. The same pure source/tests can run through a standalone macOS Swift Testing harness; record that result separately from the iOS app build and native acceptance.
