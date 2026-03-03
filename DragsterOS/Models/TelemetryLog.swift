import Foundation
import SwiftData

/// The biological ground-truth of the athlete's recovery status.
/// Captures central nervous system (CNS) readiness and restorative metrics.
@Model
final class TelemetryLog {
    /// A unique identifier ensuring absolute data integrity across sync operations.
    @Attribute(.unique) var id: UUID
    
    /// The exact timestamp the physiological reading was recorded.
    var date: Date
    
    /// Standard deviation of normal-to-normal heartbeats (SDNN) - Apple Health's default.
    var hrv: Double
    
    /// Root mean square of successive differences (RMSSD) - The elite standard for parasympathetic tone.
    var rmssd: Double?
    
    /// The lowest heart rate achieved during deep sleep.
    var restingHR: Double
    
    /// Total sleep duration expressed in hours.
    var sleepDuration: Double
    
    /// The athlete's mass in kilograms at the time of the reading.
    var weightKG: Double
    
    /// The internal 0-100 Readiness Score calculated by the ReadinessEngine.
    var readinessScore: Double
    
    /// An optional, highly-weighted external readiness score (e.g., from Athlytic/Bevel).
    var eliteReadiness: Int?
    
    init(date: Date = .now, hrv: Double, restingHR: Double, sleepDuration: Double, weightKG: Double, readinessScore: Double, rmssd: Double? = nil, eliteReadiness: Int? = nil) {
        self.id = UUID()
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
