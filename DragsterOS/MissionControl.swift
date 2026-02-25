import Foundation
import SwiftUI
import SwiftData

// MARK: - 1️⃣ THE DATA MODELS

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
        case .high: return ColorTheme.critical
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

// MARK: - 2️⃣ THE PREDICTIVE ENGINE

struct MissionEngine {
    
    /// Modifies the mission dynamically if the user is fatigued
    static func prescribeMission(scheduled: TacticalMission, readiness: Double) -> TacticalMission {
        var adjusted = scheduled
        
        // 🚨 CRITICAL DEBT: Readiness < 40
        if readiness < 40.0 && (scheduled.title.contains("INTERVAL") || scheduled.title.contains("TEMPO") || scheduled.title.contains("LONG")) {
            adjusted.title = "SYSTEM RECOVERY: \(scheduled.title)"
            adjusted.powerTarget = "ZONE 1 FLUSH (< 140W)"
            adjusted.fuel = .low
            adjusted.isAltered = true
            adjusted.coachNotes = "⚠️ CRITICAL FATIGUE DETECTED (Readiness: \(Int(readiness))). Overriding planned intensity. Focus on blood flow, do not exceed Zone 1."
            return adjusted
        }
        
        // 🟡 SUB-OPTIMAL: Readiness 40 - 65
        if readiness >= 40.0 && readiness < 65.0 && (scheduled.title.contains("INTERVAL") || scheduled.title.contains("TEMPO")) {
            adjusted.isAltered = true
            
            // Safe String Parsing: Look for numbers specifically attached to 'W'
            let components = scheduled.powerTarget.components(separatedBy: .whitespaces)
            var scaledTarget = ""
            
            for word in components {
                let cleanWord = word.replacingOccurrences(of: "W", with: "")
                if let watts = Double(cleanWord), word.contains("W") {
                    let scaledWatts = Int(watts * 0.90) // Reduce by 10%
                    scaledTarget += "\(scaledWatts)W "
                } else {
                    scaledTarget += "\(word) "
                }
            }
            
            adjusted.powerTarget = scaledTarget.trimmingCharacters(in: .whitespaces)
            adjusted.coachNotes = "🟡 MODERATE DEBT (Readiness: \(Int(readiness))). System has automatically scaled your power targets down by 10% to protect the structural system.\n\n" + scheduled.coachNotes
            return adjusted
        }
        
        return adjusted
    }
    
    /// Pulls today's mission directly from the SwiftData cache
    static func fetchTodayMission(context: ModelContext) -> TacticalMission {
        let today = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<PlannedMission>()
        let allMissions = (try? context.fetch(descriptor)) ?? []
        
        // Search the SwiftData array for a mission matching today's date
        if let planned = allMissions.first(where: { Calendar.current.startOfDay(for: $0.date) == today }) {
            
            // Map the text fuel string to our UI enum
            let mappedFuel: FuelTier
            if planned.fuelTier.contains("LOW") { mappedFuel = .low }
            else if planned.fuelTier.contains("MED") { mappedFuel = .medium }
            else if planned.fuelTier.contains("HIGH") { mappedFuel = .high }
            else if planned.fuelTier.contains("RACE") { mappedFuel = .race }
            else { mappedFuel = .medium }
            
            // Append structural lifting notes if they exist
            var finalNotes = planned.coachNotes
            if planned.strength.lowercased() != "rest" && !planned.strength.isEmpty {
                finalNotes = "STRUCTURAL LOAD: \(planned.strength). " + finalNotes
            }
            
            return TacticalMission(
                dateString: planned.dateString,
                title: planned.activity.uppercased(),
                powerTarget: planned.powerTarget.uppercased(),
                fuel: mappedFuel,
                coachNotes: finalNotes,
                isAltered: false
            )
        }
        
        // Fallback if today is a rest day or not in the CSV
        return TacticalMission(
            dateString: Date().formatted(date: .abbreviated, time: .omitted),
            title: "REST / FREELANCE",
            powerTarget: "MAINTENANCE",
            fuel: .medium,
            coachNotes: "No mission located in the database for today's date. Enjoy the rest day or log a freelance session.",
            isAltered: false
        )
    }
}
