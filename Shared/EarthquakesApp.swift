/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app and main window group scene.
*/

import SwiftUI
#if os(iOS)
import LuciqSDK
#endif

@main
struct EarthquakesApp: App {
    init() {
        #if os(iOS)
        // LUCIQ_APP_TOKEN is injected into Info.plist from Configuration/Secrets.xcconfig (gitignored).
        if let token = Bundle.main.object(forInfoDictionaryKey: "LuciqAppToken") as? String, !token.isEmpty {
            Luciq.start(withToken: token, invocationEvents: [.shake, .floatingButton])
        } else {
            print("Luciq: LUCIQ_APP_TOKEN is not set in Configuration/Secrets.xcconfig; SDK not started.")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            // SwiftUI screens only report screen loading to Luciq APM when wrapped.
            LuciqTracedView(name: "Earthquakes") { content }
            #else
            content
            #endif
        }
    }

    private var content: some View {
        ContentView()
            .environment(\.managedObjectContext, QuakesProvider.shared.container.viewContext)
    }
}
