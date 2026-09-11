//
// Copyright 2026 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing
import UserNotifications

struct UNNotificationContentTests {
    @Test
    func badgeCountUsesServerCountWhenHigher() {
        let content = UNMutableNotificationContent()
        content.userInfo = [NotificationConstants.UserInfoKey.unreadCount: 7]
        #expect(content.badgeCount(existingDeliveredNotificationCount: 2) == 7)
    }
    
    @Test
    func badgeCountUsesDeliveredNotificationsWhenHigher() {
        let content = UNMutableNotificationContent()
        content.userInfo = [NotificationConstants.UserInfoKey.unreadCount: 1]
        #expect(content.badgeCount(existingDeliveredNotificationCount: 6) == 7)
    }
}
