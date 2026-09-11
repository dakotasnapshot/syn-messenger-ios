import SwiftUI

struct ConversationListView: View {
    @Environment(WatchSessionController.self) private var session
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if session.conversations.isEmpty {
                    ContentUnavailableView("No Messages",
                                           systemImage: "bubble.left.and.bubble.right",
                                           description: Text("Open SYN Messenger on your iPhone to sync."))
                } else {
                    List(session.conversations) { conversation in
                        NavigationLink(value: conversation) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(conversation.name).bold()
                                    Spacer()
                                    if conversation.unreadCount > 0 {
                                        Text("\(conversation.unreadCount)")
                                            .font(.caption2)
                                            .padding(4)
                                            .background(.tint, in: Circle())
                                    }
                                }
                                Text(conversation.preview)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .refreshable { session.refresh() }
                }
            }
            .navigationTitle("SYN")
            .navigationDestination(for: WatchConversation.self) { ConversationView(conversation: $0) }
            .toolbar {
                NavigationLink {
                    NewConversationView()
                } label: {
                    Label("New Conversation", systemImage: "square.and.pencil")
                }
            }
        }
        #if DEBUG
        .task {
            if ProcessInfo.processInfo.environment["SYN_WATCH_OPEN_FIRST_CONVERSATION"] == "1",
               let conversation = session.conversations.first {
                path.append(conversation)
            }
        }
        #endif
    }
}

private struct ConversationView: View {
    @Environment(WatchSessionController.self) private var session
    let conversation: WatchConversation
    @State private var reply = ""
    
    private var messages: [WatchMessage] {
        session.messagesByRoomID[conversation.id] ?? []
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if session.isLoadingHistory, messages.isEmpty {
                        VStack(spacing: 6) {
                            ProgressView()
                            Text(session.isPhoneReachable ? "Loading messages…" : "Waiting for iPhone…")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let historyError = session.historyError, messages.isEmpty, !session.isLoadingHistory {
                        ContentUnavailableView("History Unavailable",
                                               systemImage: "iphone.slash",
                                               description: Text(historyError))
                    }
                    if !session.isLoadingHistory, session.historyError == nil, messages.isEmpty {
                        ContentUnavailableView("No Recent Messages", systemImage: "bubble.left")
                    }
                    ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                        MessageBubble(message: message) { reaction in
                            session.toggleReaction(reaction, to: message, in: conversation)
                        }
                        .id(index)
                    }
                    TextField("SYN Message", text: $reply)
                    
                    if let status = session.replyStatus {
                        statusView(status)
                    }
                    
                    Button("Send") {
                        session.sendReply(reply, to: conversation)
                        reply = ""
                    }
                    .disabled(reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(["OK", "Thanks", "On my way", "Yes", "No"], id: \.self) { suggestion in
                                Button(suggestion) { reply = suggestion }
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .onChange(of: messages.count, initial: true) {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(100))
                    scrollToLastReceivedMessage(using: proxy)
                }
            }
        }
        .navigationTitle(conversation.name)
        .task { session.loadHistory(for: conversation) }
    }
    
    private func scrollToLastReceivedMessage(using proxy: ScrollViewProxy) {
        guard let index = messages.lastIndex(where: { !$0.isOutgoing }) ?? messages.indices.last else { return }
        proxy.scrollTo(index, anchor: .bottom)
    }
    
    @ViewBuilder
    private func statusView(_ status: WatchReplyStatus) -> some View {
        switch status {
        case .queued:
            Label("Queued for iPhone", systemImage: "clock")
        case .sending:
            ProgressView("Sending")
        case .sent:
            Label("Sent", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }
}

private struct MessageBubble: View {
    let message: WatchMessage
    let react: (String) -> Void
    @State private var showingReactionPicker = false
    
    var body: some View {
        HStack {
            if message.isOutgoing {
                Spacer(minLength: 16)
            }
            VStack(alignment: .leading, spacing: 2) {
                if !message.isOutgoing {
                    Text(message.sender).font(.caption2).foregroundStyle(.secondary)
                }
                Text(message.body)
                if let reactions = message.reactions, !reactions.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(reactions.prefix(4)) { reaction in
                            Text(reaction.count > 1 ? "\(reaction.key) \(reaction.count)" : reaction.key)
                                .font(.caption2)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                }
                Text(message.timestamp, style: .time)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(message.isOutgoing ? Color.blue.opacity(0.72) : Color.secondary.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
            if !message.isOutgoing {
                Spacer(minLength: 16)
            }
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.35) {
            showingReactionPicker = message.eventID != nil
        }
        .confirmationDialog("React to Message", isPresented: $showingReactionPicker) {
            ForEach(["❤️", "👍", "👎", "😂", "‼️", "❓"], id: \.self) { reaction in
                Button(reaction) { react(reaction) }
            }
        }
    }
}

private struct NewConversationView: View {
    @Environment(WatchSessionController.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var userID = ""
    @State private var isCreating = false
    
    var body: some View {
        Form {
            TextField("@user:server", text: $userID)
                .textInputAutocapitalization(.never)
            Button(isCreating ? "Starting…" : "Start Conversation") {
                isCreating = true
                Task {
                    if await session.startConversation(with: userID.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        session.refresh()
                        dismiss()
                    } else {
                        isCreating = false
                    }
                }
            }
            .disabled(isCreating || !userID.hasPrefix("@") || !userID.contains(":"))
        }
        .navigationTitle("New Message")
    }
}
