# Conversation-pane composer layout

`RoomScreen` must honor the horizontal safe area supplied by a split view while its sidebar is present. The iOS27.1 full-width workaround is for detail-only content; applying it unconditionally can extend the composer behind the room list, hiding the beginning of a draft and its attachment button.

`NavigationSplitCoordinatorView` supplies the reactive `hasNavigationSidebar` environment value only inside its split-detail branch. Any column visibility other than `detailOnly` conservatively preserves the pane safe area. RoomScreen disables `synFullWidthContent` in that state. Compact navigation and sheets retain the default value; detail-only foldable layouts keep their existing full-width behavior. No device-wide idiom, fixed sidebar width or manual inset subtraction is required.

## Regression checks

`SYNComposerPaneUITests` launches the synthetic user-session fixture directly, not the screenshot baseline launcher (which pins a specific older OS/model). Open a room, reveal its sidebar when available, type `1234567891011121314151617181920212223`, backspace, and grow the draft to multiple lines. Verify its leading edge follows the room list, its trailing edge precedes Send, and attachment/Send remain usable. On a compact phone, the room-list element is absent after navigation; do not query its frame unconditionally.

Some foldable simulator versions report stale whole-application bounds and return a black cover-display image for `app.screenshot()`, even while component frames and active-screen interactions work. Compare adjacent controls in the same coordinate basis, and independently inspect an active-display native capture. Do not weaken a failing layout assertion without establishing the actual display geometry. XCTest orientation requests alone are not physical-rotation acceptance.

Use synthetic rooms only. Preserve accounts, messages, drafts and encryption storage. Simulator coverage does not establish acceptance on an affected physical iPad.
