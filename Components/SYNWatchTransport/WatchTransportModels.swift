//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

nonisolated struct WatchConversation: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let preview: String
    let timestamp: Date
    let unreadCount: Int
}

nonisolated struct WatchMessage: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let eventID: String?
    let reactions: [WatchReaction]?
    let sender: String
    let body: String
    let timestamp: Date
    let isOutgoing: Bool
    
    init(id: String,
         eventID: String? = nil,
         reactions: [WatchReaction]? = nil,
         sender: String,
         body: String,
         timestamp: Date,
         isOutgoing: Bool) {
        self.id = id
        self.eventID = eventID
        self.reactions = reactions
        self.sender = sender
        self.body = body
        self.timestamp = timestamp
        self.isOutgoing = isOutgoing
    }
}

nonisolated struct WatchReaction: Codable, Identifiable, Hashable, Sendable {
    var id: String {
        key
    }
    
    let key: String
    let count: Int
}

nonisolated enum WatchPayloadKey {
    static let conversations = "conversations"
    static let replyRoomID = "replyRoomID"
    static let replyBody = "replyBody"
    static let replyAccepted = "replyAccepted"
    static let historyRoomID = "historyRoomID"
    static let messages = "messages"
    static let directUserID = "directUserID"
    static let directRoomID = "directRoomID"
    static let reactionRoomID = "reactionRoomID"
    static let reactionEventID = "reactionEventID"
    static let reactionKey = "reactionKey"
    static let reactionAccepted = "reactionAccepted"
}

nonisolated enum WatchReplyStatus: Equatable {
    case queued
    case sending
    case sent
    case failed(String)
}
