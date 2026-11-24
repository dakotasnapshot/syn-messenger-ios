# Conversation-list sidebar surface

The split view supplies `isInSidebar` to its primary column. `HomeScreenContent` uses that context to give the conversation-list viewport a 24-point continuous rounded outline aligned to the scroll view’s measured top content inset and a 32-point alpha fade at its bottom edge. The list extends through the bottom container safe area without ignoring the keyboard safe area. A 40-point scroll-content bottom margin lets the final conversation move fully above the fade before selection. The fade is a mask, not an overlay that intercepts taps. The canvas background belongs inside that mask; a separate opaque HomeScreen background would fill the rounded corners and restore the hard lower edge. The mask follows `onScrollGeometryChange` content insets because an ancestor GeometryReader can report zero top safe-area inset even when the native navigation bar covers the scroll view.

Sidebar conversation rows use continuous 14-point corners with small horizontal and vertical insets, including the selected background. Existing retro-theme corner/inset choices remain. Compact navigation retains its original list surface, navigation clearance and row geometry; no device-idiom checks or hardcoded screen dimensions are used.

## Verification

`SYNConversationListUITests` launches the synthetic user-session coordinator with `UI_TESTS_LONG_ROOM_LIST=1`, adding 24 synthetic rooms. It checks that a sidebar viewport reaches the bottom, scrolls the final row entirely above the fade, and opens that room. Use full-display screenshot attachments to inspect rounding, fade and selection. Repeat on iPad portrait/landscape and compact iPhone, in light/dark appearances. The fixture is isolated from production accounts and is not release data.

Preserve the conversation-pane composer checks in `SYNComposerPaneUITests`; changing the sidebar's appearance must not reintroduce leading-input clipping. Simulator results do not establish acceptance on an unavailable physical iPad.
