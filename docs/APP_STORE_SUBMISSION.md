# App Store submission readiness

Audit: 2026-10-25. App `6809166852`, bundle `app.syn.messenger`.

## Current state

Updated preparation: 2026-10-27. Draft **10.27.26**, attached **build47**, **PREPARE_FOR_SUBMISSION**, release policy **MANUAL**. Giphy restored; Internal TestFlight, matching public IPA/source and ten current iPhone/iPad screenshots verified. No App Review submission.

See `APP_STORE_10.27.26_BUILD47_PREPARATION.md` and `RELEASE_10.27.26_BUILD47_RECEIPT.json` for saved Notes, exact evidence, delivery and known gaps. Contact/review-account fields and three Watch screenshots preserved. Prior provider Apple sign-in and physical-device calling/location evidence remain unverified; Notes request reassessment and evidence clarification, not a client exemption or a granted waiver.

## Rejection history

September16 review correspondence, provided October27, reported a provider Apple sign-in error and requested physical iOS/watchOS demonstrations of supported CallKit services. Other historical findings below come from earlier remediation records, not newly recovered correspondence. Recheck live review correspondence before manual submission.

| Issue | Verified finding | Remaining gate |
| --- | --- | --- |
| Guideline 5: CallKit in mainland China | CHN unavailable, `CANNOT_SELL` in live ASC territory records. | Preserve exclusion; recheck at submission. |
| 3.1.1: account portal exposes purchases | Settings view model no longer populates general account-profile URL. | Check signed candidate; keep general purchase-capable portal absent. |
| 2.5.4: background location | Existing Notes explain user-initiated live sharing and link build-26 physical recording. | Verify/re-record current build and exact menu labels. |
| 2.1: matrix.org Apple sign-in failure | Review password passed live Matrix login; temporary session logged out. This does not verify browser OAuth or Apple sign-in. | Test fresh in-app OAuth, cancellation, callback, and provider Apple sign-in. Capture actual failure before attributing cause. |
| Physical iPhone/Watch CallKit and permission demonstration | ASC currently returns no review attachments. Watch is a paired messaging companion, not standalone calling service. | Record supported incoming/outgoing calls and permission prompts on physical devices; explain Watch capabilities accurately. |

## Matrix-client review approach

Use normal public App Store review. A federated client need not operate a proprietary messaging network, but is not exempt from completeness, UGC, privacy, or deletion rules.

- Explain independently operated homeservers and server-owned accounts/authentication methods.
- Supply durable review credentials in ASC's dedicated fields, never source or public docs. Include homeserver and exact sign-in steps in Notes.
- Keep synthetic review account and peer reachable throughout review. Verify sync, encryption recovery, messaging, attachments, reports, blocks, calls, notifications, and Watch replies.
- Do not ask reviewers to skip a broken advertised sign-in option. Password access is not proof that Apple sign-in works.
- Guideline 4.8 includes a third-party-service-client exception to offering another login service. Explain that Syndicate authenticates directly to the selected Matrix service, not a separate Syndicate identity. Applicability to a federated multi-provider client is an argument for Apple to assess, not a guaranteed exemption. It does not excuse a broken provider option exposed in the review flow.
- Verify deletion separately for password and OAuth servers. Native deactivation is capability-gated; current matrix.org OAuth metadata does not advertise `org.matrix.account_deactivate`. Legacy password login does not prove OAuth deletion works. Resolve or explain this before claiming broad deletion support.
- Explain that Syndicate sells no subscriptions or paid unlocks. Do not claim a blanket IAP exemption for client apps.
- Keep report/block and public support contact discoverable; encryption/federation does not remove UGC obligations.

## Saved Review Notes

Current draft Notes are saved verbatim in `APP_STORE_10.27.26_BUILD47_PREPARATION.md` and were read back from App Store Connect. Credentials remain only in dedicated private fields. The maintainer will review before any submission.

## Duo design and validation

Adapt automatically, not via manual modes or guessed hinge-angle thresholds. Apple specifies availability October 23, 2026 (Friday). Xcode 27.1/SDK installed.

| Pose | Expected behavior | Validation |
| --- | --- | --- |
| Closed | Compact single pane on outer display; reachable controls with system vertical bars. | Signed simulator PIN layout/state verified. |
| Fully open | Regular-width split navigation shows rooms/conversation when space permits. | Signed native PIN transitions in both orientations verified; authenticated room workspace separate. |
| Partial/book | System columns avoid hinge; composer fits usable pane; dialogs use arrangements. | Actual reserved-region PIN reflow and state continuity verified. |
| Partial/tabletop | System dialog arrangement places content/actions in usable regions; composer remains bottom-inset. | Partial portrait/landscape PIN panels verified; physical tabletop posture not measured. |
| Tent | Follow system-selected display and scene geometry. Never mirror private conversations to opposite display. | Pending Device Hub or physical test. |

Preserve room, draft, recovery state, and sheets across transitions. Test Dynamic Type, RTL, keyboard, foreground/background, portrait/landscape, and multitasking. Rotation is not fold-pose testing. Do not advertise a Duo badge without validated required assets.

Current evidence: build 44 passed 110 focused tests. Actual cover/inner/partial-fold portrait and landscape PIN layouts, synthetic partial input continuity, and keypad input were verified on the signed simulator build. See `RELEASE_0.1.5_BUILD44.md` and workspace `reports/ios271-duo-20261025/syndicate-pin-verification.md`. Earlier sensor-only rotation failures and unsigned synthetic harness failures are superseded by this signed native validation. Physical tent posture and broad authenticated messaging/calling behavior on Duo are not verified.

## Submission gates

- [ ] Reconcile latest full rejection correspondence.
- [ ] Verify fresh in-app OAuth and provider Apple sign-in.
- [ ] Verify signed candidate's report/block, privacy, deletion, and no-purchase-link paths.
- [ ] Complete Duo pose/display transitions and visual inspection.
- [ ] Record requested physical iPhone/Watch/call/permission and background-location evidence.
- [ ] Refresh synthetic screenshots, privacy labels, age rating, contact, and steps.
- [x] Build47 passed iPhone/Watch gates, archive/export, signatures, Apple validation.
- [x] Build47 delivered to Internal TestFlight, matching website IPA/checksums and public source published.
- [ ] Select verified build; update Notes/attachments and release policy.
- [ ] Final App Review submission authorization. Preparing review does not itself submit.

## Primary sources

- [Complete review information](https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review/)
- [Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Account deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app/)
- [Matrix authentication/account management](https://spec.matrix.org/v1.18/client-server-api/)
- [Matrix.org OAuth service](https://www.matrix.org/blog/2025/04/morg-now-running-mas/)
- [Duo preparation](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo)
- [Duo design](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)
- [Adaptive layouts](https://developer.apple.com/videos/play/tech-talks/111463/)

- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
