import Foundation

/// A deterministic service that fuses Central Nervous System (CNS) telemetry
/// with mechanical fatigue data (TSB) to compute a high-fidelity readiness score.
struct ReadinessEngine {
    
    /// Computes the ultimate 0-100 Readiness Score tailored for a high-performance athlete.
    /// - Parameters:
    ///   - todayLog: The telemetry captured this morning.
    ///   - history: The biological baseline history.
    ///   - loadProfile: The mechanical strain computed by the `LoadEngine`.
    /// - Returns: A readiness score from 0.0 (Severe Fatigue) to 100.0 (Prime).
    static func computeReadiness(
        todayLog: TelemetryLog,
        history: [TelemetryLog],
        loadProfile: LoadEngine.LoadProfile
    ) -> Double {
        
        // ---------------------------------------------------------
        // 1. THE "ELITE" MASTER OVERRIDE
        // ---------------------------------------------------------
        var biologicalScore: Double = 0.0
        
        if let elite = todayLog.eliteReadiness, elite > 0 {
            biologicalScore = elite <= 10 ? Double(elite * 10) : Double(elite)
        } else {
            
            // ---------------------------------------------------------
            // 2. BIOLOGICAL BASELINES (Signal vs Noise Filter)
            // ---------------------------------------------------------
            let validRMSSDs = history.compactMap { $0.rmssd }.filter { $0 > 0 }
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
            let hrvRatio = baselineMetric > 0 ? (todayRecoveryMetric / baselineMetric) : 1.0
            let hrvScore = hrvRatio >= 1.0 ? 100.0 : max(0.0, 100.0 - ((1.0 - hrvRatio) * 200.0))
            
            let rhrRatio = todayLog.restingHR > 0 ? (baselineRHR / todayLog.restingHR) : 1.0
            let rhrScore = min(100.0, max(0.0, rhrRatio * 100.0))
            
            let sleepTarget = max(8.0, baselineSleep)
            let sleepRatio = todayLog.sleepDuration / sleepTarget
            let sleepScore = min(100.0, max(0.0, sleepRatio * 100.0))
            
            let rawBioScore = (hrvScore * 0.5) + (rhrScore * 0.3) + (sleepScore * 0.2)
            
            // Apple Health SDNN penalty: Cap at 85 if we lack true RMSSD
            biologicalScore = (todayLog.rmssd != nil) ? rawBioScore : min(85.0, rawBioScore)
        }
        
        // ---------------------------------------------------------
        // 4. MECHANICAL SCORING (The "Taper Window")
        // ---------------------------------------------------------
        let tsb = loadProfile.tsb
        var mechanicalScore: Double = 0.0
        
        if tsb >= -15 && tsb <= 15 {
            mechanicalScore = 100.0
        } else if tsb > 15 {
            mechanicalScore = max(0.0, 100.0 - ((tsb - 15.0) * 2.0))
        } else {
            mechanicalScore = max(0.0, 100.0 + (tsb * 2.0))
        }
        
        // ---------------------------------------------------------
        // 5. THE GRAND FUSION
        // ---------------------------------------------------------
        if loadProfile.ctl == 0 && loadProfile.atl == 0 {
            return biologicalScore
        }
        
        return (biologicalScore * 0.7) + (mechanicalScore * 0.3)
    }
    
    /// Flags severe systemic fatigue requiring an immediate training halt.
    static func requiresOverride(readiness: Double) -> Bool {
        return readiness < 40.0
    }
}
