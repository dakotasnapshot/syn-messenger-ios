import Foundation

@main struct Checks {
    static func main() {
        func check(_ raw: String?, _ available: Bool, _ count: Int, _ room: String?) {
            let value = SYNComplicationSnapshot(data: raw?.data(using: .utf8))
            precondition(value.hasSnapshot == available && value.unreadCount == count && value.unreadRoom == room)
        }
        check(nil, false, 0, nil)
        check("broken", false, 0, nil)
        check("{}", false, 0, nil)
        check("[]", true, 0, nil)
        check(#"[{"name":"Quiet","unreadCount":0}]"#, true, 0, nil)
        check(#"[{"name":"Quiet","unreadCount":0},{"name":"Team","unreadCount":4}]"#, true, 4, "Team")
        check(#"[{"name":"Negative","unreadCount":-5},{"name":"Team","unreadCount":3}]"#, true, 3, "Team")
        check(#"[{"name":"  ","unreadCount":3}]"#, true, 3, nil)
        check(#"[{"name":"Room","unreadCount":9223372036854775807},{"name":"Other","unreadCount":1}]"#, true, Int.max, "Room")
        check(#"[{"name":"Incomplete"}]"#, false, 0, nil)
        precondition(SYNComplicationSnapshot(data: nil).status == "Open Syndicate to sync")
        precondition(SYNComplicationSnapshot(hasSnapshot: true, unreadCount: 1000, unreadRoom: nil).countLabel == "999+")
        precondition(SYNComplicationSnapshot(data: Data("[]".utf8)).status == "No unread messages")
        print("13 snapshot cases passed")
    }
}
