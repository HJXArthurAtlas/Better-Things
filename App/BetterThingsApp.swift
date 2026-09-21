import SwiftUI
import BetterThingsKit

@main
struct BetterThingsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Better Things")
                .font(.title)
            Text(BetterThingsKit.version)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(minWidth: 360, minHeight: 200)
    }
}
