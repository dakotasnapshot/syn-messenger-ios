import SwiftUI
import WidgetKit

@main struct ReviewApp: App {
    let mode = ProcessInfo.processInfo.environment["CARD_CASE"] ?? "unread"
    var snapshot: SYNComplicationSnapshot {
        switch mode {
        case "missing": return .init(data: nil)
        case "corrupt": return .init(data: Data("broken".utf8))
        case "empty": return .init(data: Data("[]".utf8))
        case "long", "large": return .init(hasSnapshot: true, unreadCount: 12345, unreadRoom: "A very long synthetic conversation title for layout review")
        default: return .init(hasSnapshot: true, unreadCount: 3, unreadRoom: "Team")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 24) {
                Text("Watch-sized Syndicate card")
                SYNSmartStackCard(snapshot: snapshot)
                    .frame(width: 170, height: 90, alignment: .leading)
                    .padding(12).background(.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityIdentifier("syn-card")
                    .dynamicTypeSize(mode == "large" ? .accessibility3 : .large)
            }
        }
    }
}
