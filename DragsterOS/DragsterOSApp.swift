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

    var body: some Scene {
            WindowGroup {
                ContentView()
                    // ✨ THE FIX: We must declare all of our custom models here
                    .modelContainer(for: [
                        TelemetryLog.self,
                        RunningShoe.self,
                        ChassisSnapshot.self,
                        KineticSession.self,
                        PlannedMission.self,
                        ChassisLog.self,
                        StrategicObjective.self,
                        UserRegistry.self // ✨ ADD THIS LINE
                    ])
                    // Force pure dark mode across the entire application
                   // .preferredColorScheme(.dark)
            }
        }
}
