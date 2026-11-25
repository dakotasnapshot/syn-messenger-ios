# Watch Smart Stack verification

Compile `SYNWatch/Complications/SYNComplicationSnapshot.swift` with `SnapshotChecks.swift` using `swiftc`, then run the resulting executable. Synthetic cases cover missing/corrupt/empty caches, first unread room, negative and overflow counts, fallback names, and display labels.

For native rendering, create an isolated iOS UI test harness with `SYN_CARD_REVIEW` compilation condition; include the shipping Complications folder and ReviewApp.swift in the app, and ReviewTests.swift in its UI test target. The condition omits only the shipping widget bundle entry point. No real user stores or Matrix credentials are used. Six cases inspect the shipping rectangular card at Watch-sized bounds; they do not prove WidgetKit system delivery or physical Watch mirroring.
