//
//  DragsterOSApp.swift
//  DragsterOS
//
//  Created by James Parker on 23/02/2026.
//

import SwiftUI
import SwiftData

@main
struct DragsterOSApp: App {
    
    // 📐 ARCHITECTURE: Explicitly define the container as a property
    // This allows us to access the context for system calibration on launch.
    var container: ModelContainer = {
        let schema = Schema([
            TelemetryLog.self,
            RunningShoe.self,
            BodySnapshot.self,
            KineticSession.self,
            PlannedMission.self,
            BodyMeasurementLog.self,
            StrategicObjective.self,
            UserRegistry.self,
            OperationalDirective.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Start the system calibration on launch
                    ensureRegistryExists()
                }
                // Force pure dark mode across the entire application
                // .preferredColorScheme(.dark)
        }
        // ✨ Point the app to the container variable we defined above
        .modelContainer(container)
    }

    // ✨ THE FIX: Ensuring the Engine has its Calibration Data
    // This is now properly placed INSIDE the DragsterOSApp struct.
    @MainActor
    private func ensureRegistryExists() {
        // Use the 'container' property we defined at the top
        let context = container.mainContext
        let descriptor = FetchDescriptor<UserRegistry>()
        
        do {
            let existing = try context.fetch(descriptor)
            if existing.isEmpty {
                // Initializing with your specific 90kg target / 95kg baseline
                let defaultRegistry = UserRegistry(
                    targetWeight: 90.0,
                    ftp: 250,
                    z2: 145
                )
                context.insert(defaultRegistry)
                try context.save()
                print("✅ SYSTEM CALIBRATION: UserRegistry Initialized.")
            }
        } catch {
            print("❌ REGISTRY FAULT: \(error.localizedDescription)")
        }
    }
}
