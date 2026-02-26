import Foundation
import SwiftData

// MARK: - 🗺️ THE MACRO-CYCLE MODEL
/// Represents a single prescribed day in the 10-week Half-Marathon block.
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
    
    // Tactical State (We will use these later!)
    var isCompleted: Bool
    var isAlteredBySystem: Bool // True if low readiness caused a downgrade
    
    init(
        week: Int,
        dateString: String,
        date: Date,
        activity: String,
        powerTarget: String,
        strength: String,
        energyProtocol: String,
        commandersIntent: String,
        isCompleted: Bool = false,
        isAlteredBySystem: Bool = false
    ) {
        self.id = UUID()
        self.week = week
        self.dateString = dateString
        self.date = date
        self.activity = activity
        self.powerTarget = powerTarget
        self.strength = strength
        self.fuelTier = energyProtocol
        self.coachNotes = commandersIntent
        self.isCompleted = isCompleted
        self.isAlteredBySystem = isAlteredBySystem
    }
}

typealias OperationalDirective = PlannedMission
