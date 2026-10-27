# Syndicate 10.27.26 — build 46

## Changes

- Neutral, appearance-aware navigation and attachment controls; preserve blue message/send emphasis and semantic destructive states.
- Neutral navigation backdrop and soft top-edge fade on the conversation timeline.
- Rounded, thin-bordered sidebar and a single Chats/Spaces navigation menu in spacious layouts (at least 1,000 points wide).
- Keep the spacious-layout conversation list available when selecting a chat; retain compact navigation behavior.
- Track undocked keyboard geometry to reserve composer clearance above the iPad external-keyboard accessory, without double-counting SwiftUI's docked keyboard avoidance.

## Verification

- iPhone Debug simulator build passed (arm64).
- Watch Debug and Release simulator builds passed (arm64).
- 29 focused tests passed in four suites: keyboard clearance geometry, theme profiles, fold layout and navigation split coordination.
- Built app declares iPhone/iPad device families and all four orientations.
- Final signed Debug simulator build passed after adding the missing typed split-view introspection predicate.
- Final synthetic iPad checks passed: Chats/Spaces title navigation, full-sidebar bezel, light/dark controls, wallpaper, and two-line draft preservation across landscape-to-portrait rotation.
- Final ordinary iPhone checks passed: compact tab routing, conversation/attachment controls, portrait-to-landscape draft preservation, and software-keyboard composer clearance.
- Prior same-code iPad software-keyboard checks passed; the final iPad run did not display a software keyboard/accessory. Physical external-keyboard clearance remains unverified.
- Return-to-portrait phone observation timed out under host contention; both owned simulators and native sessions were closed. No app crash or blocking bug observed in completed checks.
- Signed Release archive and App Store Connect IPA export passed. All five app/extension/Watch components, versions, signatures, iPhone/iPad support and orientations verified; icon alpha absent. Apple validation passed with no errors. TestFlight and website delivery pending.

## Privacy and compatibility

Synthetic test data only. Reference screenshots are private working inputs and are not shipped. Existing minimum iOS 18.5 support retained; keyboard layout guide APIs used are available at that baseline. External-keyboard physical iPad acceptance must be recorded separately from simulator checks.
