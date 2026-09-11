import SwiftUI

@main
struct SYNWatchApp: App {
    @State private var session = WatchSessionController()
    
    var body: some Scene {
        WindowGroup {
            ConversationListView()
                .environment(session)
        }
    }
}
