import Foundation
import SwiftData

// 📐 ARCHITECTURE: A unified, flat schema optimized for high-speed SwiftData queries.
// We group properties logically to separate baseline vitals from kinetic output.
@Model
final class TelemetryLog {
    @Attribute(.unique) var date: Date
    var hrv: Double
    var restingHR: Double
    var sleepDuration: Double
    var weightKG: Double
    var readinessScore: Double
    
    // ✨ ADD THESE PROPERTIES
    var rmssd: Double?
    var eliteReadiness: Int?
    
    init(date: Date, hrv: Double, restingHR: Double, sleepDuration: Double, weightKG: Double, readinessScore: Double, rmssd: Double? = nil, eliteReadiness: Int? = nil) {
        self.date = date
        self.hrv = hrv
        self.restingHR = restingHR
        self.sleepDuration = sleepDuration
        self.weightKG = weightKG
        self.readinessScore = readinessScore
        self.rmssd = rmssd
        self.eliteReadiness = eliteReadiness
    }
}
