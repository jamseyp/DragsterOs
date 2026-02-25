import Foundation
import SwiftData

// 📐 ARCHITECTURE: A macro-level snapshot of the athlete's structural and kinetic evolution.
// Kept separate from daily logs to efficiently track month-over-month progress.

@Model
final class ChassisSnapshot {
    @Attribute(.unique) var id: UUID
    var date: Date
    var weightKG: Double
    var peakPowerWatts: Double
    var leftLegCM: Double
    var rightLegCM: Double
    
    // ✨ THE POLISH: A computed transient property for the ultimate efficiency metric
    @Transient var powerToWeightRatio: Double {
        guard weightKG > 0 else { return 0.0 }
        return peakPowerWatts / weightKG
    }
    
    // Computed property to determine if symmetry is optimal (within 1cm)
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
