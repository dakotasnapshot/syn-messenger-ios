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
- Final synthetic iPad and ordinary iPhone interaction checks resumed October 27. The first resumed compile caught a missing split-view introspection predicate; added the supported-version predicate matching existing navigation helpers. Final build and release evidence pending.

## Privacy and compatibility

Synthetic test data only. Reference screenshots are private working inputs and are not shipped. Existing minimum iOS 18.5 support retained; keyboard layout guide APIs used are available at that baseline. External-keyboard physical iPad acceptance must be recorded separately from simulator checks.
