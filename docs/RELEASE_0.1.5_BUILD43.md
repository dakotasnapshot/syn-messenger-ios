# Syndicate 0.1.5 (43)

## Changes

- Keep UIKit keyboards aligned with system or selected light/dark mode when returning from another app. Resolve pending trait updates before reading input appearance, then refresh the existing first responder without dismissing it or changing drafts. Applies to both plain and formatted text inputs.
- Apply appearance when windows are configured and before foreground restoration, not only when changing theme settings. Ignore windows that have not been initialized.
- Correct composer drag resizing: use gesture translation directly instead of adding the cumulative translation on every update.
- Make reachability values explicitly nonisolated/Sendable, and use a read-only default text token for background mention parsing under Xcode 27.
- Declare stateless waveform and rounded-corner shapes nonisolated for Xcode 27’s SwiftUI shape requirements.
- Fix Xcode 27 notification-extension compilation by accessing the inline-code color token without the main-actor-isolated shared color palette.
- Apply repository-required formatter cleanup to existing guards, imports, and actor annotation placement.
- Require matching website IPA publication, public checksums, latest-download references, and source updates for every iOS release.

## Regression checks

`SYNWindowAppearanceTests` covers nested text fields/editors in explicit light/dark modes, reset to system mode, system trait changes, and refreshing a surviving first responder while preserving its draft. All 84 focused tests passed in the full app’s `UnitTests` scheme: `SYNWindowAppearanceTests`, `SYNThemeProfileTests`, and `AttributedStringBuilderTests`, including background inline-code rendering. The five appearance tests also passed in an isolated iOS Simulator harness compiling the repository source directly.

The full iPhone Debug build passed with its embedded Watch app and extensions; project-wide SwiftLint reported zero serious violations.

## Device acceptance

With system dark mode and app appearance set to System, focus a conversation composer, switch to another app, then return. Confirm the keyboard remains dark and the draft/cursor are intact. Repeat with plain and formatted composers, explicit Light/Dark app modes, and a system appearance change while backgrounded.

The downloadable IPA is an App Store distribution export; direct device installation requires local re-signing with an appropriate provisioning profile. Preserve Element attribution and AGPL licensing when distributing source or binaries.
