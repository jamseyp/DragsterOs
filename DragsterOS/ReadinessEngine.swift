import Foundation
import SwiftData

struct ReadinessEngine {
    
    /// Computes the ultimate 0-100 Readiness Score by fusing Biological, Mechanical, and Thermodynamic data.
    static func computeReadiness(
        todayHRV: Double,
        todayRHR: Double,
        todaySleep: Double,
        yesterdayNetBalance: Double, // ✨ Added Thermodynamic Input
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
        
        // 2. BIOLOGICAL SCORING (60% Weight)
        let hrvRatio = baselineHRV > 0 ? (todayHRV / baselineHRV) : 1.0
        let hrvScore = min(100, max(0, hrvRatio * 100))
        
        let rhrRatio = todayRHR > 0 ? (baselineRHR / todayRHR) : 1.0
        let rhrScore = min(100, max(0, rhrRatio * 100))
        
        let sleepTarget = max(8.0, baselineSleep)
        let sleepRatio = todaySleep / sleepTarget
        let sleepScore = min(100, max(0, sleepRatio * 100))
        
        let biologicalScore = (hrvScore * 0.4) + (rhrScore * 0.4) + (sleepScore * 0.2)
        
        // 3. MECHANICAL SCORING (40% Weight)
        let tsb = loadProfile.tsb
        let mechanicalScore = min(100.0, max(0.0, 100.0 + (tsb * 2.0)))
        
        // 4. THE GRAND FUSION
        var finalScore: Double
        if loadProfile.ctl == 0 && loadProfile.atl == 0 {
            finalScore = biologicalScore
        } else {
            finalScore = (biologicalScore * 0.6) + (mechanicalScore * 0.4)
        }
        
       
        // ✨ Thermodynamic Governor based on CLOSED loop (Yesterday)
                if yesterdayNetBalance < -500 {
                    finalScore *= 0.85
                }
    
        
        return min(100, max(0, finalScore))
    }
    
    /// Evaluates the final readiness score to determine if a CNS Override is required.
    static func requiresOverride(readiness: Double) -> Bool {
        return readiness < 40.0
    }
}
