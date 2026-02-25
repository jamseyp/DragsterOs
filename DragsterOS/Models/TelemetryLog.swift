import Foundation
import SwiftData

// 📐 ARCHITECTURE: A unified, flat schema optimized for high-speed SwiftData queries.
// We group properties logically to separate baseline vitals from kinetic output.

@Model
final class TelemetryLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    
    // --- 🫀 BIOMETRIC BASELINE ---
    var hrv: Double
    var restingHR: Double
    var sleepDuration: Double // In hours
    var weightKG: Double
    var subjectiveSoreness: Double // 1-10 scale
    var readinessScore: Double // Calculated 0-100
    
    // --- ⚡️ KINETIC OUTPUT (Performance) ---
    var maxPower: Double?      // Watts (Optional for rest days)
    var avgCadence: Double?    // SPM
    var intervalPace: String?  // e.g., "4:50/km"
    
    // --- 🥩 NUTRITIONAL PROTOCOL ---
    var proteinGrams: Double
    
    init(
        date: Date = .now,
        hrv: Double = 0.0,
        restingHR: Double = 0.0,
        sleepDuration: Double = 0.0,
        weightKG: Double = 0.0,
        subjectiveSoreness: Double = 0.0,
        readinessScore: Double = 0.0,
        maxPower: Double? = nil,
        avgCadence: Double? = nil,
        intervalPace: String? = nil,
        proteinGrams: Double = 0.0
    ) {
        self.id = UUID()
        self.date = date
        self.hrv = hrv
        self.restingHR = restingHR
        self.sleepDuration = sleepDuration
        self.weightKG = weightKG
        self.subjectiveSoreness = subjectiveSoreness
        self.readinessScore = readinessScore
        self.maxPower = maxPower
        self.avgCadence = avgCadence
        self.intervalPace = intervalPace
        self.proteinGrams = proteinGrams
    }
}
