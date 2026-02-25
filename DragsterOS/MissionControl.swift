import Foundation
import SwiftUI

// 1️⃣ THE DATA MODELS

enum FuelTier: String, Codable {
    case low = "🟢 LOW FUEL TIER (2200 kcal)"
    case medium = "🟡 MED FUEL TIER (2600 kcal)"
    case high = "🔴 HIGH FUEL TIER (3000 kcal)"
    case race = "🏁 RACE FUEL"
    
    var macros: String {
        switch self {
        case .low: return "215g P | 165g C | 80g F"
        case .medium: return "215g P | 265g C | 80g F"
        case .high: return "215g P | 375g C | 75g F"
        case .race: return "GLYCOGEN LOAD. MAX CARBS."
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        case .race: return .purple
        }
    }
}

struct TacticalMission: Identifiable {
    let id = UUID()
    var dateString: String
    var title: String
    var powerTarget: String
    var fuel: FuelTier
    var coachNotes: String
    var isAltered: Bool
}

// 2️⃣ THE PREDICTIVE ENGINE

struct MissionEngine {
    
    static func prescribeMission(scheduled: TacticalMission, readiness: Double) -> TacticalMission {
        if readiness < 40.0 && (scheduled.title.contains("Intervals") || scheduled.title.contains("Tempo")) {
            return TacticalMission(
                dateString: scheduled.dateString,
                title: "SYSTEM RECOVERY PROTOCOL",
                powerTarget: "ZONE 1 FLUSH (< 150W)",
                fuel: .low,
                coachNotes: "⚠️ CRITICAL FATIGUE DETECTED. Readiness is \(Int(readiness))/100. Spreadsheet overridden. Flush the legs, hydrate, and survive today. Do not push.",
                isAltered: true
            )
        }
        return scheduled
    }
    
    static func fetchScheduledMission() -> TacticalMission {
        // ✨ THE POLISH: Currently testing "Mar 10" to verify the parser
        if let futureMission = CSVParserEngine.testSpecificDateMission(dateString: "Mar 10") {
            return futureMission
        }
        
        return TacticalMission(
            dateString: "Today",
            title: "AWAITING NEW TRAINING BLOCK",
            powerTarget: "MAINTENANCE",
            fuel: .medium,
            coachNotes: "No mission located in the current CSV for today's date. Upload the next phase of the training block.",
            isAltered: false
        )
    }
}

// 3️⃣ THE CSV INGESTION PIPELINE

