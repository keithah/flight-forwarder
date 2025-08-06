import SwiftUI

@main
struct FlightForwarderApp: App {
    @StateObject private var configurationManager = ConfigurationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configurationManager)
        }
    }
}