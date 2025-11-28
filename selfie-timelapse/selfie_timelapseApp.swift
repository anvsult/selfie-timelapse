import SwiftUI
import SwiftData
import Combine

@main
struct SelfieTimelapseApp: App {
    @AppStorage("colorScheme") private var colorSchemeString = "system"
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SelfieRecord.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var locationManager = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(notificationManager)
                .environmentObject(locationManager)
                .preferredColorScheme(colorSchemeString == "system" ? nil : (colorSchemeString == "dark" ? .dark : .light))
        }
        .modelContainer(sharedModelContainer)
    }
}
