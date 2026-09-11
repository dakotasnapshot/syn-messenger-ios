import Foundation
import Observation
@preconcurrency import WatchConnectivity

@MainActor
@Observable
final class WatchSessionController: NSObject {
    private(set) var conversations: [WatchConversation] = []
    private(set) var isPhoneReachable = false
    private(set) var lastError: String?
    private(set) var replyStatus: WatchReplyStatus?
    private(set) var messagesByRoomID = [String: [WatchMessage]]()
    private(set) var isLoadingHistory = false
    private(set) var historyError: String?
    
    private let session: WCSession?
    private var pendingHistoryRoomID: String?
    override init() {
        session = WCSession.isSupported() ? .default : nil
        super.init()
        conversations = WatchSnapshotStore.load()
        messagesByRoomID = WatchHistoryStore.load()
        #if DEBUG
        if ProcessInfo.processInfo.environment["SYN_WATCH_DEMO"] == "1" {
            conversations = Self.demoConversations
            messagesByRoomID = Self.demoMessages
            if ProcessInfo.processInfo.environment["SYN_WATCH_DEMO_STATUS"] == "queued" {
                messagesByRoomID = [:]
                replyStatus = .queued
            }
        }
        #endif
        session?.delegate = self
        session?.activate()
    }
    
    func refresh() {
        guard let session, session.isReachable else { return }
        let replyHandler: @Sendable ([String: Any]) -> Void = { [weak self] response in
            guard let data = response[WatchPayloadKey.conversations] as? Data else { return }
            Task { @MainActor in self?.consume([WatchPayloadKey.conversations: data]) }
        }
        let errorHandler: @Sendable (any Error) -> Void = { [weak self] error in
            Task { @MainActor in self?.lastError = error.localizedDescription }
        }
        session.sendMessage(["request": "conversations"], replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    func loadHistory(for conversation: WatchConversation) {
        guard let session else { return }
        markLocallyRead(conversation.id)
        pendingHistoryRoomID = conversation.id
        isLoadingHistory = true
        historyError = nil
        
        guard session.isReachable else {
            session.transferUserInfo([WatchPayloadKey.historyRoomID: conversation.id])
            return
        }
        
        requestHistory(roomID: conversation.id, using: session)
    }
    
    private func requestHistory(roomID: String, using session: WCSession) {
        let replyHandler: @Sendable ([String: Any]) -> Void = { [weak self] response in
            guard let data = response[WatchPayloadKey.messages] as? Data else { return }
            Task { @MainActor in
                self?.consumeHistory(data: data, roomID: roomID)
            }
        }
        let errorHandler: @Sendable (any Error) -> Void = { [weak self] error in
            Task { @MainActor in
                self?.historyError = error.localizedDescription
                self?.session?.transferUserInfo([WatchPayloadKey.historyRoomID: roomID])
            }
        }
        session.sendMessage([WatchPayloadKey.historyRoomID: roomID], replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    private func consumeHistory(data: Data, roomID: String) {
        guard data.count <= 256_000,
              let messages = try? JSONDecoder().decode([WatchMessage].self, from: data) else { return }
        if !messages.isEmpty || messagesByRoomID[roomID] == nil {
            messagesByRoomID[roomID] = messages
        }
        WatchHistoryStore.save(messagesByRoomID)
        if pendingHistoryRoomID == roomID {
            pendingHistoryRoomID = nil
            isLoadingHistory = false
            historyError = nil
        }
    }
    
    func startConversation(with userID: String) async -> Bool {
        guard let session, session.isReachable else { return false }
        return await withCheckedContinuation { continuation in
            let replyHandler: @Sendable ([String: Any]) -> Void = { response in
                continuation.resume(returning: response[WatchPayloadKey.directRoomID] is String)
            }
            let errorHandler: @Sendable (any Error) -> Void = { [weak self] error in
                Task { @MainActor in self?.lastError = error.localizedDescription }
                continuation.resume(returning: false)
            }
            session.sendMessage([WatchPayloadKey.directUserID: userID], replyHandler: replyHandler, errorHandler: errorHandler)
        }
    }
    
    func sendReply(_ body: String, to conversation: WatchConversation) {
        guard let session else { return }
        let message: [String: Any] = [
            WatchPayloadKey.replyRoomID: conversation.id,
            WatchPayloadKey.replyBody: body
        ]
        
        guard session.isReachable else {
            session.transferUserInfo(message)
            replyStatus = .queued
            return
        }
        
        replyStatus = .sending
        let replyHandler: @Sendable ([String: Any]) -> Void = { [weak self] response in
            let accepted = response[WatchPayloadKey.replyAccepted] as? Bool == true
            Task { @MainActor in self?.replyStatus = accepted ? .sent : .failed("Message not sent") }
        }
        let errorHandler: @Sendable (any Error) -> Void = { [weak self] error in
            Task { @MainActor in self?.replyStatus = .failed(error.localizedDescription) }
        }
        session.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    func toggleReaction(_ key: String, to message: WatchMessage, in conversation: WatchConversation) {
        guard let session, session.isReachable, let eventID = message.eventID else { return }
        let payload: [String: Any] = [
            WatchPayloadKey.reactionRoomID: conversation.id,
            WatchPayloadKey.reactionEventID: eventID,
            WatchPayloadKey.reactionKey: key
        ]
        let replyHandler: @Sendable ([String: Any]) -> Void = { [weak self] response in
            let accepted = response[WatchPayloadKey.reactionAccepted] as? Bool == true
            Task { @MainActor in
                guard accepted else {
                    self?.lastError = "Reaction not sent"
                    return
                }
                try? await Task.sleep(for: .milliseconds(300))
                guard let session = self?.session, session.isReachable else { return }
                self?.requestHistory(roomID: conversation.id, using: session)
            }
        }
        let errorHandler: @Sendable (any Error) -> Void = { [weak self] error in
            Task { @MainActor in self?.lastError = error.localizedDescription }
        }
        session.sendMessage(payload, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    private func markLocallyRead(_ roomID: String) {
        conversations = conversations.map { conversation in
            guard conversation.id == roomID, conversation.unreadCount > 0 else { return conversation }
            return WatchConversation(id: conversation.id,
                                     name: conversation.name,
                                     preview: conversation.preview,
                                     timestamp: conversation.timestamp,
                                     unreadCount: 0)
        }
        WatchSnapshotStore.save(conversations)
    }
    
    private func consume(_ payload: [String: Any]) {
        guard let data = payload[WatchPayloadKey.conversations] as? Data,
              let decoded = try? JSONDecoder().decode([WatchConversation].self, from: data) else { return }
        conversations = decoded
        WatchSnapshotStore.save(decoded)
    }
}

#if DEBUG
private extension WatchSessionController {
    static let demoConversations = [
        WatchConversation(id: "weekend", name: "Weekend Plans", preview: "Trailhead at 9 works for me!", timestamp: .now, unreadCount: 2),
        WatchConversation(id: "studio", name: "Studio Crew", preview: "The new colors look fantastic.", timestamp: .now.addingTimeInterval(-900), unreadCount: 0),
        WatchConversation(id: "garden", name: "Community Garden", preview: "Seed swap is Saturday morning.", timestamp: .now.addingTimeInterval(-3600), unreadCount: 1)
    ]
    
    static let demoMessages = [
        "weekend": [
            WatchMessage(id: "1", sender: "Maya", body: "Want to try the lakeside trail?", timestamp: .now.addingTimeInterval(-600), isOutgoing: false),
            WatchMessage(id: "2", sender: "You", body: "Absolutely. I can bring snacks.", timestamp: .now.addingTimeInterval(-420), isOutgoing: true),
            WatchMessage(id: "3", sender: "Maya", body: "Trailhead at 9 works for me!", timestamp: .now.addingTimeInterval(-120), isOutgoing: false)
        ]
    ]
}
#endif

extension WatchSessionController: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: (any Error)?) {
        let isReachable = session.isReachable
        let errorDescription = error?.localizedDescription
        let data = session.receivedApplicationContext[WatchPayloadKey.conversations] as? Data
        Task { @MainActor in
            isPhoneReachable = isReachable
            lastError = errorDescription
            if let data {
                consume([WatchPayloadKey.conversations: data])
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let isReachable = session.isReachable
        Task { @MainActor in
            self.isPhoneReachable = isReachable
            if isReachable, let roomID = pendingHistoryRoomID {
                requestHistory(roomID: roomID, using: session)
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext[WatchPayloadKey.conversations] as? Data else { return }
        Task { @MainActor in consume([WatchPayloadKey.conversations: data]) }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let roomID = userInfo[WatchPayloadKey.historyRoomID] as? String,
              let data = userInfo[WatchPayloadKey.messages] as? Data else { return }
        Task { @MainActor in consumeHistory(data: data, roomID: roomID) }
    }
}

enum WatchSnapshotStore {
    private static let suiteName = "group.app.syn.messenger.watch"
    private static let key = "conversationSnapshot"
    
    static func save(_ conversations: [WatchConversation]) {
        guard let data = try? JSONEncoder().encode(conversations) else { return }
        UserDefaults(suiteName: suiteName)?.set(data, forKey: key)
    }
    
    static func load() -> [WatchConversation] {
        guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([WatchConversation].self, from: data)) ?? []
    }
}

enum WatchHistoryStore {
    private static let suiteName = "group.app.syn.messenger.watch"
    private static let key = "messageHistory"
    
    static func save(_ messagesByRoomID: [String: [WatchMessage]]) {
        guard let data = try? JSONEncoder().encode(messagesByRoomID) else { return }
        UserDefaults(suiteName: suiteName)?.set(data, forKey: key)
    }
    
    static func load() -> [String: [WatchMessage]] {
        guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: key), data.count <= 512_000 else { return [:] }
        return (try? JSONDecoder().decode([String: [WatchMessage]].self, from: data)) ?? [:]
    }
}
