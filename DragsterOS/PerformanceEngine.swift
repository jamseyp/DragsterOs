import Foundation

/// 📐 ARCHITECTURAL REASONING:
/// This logic is separated into a 'PerformanceEngine' so that the UI
/// never has to do math. It simply observes the result.
struct PerformanceEngine {
    
    /// Calculates the Power-to-Weight ratio.
    /// - Parameters:
    ///   - power: Current session target or actual watts.
    ///   - weight: Morning weight in KG.
    /// - Returns: W/kg rounded to two decimal places.
    static func calculatePowerToWeight(power: Double, weight: Double) -> Double {
            guard weight > 0 else { return 0.0 }
            return (power / weight * 100).rounded() / 100
        }
    
    /// Returns a performance tier based on the ratio.
    static func efficiencyTier(ratio: Double) -> String {
        switch ratio {
        case ..<2.5: return "BASE"
        case 2.5..<3.5: return "DEVELOPING"
        case 3.5..<4.5: return "ELITE"
        default: return "PRO"
        }
    }
}
