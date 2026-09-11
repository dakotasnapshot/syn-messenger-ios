//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

@testable import ElementX
import Foundation
import Testing

struct WatchTransportModelsTests {
    @Test
    func conversationRoundTripsBetweenPhoneAndWatch() throws {
        let timestamp = Date(timeIntervalSince1970: 1_788_703_200)
        let expected = WatchConversation(id: "!public-example:example.org",
                                         name: "Weekend plans",
                                         preview: "Meet at ten?",
                                         timestamp: timestamp,
                                         unreadCount: 2)
        
        let data = try JSONEncoder().encode([expected])
        let decoded = try JSONDecoder().decode([WatchConversation].self, from: data)
        
        #expect(decoded == [expected])
    }
    
    @Test
    func messageRoundTripsBetweenPhoneAndWatch() throws {
        let expected = WatchMessage(id: "$synthetic-event",
                                    eventID: "$synthetic-event",
                                    reactions: [WatchReaction(key: "👍", count: 2)],
                                    sender: "Alice",
                                    body: "See you soon",
                                    timestamp: Date(timeIntervalSince1970: 1_788_703_200),
                                    isOutgoing: false)
        
        let data = try JSONEncoder().encode([expected])
        let decoded = try JSONDecoder().decode([WatchMessage].self, from: data)
        
        #expect(decoded == [expected])
    }
    
    @Test
    func messageWithoutReactionIdentifierStillDecodes() throws {
        let data = Data(#"{"id":"legacy","sender":"Alice","body":"Hello","timestamp":0,"isOutgoing":false}"#.utf8)
        let decoded = try JSONDecoder().decode(WatchMessage.self, from: data)
        
        #expect(decoded.eventID == nil)
    }
    
    @Test
    func payloadKeysRemainStable() {
        #expect(WatchPayloadKey.conversations == "conversations")
        #expect(WatchPayloadKey.replyRoomID == "replyRoomID")
        #expect(WatchPayloadKey.replyBody == "replyBody")
        #expect(WatchPayloadKey.replyAccepted == "replyAccepted")
        #expect(WatchPayloadKey.historyRoomID == "historyRoomID")
        #expect(WatchPayloadKey.messages == "messages")
        #expect(WatchPayloadKey.directUserID == "directUserID")
        #expect(WatchPayloadKey.directRoomID == "directRoomID")
        #expect(WatchPayloadKey.reactionRoomID == "reactionRoomID")
        #expect(WatchPayloadKey.reactionEventID == "reactionEventID")
        #expect(WatchPayloadKey.reactionKey == "reactionKey")
        #expect(WatchPayloadKey.reactionAccepted == "reactionAccepted")
    }
}
