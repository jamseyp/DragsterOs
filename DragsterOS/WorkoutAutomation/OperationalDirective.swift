//
//  OperationalDirective.swift
//  DragsterOS
//
//  Created by James Parker on 28/02/2026.
//


import Foundation
import SwiftData

@Model
final class OperationalDirective: Identifiable {
    @Attribute(.unique) var id: UUID
    var assignedDate: Date
    var discipline: String // "RUN" or "SPIN"
    var missionTitle: String
    var missionNotes: String
    
    // ⚙️ KINETIC PARAMETERS (Mapped to WorkoutKit)
    var warmupMinutes: Int
    var intervalSets: Int
    var workDurationMinutes: Int
    var workTargetWatts: Int
    var recoveryDurationMinutes: Int
    var cooldownMinutes: Int
    var fuelTier: String
    var targetLoad: Int
    var coachNotes: String
    var isCompleted: Bool
    
    
    init(
        assignedDate: Date = .now,
        discipline: String = "RUN",
        missionTitle: String = "New Mission",
        missionNotes: String = "",
        warmupMinutes: Int = 10,
        intervalSets: Int = 1,
        workDurationMinutes: Int = 30,
        workTargetWatts: Int = 200,
        recoveryDurationMinutes: Int = 2,
        cooldownMinutes: Int = 10,
        fuelTier: String = "LOW",
    targetLoad: Int = 0,
coachNotes: String = "",
        isCompleted: Bool = false
    ) {
        self.id = UUID()
        self.assignedDate = assignedDate
        self.discipline = discipline
        self.missionTitle = missionTitle
        self.missionNotes = missionNotes
        self.warmupMinutes = warmupMinutes
        self.intervalSets = intervalSets
        self.workDurationMinutes = workDurationMinutes
        self.workTargetWatts = workTargetWatts
        self.recoveryDurationMinutes = recoveryDurationMinutes
        self.cooldownMinutes = cooldownMinutes
        self.fuelTier = fuelTier
        self.targetLoad = targetLoad
        self.coachNotes = coachNotes
        self.isCompleted = isCompleted
    }
}
