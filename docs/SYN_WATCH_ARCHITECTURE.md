# SYN Messenger Watch Architecture

## Goal

Provide an iMessage-like Matrix experience on Apple Watch without asking the user to authenticate a second time.

## Current boundary

- The iPhone remains the Matrix sync and encryption authority.
- The watch receives a minimal, Codable conversation snapshot through WatchConnectivity.
- Replies are queued back to the iPhone with the Matrix room ID and plaintext body.
- The watch never receives an access token, cross-signing key, recovery key, or crypto store.
- The WidgetKit extension reads only the reduced snapshot from its watch-only app group.

This gives the user automatic companion provisioning while avoiding credential duplication. It also works with the currently shipped MatrixRustSDK XCFramework, which does not contain watchOS slices.

## Complication privacy

The four supported families are accessory inline, circular, corner, and rectangular. Inline, circular, and corner show only aggregate unread state. The rectangular family can show the latest room name and marks that detail as privacy-sensitive.

## Next integration steps

1. Persist queued replies until the iPhone acknowledges their Matrix event IDs.
2. Add notification actions, dictation, emoji, and canned replies.
3. Add room avatars and a compact message timeline to the watch conversation view.
4. Evaluate a custom watchOS build of matrix-rust-sdk before enabling independent encrypted sync.

## Implemented bridge

The iPhone observes its authenticated static room summary provider and publishes up to 50 non-space, joined rooms. Reachable watch replies use interactive messaging and show sent or failed state. Replies created while the phone is unreachable use background user-info transfer and show queued state. The iPhone resolves the room through the existing client proxy and sends with the normal encrypted Matrix timeline.

Opening a conversation requests up to 30 recent message events from the iPhone's encrypted timeline. Reachable devices use an interactive request; otherwise WatchConnectivity queues a background request and response. Successful histories remain cached on the watch. The watch receives only display-ready sender, body, timestamp, direction, and event identifier fields. Starting a direct conversation sends a Matrix user ID to the iPhone, which creates the room through the authenticated client.

## Public-source rule

Do not add private homeserver names, internal URLs, organization data, credentials, tokens, customer content, or developer-machine paths. Examples and previews must use synthetic Matrix rooms and users.

## First TestFlight capability note

Element X uses Apple's restricted Notification Service Extension Filtering entitlement. SYN Messenger omits that entitlement until Apple approves it for the new App ID. Ordinary notification-service processing remains in the target, but restricted filtering behavior must be verified after approval and re-enablement.
