# Duo full-width navigation

On iOS 27.1, the cover layout uses the full available width with floating Chats/Spaces controls. Home and Spaces reserve measured scroll clearance for that overlay, including accessibility text sizes. Selecting a conversation focuses the detail column; the native sidebar toggle restores navigation.

Conversation content extends through unused horizontal tab-bar safe areas. Active system display divisions retain their safe-area clearances, so partially folded layouts are not promised to be edge-to-edge. Older iOS keeps the existing native navigation controls.

The inverted timeline uses bounds and center for resizing, not frame (undefined under its nonidentity transform). Hosted timeline content does not reapply keyboard/container safe areas inside each cell: the containing table already owns viewport clipping and insets. Draft content remains in the existing composer service; screenshot fixtures use a coherent in-memory room/thread store.

Restored Markdown user mentions retain SDK-recognized Matrix URIs internally rather than prematurely converting them to branded web links. This preserves intentional-mention metadata when sending a restored draft.

Acceptance evidence and release receipt are recorded separately. Physical tent posture remains unverified. App Store submission is separate from TestFlight delivery.
