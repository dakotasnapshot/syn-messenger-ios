//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

import Combine
import LinkPresentation
import MatrixRustSDK
import SwiftUI
import UniformTypeIdentifiers
@preconcurrency import WatchConnectivity

@MainActor
final class PhoneWatchBridge: NSObject {
    private let session: WCSession?
    private var roomsObserver: AnyCancellable?
    private var clientProxy: ClientProxyProtocol?
    private var mediaProvider: MediaProviderProtocol?
    private var latestSnapshot = [WatchConversation]()
    private var sendReply: ((String, String) async -> Bool)?
    
    override init() {
        session = WCSession.isSupported() ? .default : nil
        super.init()
        session?.delegate = self
        session?.activate()
    }
    
    func configure(userSession: UserSessionProtocol?) {
        roomsObserver?.cancel()
        clientProxy = userSession?.clientProxy
        mediaProvider = userSession?.mediaProvider
        sendReply = nil
        latestSnapshot = []
        
        guard let clientProxy else {
            publish([])
            return
        }
        
        sendReply = { [weak clientProxy] roomID, body in
            guard let clientProxy,
                  case let .joined(roomProxy) = await clientProxy.roomForIdentifier(roomID) else {
                return false
            }
            
            return await roomProxy.timeline.sendMessage(body,
                                                        html: nil,
                                                        inReplyToEventID: nil,
                                                        intentionalMentions: .empty).isSuccess
        }
        
        roomsObserver = clientProxy.staticRoomSummaryProvider.roomListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rooms in
                self?.publish(rooms.filter { !$0.isSpace && $0.joinRequestType == nil })
            }
    }
    
    private func publish(_ rooms: [RoomSummary]) {
        let snapshot = rooms.prefix(50).map {
            WatchConversation(id: $0.id,
                              name: $0.name,
                              preview: $0.lastMessage.map { String($0.characters) } ?? "",
                              timestamp: $0.lastMessageDate ?? .distantPast,
                              unreadCount: Int(min($0.unreadMessagesCount, UInt(Int.max))))
        }
        latestSnapshot = snapshot
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        do {
            try session?.updateApplicationContext([WatchPayloadKey.conversations: data])
        } catch {
            MXLog.error("Failed updating watch conversation snapshot: \(error)")
        }
    }
    
    private func encodedSnapshot() -> Data {
        (try? JSONEncoder().encode(latestSnapshot)) ?? Data("[]".utf8)
    }
    
    private func processReply(roomID: String, body: String) async -> Bool {
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let sendReply else {
            return false
        }
        return await sendReply(roomID, body)
    }
    
    private func messageHistory(roomID: String) async -> [WatchMessage] {
        guard let clientProxy,
              case let .joined(roomProxy) = await clientProxy.roomForIdentifier(roomID) else {
            return []
        }
        
        let timeline = roomProxy.timeline
        await timeline.subscribeForUpdates()
        try? await Task.sleep(for: .milliseconds(150))
        _ = await timeline.paginateBackwards(requestSize: 50)
        
        var messages = await watchMessages(from: timeline.timelineItemProvider.itemProxies)
        for _ in 0..<20 where messages.isEmpty {
            try? await Task.sleep(for: .milliseconds(100))
            messages = await watchMessages(from: timeline.timelineItemProvider.itemProxies)
        }
        
        _ = await roomProxy.markAsRead(receiptType: .read)
        _ = await roomProxy.markAsRead(receiptType: .fullyRead)
        
        return Array(messages.suffix(30))
    }
    
    private func watchMessages(from items: [TimelineItemProxy]) async -> [WatchMessage] {
        var seenIDs = Set<String>()
        var messages = [WatchMessage]()
        var thumbnailCount = 0
        var linkPreviewCount = 0
        for item in items.reversed() {
            guard case let .event(event) = item,
                  case let .msgLike(content) = event.content,
                  case let .message(message) = content.kind,
                  let body = watchBody(for: message.msgType) else {
                continue
            }
            let id = event.id.uniqueID.value
            guard seenIDs.insert(id).inserted else { continue }
            let thumbnailData: Data?
            if thumbnailCount < 2,
               case .image(let imageContent) = message.msgType,
               let data = await watchThumbnailData(for: imageContent) {
                thumbnailData = data
                thumbnailCount += 1
            } else {
                thumbnailData = nil
            }
            let linkPreview: WatchLinkPreview?
            if linkPreviewCount < 2,
               case .text = message.msgType,
               let preview = await watchLinkPreview(for: body) {
                linkPreview = preview
                linkPreviewCount += 1
            } else {
                linkPreview = nil
            }
            messages.append(WatchMessage(id: id,
                                         eventID: event.id.eventID,
                                         reactions: event.reactions.map { reaction in
                                             WatchReaction(key: String(reaction.key.prefix(16)), count: reaction.senders.count)
                                         },
                                         thumbnailData: thumbnailData,
                                         linkPreview: linkPreview,
                                         sender: String((event.sender.displayName ?? event.sender.id).prefix(100)),
                                         body: String(body.prefix(1000)),
                                         timestamp: event.timestamp,
                                         isOutgoing: event.isOwn))
            if messages.count == 30 {
                break
            }
        }
        return Array(messages.reversed())
    }
    
    private func watchLinkPreview(for body: String) async -> WatchLinkPreview? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
              let match = detector.firstMatch(in: body, range: NSRange(body.startIndex..., in: body)),
              let url = match.url,
              ["http", "https"].contains(url.scheme?.lowercased()) else {
            return nil
        }
        
        guard let metadata = try? await LPMetadataProvider().startFetchingMetadata(for: url) else {
            return WatchLinkPreview(url: url, title: url.host() ?? url.absoluteString, imageData: nil)
        }
        
        let imageData = await watchLinkPreviewImageData(from: metadata.imageProvider)
        return WatchLinkPreview(url: url,
                                title: String((metadata.title ?? url.host() ?? url.absoluteString).prefix(120)),
                                imageData: imageData)
    }
    
    private func watchLinkPreviewImageData(from provider: NSItemProvider?) async -> Data? {
        guard let provider else { return nil }
        return await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                guard let data,
                      let image = UIImage(data: data),
                      let thumbnail = image.preparingThumbnail(of: .init(width: 180, height: 100))?.jpegData(compressionQuality: 0.45),
                      thumbnail.count <= 24000 else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: thumbnail)
            }
        }
    }
    
    private func watchThumbnailData(for content: ImageMessageContent) async -> Data? {
        guard let mediaProvider else { return nil }
        let source = content.info?.thumbnailSource ?? content.source
        let mimeType = content.info?.thumbnailInfo?.mimetype ?? content.info?.mimetype
        let proxy = MediaSourceProxy(source: source, mimeType: mimeType)
        guard case let .success(data) = await mediaProvider.loadThumbnailForSource(source: proxy, size: .init(width: 180, height: 180)),
              let image = UIImage(data: data),
              let thumbnail = image.jpegData(compressionQuality: 0.5),
              thumbnail.count <= 24000 else {
            return nil
        }
        return thumbnail
    }
    
    private func toggleReaction(roomID: String, eventID: String, key: String) async -> Bool {
        guard let clientProxy,
              !key.isEmpty,
              case let .joined(roomProxy) = await clientProxy.roomForIdentifier(roomID) else {
            return false
        }
        
        return await roomProxy.timeline.toggleReaction(key, to: .eventID(eventID)).isSuccess
    }
    
    private func watchBody(for messageType: MessageType?) -> String? {
        switch messageType {
        case .text(let content): content.body
        case .notice(let content): content.body
        case .emote(let content): content.body
        case .image: "Image"
        case .video: "Video"
        case .audio: "Audio"
        case .file: "File"
        case .location: "Location"
        case .gallery: "Gallery"
        case .other(_, let body): body
        case nil: nil
        }
    }
    
    private func startDirectConversation(userID: String) async -> String? {
        guard let clientProxy,
              userID.hasPrefix("@"), userID.contains(":"),
              case let .success(roomID) = await clientProxy.createDirectRoom(with: userID, expectedRoomName: nil) else {
            return nil
        }
        return roomID
    }
}

extension PhoneWatchBridge: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: (any Error)?) {
        if let error {
            MXLog.error("WatchConnectivity activation failed: \(error)")
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) { }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String: Any],
                             replyHandler: @escaping ([String: Any]) -> Void) {
        let reply = UnsafeSendable(value: replyHandler)
        if message["request"] as? String == "conversations" {
            Task { @MainActor in
                reply.value([WatchPayloadKey.conversations: encodedSnapshot()])
            }
            return
        }
        
        if let roomID = message[WatchPayloadKey.historyRoomID] as? String {
            Task { @MainActor in
                let history = await messageHistory(roomID: roomID)
                let data = (try? JSONEncoder().encode(history)) ?? Data("[]".utf8)
                reply.value([WatchPayloadKey.messages: data])
            }
            return
        }
        
        if let userID = message[WatchPayloadKey.directUserID] as? String {
            Task { @MainActor in
                guard let roomID = await startDirectConversation(userID: userID) else {
                    reply.value([:])
                    return
                }
                reply.value([WatchPayloadKey.directRoomID: roomID])
            }
            return
        }
        
        if let roomID = message[WatchPayloadKey.reactionRoomID] as? String,
           let eventID = message[WatchPayloadKey.reactionEventID] as? String,
           let key = message[WatchPayloadKey.reactionKey] as? String {
            Task { @MainActor in
                let accepted = await toggleReaction(roomID: roomID, eventID: eventID, key: key)
                reply.value([WatchPayloadKey.reactionAccepted: accepted])
            }
            return
        }
        
        guard let roomID = message[WatchPayloadKey.replyRoomID] as? String,
              let body = message[WatchPayloadKey.replyBody] as? String else {
            reply.value([WatchPayloadKey.replyAccepted: false])
            return
        }
        
        Task { @MainActor in
            let accepted = await processReply(roomID: roomID, body: body)
            reply.value([WatchPayloadKey.replyAccepted: accepted])
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        if userInfo[WatchPayloadKey.requestConversations] as? Bool == true {
            Task { @MainActor in
                session.transferUserInfo([WatchPayloadKey.conversations: encodedSnapshot()])
            }
            return
        }
        
        if let roomID = userInfo[WatchPayloadKey.historyRoomID] as? String {
            Task { @MainActor in
                let history = await messageHistory(roomID: roomID)
                let data = (try? JSONEncoder().encode(history)) ?? Data("[]".utf8)
                session.transferUserInfo([
                    WatchPayloadKey.historyRoomID: roomID,
                    WatchPayloadKey.messages: data
                ])
            }
            return
        }
        
        guard let roomID = userInfo[WatchPayloadKey.replyRoomID] as? String,
              let body = userInfo[WatchPayloadKey.replyBody] as? String else { return }
        Task { @MainActor in
            _ = await processReply(roomID: roomID, body: body)
        }
    }
}

private nonisolated extension Result {
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}

/// WatchConnectivity predates Swift concurrency and doesn't annotate its reply callback as Sendable.
private nonisolated struct UnsafeSendable<Value>: @unchecked Sendable {
    let value: Value
}
