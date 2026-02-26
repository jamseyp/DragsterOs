import Foundation
import SwiftData

struct ReadinessEngine {
    
    /// Computes the ultimate 0-100 Readiness Score by fusing Biological (HRV/RHR/Sleep) and Mechanical (TSB) data.
    static func computeReadiness(
        todayHRV: Double,
        todayRHR: Double,
        todaySleep: Double,
        history: [TelemetryLog],
        loadProfile: LoadEngine.LoadProfile
    ) -> Double {
        
        // 1. BIOLOGICAL BASELINES
        let validHRVs = history.filter { $0.hrv > 0 }.map { $0.hrv }
        let validRHRs = history.filter { $0.restingHR > 0 }.map { $0.restingHR }
        let validSleeps = history.filter { $0.sleepDuration > 0 }.map { $0.sleepDuration }
        
        let baselineHRV = validHRVs.isEmpty ? todayHRV : validHRVs.reduce(0, +) / Double(validHRVs.count)
        let baselineRHR = validRHRs.isEmpty ? todayRHR : validRHRs.reduce(0, +) / Double(validRHRs.count)
        let baselineSleep = validSleeps.isEmpty ? (todaySleep > 0 ? todaySleep : 8.0) : validSleeps.reduce(0, +) / Double(validSleeps.count)
        
        // 2. BIOLOGICAL SCORING (60% Weight of Total)
        // HRV: Higher is better.
        let hrvRatio = baselineHRV > 0 ? (todayHRV / baselineHRV) : 1.0
        let hrvScore = min(100, max(0, hrvRatio * 100))
        
        // RHR: Lower is better. Invert the mathematical ratio.
        let rhrRatio = todayRHR > 0 ? (baselineRHR / todayRHR) : 1.0
        let rhrScore = min(100, max(0, rhrRatio * 100))
        
        // Sleep: Target 8 hours or your baseline, whichever is higher.
        let sleepTarget = max(8.0, baselineSleep)
        let sleepRatio = todaySleep / sleepTarget
        let sleepScore = min(100, max(0, sleepRatio * 100))
        
        let biologicalScore = (hrvScore * 0.4) + (rhrScore * 0.4) + (sleepScore * 0.2)
        
        // 3. MECHANICAL SCORING (40% Weight of Total)
        // TSB (Training Stress Balance) mapped to a 0-100 scale.
        let tsb = loadProfile.tsb
        let mechanicalScore = min(100.0, max(0.0, 100.0 + (tsb * 2.0)))
        
        // 4. THE GRAND FUSION
        // If we have no mechanical load (new user or purged DB), rely 100% on biology.
        if loadProfile.ctl == 0 && loadProfile.atl == 0 {
            return biologicalScore
        }
        
        return (biologicalScore * 0.6) + (mechanicalScore * 0.4)
    }
    
    /// Evaluates the final readiness score to determine if a CNS Override is required.
    /// A score below 40 indicates critical central nervous system fatigue or mechanical overload.
    static func requiresOverride(readiness: Double) -> Bool {
        return readiness < 40.0
    }
}
