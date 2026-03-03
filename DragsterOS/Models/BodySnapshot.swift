import Foundation
import SwiftData

/// A macro-level assessment of the athlete's structural geometry and power capabilities.
/// Designed for month-over-month evolutionary tracking.
@Model
final class BodySnapshot {
    @Attribute(.unique) var id: UUID
    
    /// The date the structural baseline was measured.
    var date: Date
    
    /// Total body mass in kilograms.
    var weightKG: Double
    
    /// The maximum instantaneous wattage the athlete can generate.
    var peakPowerWatts: Double
    
    /// Circumference of the left limb in centimeters.
    var leftLegCM: Double
    
    /// Circumference of the right limb in centimeters.
    var rightLegCM: Double
    
    /// The pinnacle metric for running economy and cycling performance (W/kg).
    @Transient var powerToWeightRatio: Double {
        guard weightKG > 0 else { return 0.0 }
        return peakPowerWatts / weightKG
    }
    
    /// Evaluates structural symmetry. Imbalances > 1.0cm heavily correlate with injury risk.
    @Transient var isSymmetrical: Bool {
        return abs(leftLegCM - rightLegCM) <= 1.0
    }
    
    init(date: Date = .now, weightKG: Double, peakPowerWatts: Double, leftLegCM: Double, rightLegCM: Double) {
        self.id = UUID()
        self.date = date
        self.weightKG = weightKG
        self.peakPowerWatts = peakPowerWatts
        self.leftLegCM = leftLegCM
        self.rightLegCM = rightLegCM
    }
}
