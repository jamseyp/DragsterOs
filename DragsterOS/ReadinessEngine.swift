import Foundation
import SwiftData

struct ReadinessEngine {
    
    /// Computes the ultimate 0-100 Readiness Score tailored for a high-performance athlete.
    /// Prioritizes Elite HRV (RMSSD) and penalizes generic Apple Health (SDNN) noise.
    static func computeReadiness(
        todayLog: TelemetryLog, // Pass the whole log to access RMSSD and Elite scores
        history: [TelemetryLog],
        loadProfile: LoadEngine.LoadProfile
    ) -> Double {
        
        // ---------------------------------------------------------
        // 1. THE "ELITE" MASTER OVERRIDE
        // ---------------------------------------------------------
        // If the Commander took a controlled Elite HRV reading today, we trust the biological
        // readiness from that app above our own internal math.
        var biologicalScore: Double = 0.0
        
        if let elite = todayLog.eliteReadiness, elite > 0 {
            // Convert 1-10 to 10-100 scale if necessary, assuming it might be stored as 1-10
            biologicalScore = elite <= 10 ? Double(elite * 10) : Double(elite)
        } else {
            
            // ---------------------------------------------------------
            // 2. BIOLOGICAL BASELINES (The "Signal vs Noise" Filter)
            // ---------------------------------------------------------
            // Extract RMSSD first. If unavailable, fallback to HRV (SDNN) but note it's lower fidelity.
            let validRMSSDs = history.compactMap { $0.rmssd }.filter { $0 > 0 }
            
            // We use today's RMSSD if available, otherwise fallback to the generic HRV
            let todayRecoveryMetric = todayLog.rmssd ?? todayLog.hrv
            
            let baselineMetric: Double
            if !validRMSSDs.isEmpty {
                baselineMetric = validRMSSDs.reduce(0, +) / Double(validRMSSDs.count)
            } else {
                let validHRVs = history.filter { $0.hrv > 0 }.map { $0.hrv }
                baselineMetric = validHRVs.isEmpty ? todayRecoveryMetric : validHRVs.reduce(0, +) / Double(validHRVs.count)
            }
            
            let validRHRs = history.filter { $0.restingHR > 0 }.map { $0.restingHR }
            let baselineRHR = validRHRs.isEmpty ? todayLog.restingHR : validRHRs.reduce(0, +) / Double(validRHRs.count)
            
            let validSleeps = history.filter { $0.sleepDuration > 0 }.map { $0.sleepDuration }
            let baselineSleep = validSleeps.isEmpty ? (todayLog.sleepDuration > 0 ? todayLog.sleepDuration : 8.0) : validSleeps.reduce(0, +) / Double(validSleeps.count)
            
            // ---------------------------------------------------------
            // 3. SURGICAL BIOLOGICAL SCORING
            // ---------------------------------------------------------
            
            // HRV/RMSSD Penalty Curve: Drops below baseline are severely penalized.
            let hrvRatio = baselineMetric > 0 ? (todayRecoveryMetric / baselineMetric) : 1.0
            // If ratio is 0.8 (20% drop), math becomes: 100 - ((1.0 - 0.8) * 200) = 60/100
            let hrvScore = hrvRatio >= 1.0 ? 100.0 : max(0.0, 100.0 - ((1.0 - hrvRatio) * 200.0))
            
            // RHR: Invert ratio. Higher RHR means engine is running hot.
            let rhrRatio = todayLog.restingHR > 0 ? (baselineRHR / todayLog.restingHR) : 1.0
            let rhrScore = min(100.0, max(0.0, rhrRatio * 100.0))
            
            // Sleep
            let sleepTarget = max(8.0, baselineSleep)
            let sleepRatio = todayLog.sleepDuration / sleepTarget
            let sleepScore = min(100.0, max(0.0, sleepRatio * 100.0))
            
            // Apply Noise Penalty: If we are forced to use Apple Health SDNN, cap the bio score at 85
            // to prevent false "Peak" readings from background noise.
            let rawBioScore = (hrvScore * 0.5) + (rhrScore * 0.3) + (sleepScore * 0.2)
            biologicalScore = (todayLog.rmssd != nil) ? rawBioScore : min(85.0, rawBioScore)
        }
        
        // ---------------------------------------------------------
        // 4. MECHANICAL SCORING (The "Taper Window")
        // ---------------------------------------------------------
        let tsb = loadProfile.tsb
        var mechanicalScore: Double = 0.0
        
        if tsb >= -15 && tsb <= 15 {
            // Race Ready / Taper Sweet Spot
            mechanicalScore = 100.0
        } else if tsb > 15 {
            // Detraining (Losing fitness)
            mechanicalScore = max(0.0, 100.0 - ((tsb - 15.0) * 2.0))
        } else {
            // Heavy Fatigue / Overreaching (TSB < -15)
            mechanicalScore = max(0.0, 100.0 + (tsb * 2.0)) // tsb is negative here
        }
        
        // ---------------------------------------------------------
        // 5. THE GRAND FUSION
        // ---------------------------------------------------------
        if loadProfile.ctl == 0 && loadProfile.atl == 0 {
            return biologicalScore
        }
        
        // Elite Biological data heavily dictates readiness. Mechanical is context.
        return (biologicalScore * 0.7) + (mechanicalScore * 0.3)
    }
    
    /// Evaluates the final readiness score to determine if a CNS Override is required.
    static func requiresOverride(readiness: Double) -> Bool {
        return readiness < 40.0
    }
}
