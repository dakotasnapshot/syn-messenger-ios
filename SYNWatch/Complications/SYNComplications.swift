import SwiftUI
import WidgetKit

struct SYNEntry: TimelineEntry {
    let date: Date
    let snapshot: SYNComplicationSnapshot
}

struct SYNProvider: TimelineProvider {
    func placeholder(in context: Context) -> SYNEntry {
        .init(date: .now, snapshot: .preview)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SYNEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : entry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SYNEntry>) -> Void) {
        completion(Timeline(entries: [entry()], policy: .after(.now.addingTimeInterval(900))))
    }
    
    private func entry() -> SYNEntry {
        let data = UserDefaults(suiteName: "group.app.syn.messenger.watch")?.data(forKey: "conversationSnapshot")
        return .init(date: .now, snapshot: .init(data: data))
    }
}

struct SYNComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SYNEntry
    
    var body: some View {
        content
            .privacySensitive()
            .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:
            Label(entry.snapshot.status, systemImage: "message.fill")
        case .accessoryRectangular:
            SYNSmartStackCard(snapshot: entry.snapshot)
        #if os(watchOS)
        case .accessoryCorner:
            Text(entry.snapshot.countLabel).font(.headline).widgetLabel { Text("SYN") }
        #endif
        default:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: "message.fill")
                    Text(entry.snapshot.countLabel).font(.headline)
                }
            }
        }
    }
}

struct SYNSmartStackCard: View {
    let snapshot: SYNComplicationSnapshot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Syndicate", systemImage: "message.fill")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(snapshot.status)
                .font(.caption)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            if let room = snapshot.unreadRoom, snapshot.unreadCount > 0 {
                Text(room).font(.caption2).lineLimit(1)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .privacySensitive()
        .accessibilityElement(children: .combine)
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

struct SYNSmartStackCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SYNSmartStackCard(snapshot: .init(data: nil))
                .previewDisplayName("Sync needed")
            SYNSmartStackCard(snapshot: .init(hasSnapshot: true, unreadCount: 0, unreadRoom: nil))
                .previewDisplayName("No unread messages")
            SYNSmartStackCard(snapshot: .preview)
                .previewDisplayName("Unread messages")
        }
        .previewLayout(.fixed(width: 170, height: 90))
    }
}

#if !SYN_CARD_REVIEW
@main
struct SYNComplicationBundle: WidgetBundle {
    var body: some Widget {
        SYNComplication()
    }
}

#endif
