# Syndicate 11.16.26 (48) — suspension safety

## Changes

- Give every asynchronous client shutdown its own UIKit background assertion. Release only that assertion when its work finishes or iOS expires it.
- Keep pending database shutdown protected when the app returns to the foreground. Do not cancel the shutdown or release its protection before completion.
- Do not skip a new background shutdown merely because an earlier one is still pending, or let an old completion release a newer assertion.
- Acquire background protection before resuming services for an incoming VoIP call, retaining it through the subsequent pause.
- Keep the foreground sync-state observer when an older background pause finishes after foregrounding.

## Scope

This addresses concrete lifecycle races relevant to suspension-time file-lock terminations. It does not establish a fix for every sync stall, Wi-Fi reconnection issue, SDK search-index merge, or database-lock termination. No account reset, logout, database deletion, encryption-key migration, SDK replacement, or search-feature removal is included.

The existing development-only notification schedule editor remains Debug-only. This release does not enable or claim notification filtering/scheduling acceptance.

## Verification

Pending candidate verification. Do not treat this document as upload or tester-availability evidence until the terminal release receipt is recorded.

Physical-device reproduction of suspension with an authenticated account remains a follow-up acceptance check. Simulator smoke checks do not reproduce iOS physical-device suspension enforcement.
