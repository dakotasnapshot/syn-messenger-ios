import Foundation

struct SYNComplicationSnapshot {
    let hasSnapshot: Bool
    let unreadCount: Int
    let unreadRoom: String?
    
    static let preview = Self(hasSnapshot: true, unreadCount: 3, unreadRoom: "Messages")
    
    init(hasSnapshot: Bool, unreadCount: Int, unreadRoom: String?) {
        self.hasSnapshot = hasSnapshot
        self.unreadCount = unreadCount
        self.unreadRoom = unreadRoom
    }
    
    init(data: Data?) {
        guard let data, data.count <= 256_000,
              let conversations = try? JSONDecoder().decode([Conversation].self, from: data) else {
            self.init(hasSnapshot: false, unreadCount: 0, unreadRoom: nil)
            return
        }
        let total = conversations.reduce(0) { count, conversation in
            let addition = max(0, conversation.unreadCount)
            return count > Int.max - addition ? Int.max : count + addition
        }
        let name = conversations.first { $0.unreadCount > 0 }?.name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.init(hasSnapshot: true, unreadCount: total, unreadRoom: name?.isEmpty == false ? name : nil)
    }
    
    var countLabel: String {
        hasSnapshot ? (unreadCount > 999 ? "999+" : "\(unreadCount)") : "–"
    }
    
    var status: String {
        guard hasSnapshot else { return "Open Syndicate to sync" }
        return unreadCount == 0 ? "No unread messages" : "\(countLabel) unread"
    }
    
    private struct Conversation: Decodable {
        let name: String
        let unreadCount: Int
    }
}
