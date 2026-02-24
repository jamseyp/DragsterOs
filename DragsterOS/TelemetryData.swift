//
//  TelemetryData.swift
//  DragsterOS
//
//  Created by James Parker on 24/02/2026.
//

import Foundation

struct PaddockReport: Identifiable {
        let id = UUID()
        let date: Date
        let readinessScore: Int // Out of 10
        let restingHR: Int
        let hrvStatus: String // e.g., "Parasympathetic"
        let intervalPace: String // e.g., "4:50/km"
        let maxPower: Int // Watts
        let averageCadence: Int // SPM
    
}
