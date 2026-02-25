import SwiftUI

// 📐 ARCHITECTURE: The tactical data structures.
// We make FuelTier Codable so it can eventually be stored directly in SwiftData.

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

struct TacticalMission {
    var title: String
    var powerTarget: String
    var fuel: FuelTier
    var coachNotes: String
    var isAltered: Bool // Flags if the Engine overrode the spreadsheet
}

// 🧠 THE ALGORITHM: The Race Engineer
struct MissionEngine {
    
    /// Dynamically prescribes the daily mission based on physiological readiness.
    static func prescribeMission(scheduled: TacticalMission, readiness: Double) -> TacticalMission {
        
        // ✨ THE POLISH: If the engine detects critical central nervous system fatigue,
        // it actively overrides high-intensity spreadsheet workouts to protect the athlete.
        
        if readiness < 40.0 && scheduled.title.contains("Intervals") || scheduled.title.contains("Tempo") {
            // 🚨 SYSTEM FAULT DETECTED
            return TacticalMission(
                title: "SYSTEM RECOVERY PROTOCOL",
                powerTarget: "ZONE 1 FLUSH (< 150W)",
                fuel: .low,
                coachNotes: "⚠️ CRITICAL FATIGUE DETECTED. Readiness is \(Int(readiness))/100. Spreadsheet overridden. Flush the legs, hydrate, and survive today. Do not push.",
                isAltered: true
            )
        } else if readiness > 85.0 && scheduled.title.contains("Intervals") {
            // 🚀 PRIME DETECTED
            var upgradedMission = scheduled
            upgradedMission.coachNotes = "🟢 OPTIMAL READINESS (\(Int(readiness))/100). The engine is primed. You have clearance to push the wattage ceiling on the final 2 intervals today."
            return upgradedMission
        }
        
        // If readiness is standard, proceed with the spreadsheet plan.
        return scheduled
    }
    
    // TEMPORARY MOCK DATA: In Phase 3, we will load your entire CSV directly into SwiftData.
    // For now, we pull today's scheduled workout from your current block.
    static func fetchScheduledMission() -> TacticalMission {
        return TacticalMission(
            title: "Taper Intervals (3 x 800m @ Race Pace)",
            powerTarget: "312W - 336W",
            fuel: .medium,
            coachNotes: "Practice 5:48/km pace. Sharp but not hard. Keep cadence 170+.",
            isAltered: false
        )
    }
}
