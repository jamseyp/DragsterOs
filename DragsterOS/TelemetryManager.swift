//
//  TelemetryManager.swift
//  DragsterOS
//
//  Created by James Parker on 24/02/2026.
//

import Foundation

class TelemetryManager: ObservableObject {
    @Published var currentReport: PaddockReport
    
    init() {
        // This is your actual data from this morning hardcoded as the simulator!
        self.currentReport = PaddockReport(
            date: Date(),
            readinessScore: 8,
            restingHR: 48,
            hrvStatus: "Parasympathetic",
            intervalPace: "4:50/km",
            maxPower: 336,
            averageCadence: 175
        )
    }
}
