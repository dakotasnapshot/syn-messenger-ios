import SwiftUI
import WidgetKit

struct SYNEntry: TimelineEntry {
    let date: Date
    let unreadCount: Int
    let latestRoom: String?
}

struct SYNProvider: TimelineProvider {
    func placeholder(in context: Context) -> SYNEntry {
        .init(date: .now, unreadCount: 3, latestRoom: "Messages")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SYNEntry) -> Void) {
        completion(entry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SYNEntry>) -> Void) {
        completion(Timeline(entries: [entry()], policy: .after(.now.addingTimeInterval(900))))
    }
    
    private func entry() -> SYNEntry {
        let data = UserDefaults(suiteName: "group.app.syn.messenger.watch")?.data(forKey: "conversationSnapshot")
        let conversations = data.flatMap { try? JSONDecoder().decode([ComplicationConversation].self, from: $0) } ?? []
        return .init(date: .now,
                     unreadCount: conversations.reduce(0) { $0 + $1.unreadCount },
                     latestRoom: conversations.first?.name)
    }
}

private struct ComplicationConversation: Codable {
    let name: String
    let unreadCount: Int
}

struct SYNComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SYNEntry
    
    var body: some View {
        switch family {
        case .accessoryInline:
            Label("\(entry.unreadCount) unread", systemImage: "message.fill")
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Label("SYN Messenger", systemImage: "message.fill")
                Text(entry.unreadCount == 0 ? "No unread messages" : "\(entry.unreadCount) unread · \(entry.latestRoom ?? "Messages")")
                    .font(.caption)
                    .privacySensitive()
            }
        #if os(watchOS)
        case .accessoryCorner:
            Text("\(entry.unreadCount)").font(.headline).widgetLabel { Text("SYN") }
        #endif
        default:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: "message.fill")
                    Text("\(entry.unreadCount)").font(.headline)
                }
            }
        }
    }
}

struct SYNComplication: Widget {
    let kind = "SYNComplication"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SYNProvider()) { entry in
            SYNComplicationView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("SYN Messages")
        .description("See unread Matrix messages at a glance.")
        #if os(watchOS)
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryCorner, .accessoryRectangular])
        #else
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
        #endif
    }
}

@main
struct SYNComplicationBundle: WidgetBundle {
    var body: some Widget {
        SYNComplication()
    }
}
