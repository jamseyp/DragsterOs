import Foundation
import SwiftData

// MARK: - 🗺️ THE MACRO-CYCLE MODEL
/// Represents a single prescribed day in the macro-cycle block.
@Model
final class PlannedMission {
    @Attribute(.unique) var id: UUID
    var week: Int
    var dateString: String // e.g., "Mar-09"
    var date: Date // Mathematically linked Date object for sorting
    var activity: String
    var powerTarget: String
    var strength: String
    var fuelTier: String
    var coachNotes: String
    var targetLoad: Double
    
    // Tactical State
    var isCompleted: Bool
    var isAlteredBySystem: Bool // True if low readiness caused a downgrade
    
    // ✨ UPDATED: Added default values so manual UI injection doesn't crash the compiler
    init(
        week: Int = 0,
        dateString: String = "",
        date: Date = .now,
        activity: String = "UNASSIGNED",
        powerTarget: String = "",
        strength: String = "",
        fuelTier: String = "LOW",
        coachNotes: String = "",
        targetLoad: Double = 0.0,
        isCompleted: Bool = false,
        isAlteredBySystem: Bool = false
    ) {
        self.id = UUID()
        self.week = week
        
        // ✨ LOGIC: If a manual mission is injected, auto-generate the CSV-style dateString
        if dateString.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM-dd"
            self.dateString = formatter.string(from: date)
        } else {
            self.dateString = dateString
        }
        
        self.date = date
        self.activity = activity
        self.powerTarget = powerTarget
        self.strength = strength
        self.fuelTier = fuelTier
        self.coachNotes = coachNotes
        self.targetLoad = targetLoad
        self.isCompleted = isCompleted
        self.isAlteredBySystem = isAlteredBySystem
    }
}

// Seamless alias so the rest of the OS continues to function without refactoring
typealias OperationalDirective = PlannedMission
