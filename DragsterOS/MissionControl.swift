import SwiftUI

// 1. THE FUEL MAP (From your Macros & Calories sheet)
enum FuelTier: String {
    case low = "🟢 LOW FUEL (2200 kcal)"
    case medium = "🟡 MED FUEL (2600 kcal)"
    case high = "🔴 HIGH FUEL (3000 kcal)"
    case race = "🏁 RACE FUEL"
    
    var macros: String {
        switch self {
        case .low: return "215g P | 165g C | 80g F"
        case .medium: return "215g P | 265g C | 80g F"
        case .high: return "215g P | 375g C | 75g F"
        case .race: return "MAX CARBS. PREP THE ENGINE."
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

// 2. THE MISSION STRUCT
struct DailyMission {
    let date: String
    let activity: String
    let powerTarget: String
    let strength: String
    let fuel: FuelTier
    let coachNotes: String
}

// 3. THE SPREADSHEET DATA (Current Block)
class MissionManager: ObservableObject {
    @Published var todaysMission: DailyMission
    
    init() {
        // Hardcoded to today's actual spreadsheet entry (Feb 24)
        self.todaysMission = DailyMission(
            date: "FEB 24 - TUE",
            activity: "Taper Intervals (3 x 800m @ Race Pace)",
            powerTarget: "312W - 336W", // Updated based on your actual morning run!
            strength: "Rest",
            fuel: .medium,
            coachNotes: "Practice 5:48/km pace. Sharp but not hard."
        )
    }
}
