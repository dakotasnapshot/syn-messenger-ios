# Syndicate iOS releases

One entry point: `Tools/Release/release.py`. Three stages: **develop/verify → immutable candidate → resumable delivery**. This is the iOS/Watch lane; desktop, Loader, Android and SYN Web keep their own workflows.

## Ownership and sources of truth

| Concern | Owner / canonical record |
|---|---|
| Product code and focused tests | Development task, committed before release preparation |
| Signed IPA, identity and provenance | One private per-release `candidate.json`; immutable after admission |
| Delivery progress | One private `status.json`, protected by an exclusive file lock |
| Public package, manifest and checksum | Immutable, versioned GitHub Release |
| Website | Generated snapshot of that verified GitHub manifest, not separately edited release numbers |
| Wiki | Operational runbook plus one replaceable generated current-release block |
| Apple processing wait | Native durable worker; no model polling or chat/session continuation dependency |

Do not copy build-specific report scripts for a new release. Historical reports remain evidence, not executable dependencies. Keep machine addresses, account configuration, credentials, logs, archives and receipts outside the repository. The public source checkout is an independent stable checkout, not a dated report folder.

## Setup

Use Python 3.9+ on the build Mac, Xcode, XcodeGen, SwiftFormat, SwiftLint, git, SSH and a configured Apple signing account. Create a private virtual environment and install `requirements.txt`. Copy `config.example.json` to `~/.config/syndicate-release/config.json`, fill the machine-specific values and restrict it to mode 0600. Put `ExportOptions.plist` beside it; reference private credential files, never copy key/token values into git. Existing internal beta-group membership is used; no testers are invited.

The private `source.allowed_dirty` list is an explicit exception list for known unrelated changes, never a broad wildcard over product source. `source.private_patterns` adds machine-specific public-source leak checks. Confirm both checkouts' identity and branch before operating. The profile is bound to each candidate by hash; changing an active profile blocks resume rather than silently redirecting delivery.

Examples below use `release.py` as shorthand for invoking it with the private virtual environment's Python. Always pass an absolute, private `--state` directory. Commands execute argument arrays, not shell templates.

## 1. Develop and verify

Finish requested product changes, version/build settings, focused logic/native tests, visual review, formatting/lint and source review. Preserve unrelated changes and commit the intended product checkpoint. Own simulators serially; shut them down before archiving. Never use real account/message data in fixtures.

Create a private verification plan from `plan.example.json`. Replace every placeholder. List the explicit changed source/docs/generated project files for the sanitized public-source checkout. Include focused XCTest/UI-test commands and their unique xcresult output path; empty or skipped native runs fail. Add feature-specific logic/visual acceptance to `source_checks` using a reviewed checked-in verification script when several checks are needed. Do not weaken the required gate set to speed up a release.

```sh
release.py --state "$RELEASE_STATE" prepare --plan "$VERIFICATION_PLAN" --version 1.2.3 --build 54
```

`prepare` runs the five required gates serially, copies only declared files into a clean public-source checkout, checks shared Swift/dependency equality, archives/exports once, checks all five bundle identities/profiles/signatures, push configuration, device families, orientations, icons and Giphy configuration, and runs Apple validation. The candidate contains one IPA hash, source commit, notes and verification summary. Full evidence stays private.

Use `verify` and `candidate` separately when inspecting the development/build boundary. A completed archive is reused on a safe retry; an incomplete archive is preserved and blocked for inspection. A candidate cannot be rebuilt or edited in place. Changed source or bytes require a new candidate/build number. Never rerun `prepare` to solve an Apple-processing delay.

## 2. Admit delivery

Announce that the tested candidate will upload after two minutes without a new user message. After that interval, read the actual task conversation, reconcile every new request/hold and record its real `$` event ID. A changed request requires updating/testing the candidate first; a hold stops delivery.

```sh
release.py --state "$RELEASE_STATE" quiet --announced-at "$ANNOUNCEMENT_EPOCH" --latest-user-at "$LATEST_USER_EPOCH" --event '$REAL_EVENT_ID' --requests-reconciled
release.py --state "$RELEASE_STATE" install-worker
```

The conversation read must be fresh: admission expires after 90 seconds. Install only one worker per candidate. `install-worker` creates a dedicated **user LaunchAgent**, not a Gateway job. It survives the chat ending and restarts after unexpected process failure. It never restarts or changes OpenClaw. A deliberate safety block exits cleanly and records the blocker instead of creating a restart storm. A completed release needs no worker. LaunchAgent files stay private; an exited successful job consumes no polling resources.

For attended delivery use `deliver`; for resumption use the same state directory, never another upload command. `status` is local/read-only. `audit` freshly reconciles Apple, anonymous public delivery and recovery without publishing or uploading.

## 3. Delivery worker

1. Check the candidate bytes and live Apple build identity. Persist an upload intent **before** starting the one transfer. An interrupted/uncertain upload is reconciled by build registration, never blindly retransmitted.
2. Prepare/reconcile GitHub draft assets by exact digest; refuse conflicting or published replacement bytes.
3. Verify required recovery mount identity, free-space admission and fresh whole-file readback for IPA/checksum/manifest. Preserve original artifacts.
4. Push only a fast-forward public-source checkpoint and verify anonymous raw source at the candidate commit.
5. Wait for exact Apple delivery COMPLETE, build VALID, IN_BETA_TESTING, existing internal-group membership and beta-notes readback. No App Store review submission.
6. Publish GitHub and anonymously download/verify the whole IPA, embedded version/build, checksum and manifest.
7. Generate `ios-release.json` and the static mobile section from that manifest. Deploy metadata/assets before HTML using a saved, replayable CAS plan. Preserve historical checksums, other platforms, Loader/counter scripts and account state; require live exact readback.
8. Update/read back the existing operational wiki page's managed current-release block; link the canonical GitHub release instead of maintaining another hand-written release narrative.
9. Record completion and send one scoped completion notification. An uncertain notification is not blindly resent. Deliberate blockers produce a scoped alert and preserved state.

`deliver` resumes verified steps through reconciliation. It may recheck live state but never rebuilds or repeats an accepted upload. Existing assets/copies are reused only after exact identity verification. Network failures back off in the native worker for at most 24 hours; conflicting state stops it.

## Website behavior

`Website/public/downloads/ios-release.js` reads same-origin generated `ios-release.json`, validates its identity/URL and fills text/link fields without injecting HTML. The static HTML is generated from the same data and remains usable with JavaScript disabled or metadata unavailable. Browsers do not call GitHub's API. Desktop/Loader/counters are outside the mobile lane.

`site-refresh --revision UNIQUE_DEPLOYMENT_LABEL` reconciles an already-completed release, then regenerates/deploys only mobile metadata, script, static fallback and historical checksum manifest. Each intentional website revision gets a new immutable CAS plan; retries of that revision resume its exact plan. It does not build or upload an app. Inspect rollback copies and current hashes before reverting metadata; never delete or replace published payloads. Preserve and diagnose conflicts rather than restoring over concurrent changes.

## Migration and recovery

`adopt --report COMPLETED_REPORT --recovery-directory VERIFIED_EXISTING_DIRECTORY` imports only a terminal completed release, verifies native/build/validation evidence and signed IPA, and freshly reconciles Apple/public/recovery. It preserves the existing public manifest bytes and marks already-delivered notifications, preventing duplicate uploads, assets or messages. Adoption is an explicit migration operation, not an automatic response to a missing job/receipt.

If the wiki is unavailable, the worker retains its pending/blocked state; keep a private documentation draft and finish the wiki adapter after access returns. Do not claim documentation complete. If upload has an intent but no UUID and Apple has not registered the build, wait or inspect the exact upload log—do not delete the intent. A conflicting manifest, source, recovery mount, published digest or website before-hash requires operator reconciliation.

## Tests and current limits

```sh
python3 -m unittest discover -s Tools/Release/tests -v
```

Tests cover immutable candidate binding, changed artifacts, worker exclusion, interrupted uploads, quiet admission, notification deduplication, malformed metadata, static fallback preservation, read-only recovery and partial frontend replay. Reconcile an existing release before enabling delivery on a new candidate.

The sample verification plan is intentionally not runnable until the developer selects feature-specific tests. Physical Watch delivery is not established by simulator card tests. LaunchAgent crash/receipt behavior is tested synthetically; a future real upload through the new worker remains a separate observed acceptance step. Never manufacture a release to test it.
