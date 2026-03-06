import Foundation

/// 🧠 A deterministic, side-effect-free service that fuses Autonomic Nervous System (ANS) telemetry
/// with Kinetic Load data (TSB) to compute a high-fidelity systemic readiness score.
struct NeuralReadinessEngine {
    
    /// Computes the ultimate 0-100 Neural Readiness Score tailored for a high-performance athlete.
    /// - Parameters:
    ///   - todayLog: The biological telemetry captured this morning.
    ///   - history: The rolling biological baseline history.
    ///   - loadProfile: The kinetic strain computed by the `KineticLoadEngine`.
    /// - Returns: A readiness score from 0.0 (Severe Neural Fatigue) to 100.0 (Prime State).
    static func computeReadiness(
        todayLog: TelemetryLog,
        history: [TelemetryLog],
        loadProfile: KineticLoadEngine.LoadProfile // Assume LoadEngine will be refactored to KineticLoadEngine next
    ) -> Double {
        
        // ---------------------------------------------------------
        // 1. CLINICAL OVERRIDE
        // ---------------------------------------------------------
        var biologicalScore: Double = 0.0
        
        if let elite = todayLog.eliteReadiness, elite > 0 {
            // Directly prioritize a trusted third-party clinical score (e.g., Athlytic/Bevel) if provided
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
            // 3. SURGICAL NEURAL SCORING
            // ---------------------------------------------------------
            let hrvRatio = baselineMetric > 0 ? (todayRecoveryMetric / baselineMetric) : 1.0
            let hrvScore = hrvRatio >= 1.0 ? 100.0 : max(0.0, 100.0 - ((1.0 - hrvRatio) * 200.0))
            
            let rhrRatio = todayLog.restingHR > 0 ? (baselineRHR / todayLog.restingHR) : 1.0
            let rhrScore = min(100.0, max(0.0, rhrRatio * 100.0))
            
            let sleepTarget = max(8.0, baselineSleep)
            let sleepRatio = todayLog.sleepDuration / sleepTarget
            let sleepScore = min(100.0, max(0.0, sleepRatio * 100.0))
            
            let rawBioScore = (hrvScore * 0.5) + (rhrScore * 0.3) + (sleepScore * 0.2)
            
            // 🛡️ DATA INTEGRITY GUARDRAIL: Cap at 85 if we rely on Apple Health SDNN instead of true RMSSD
            biologicalScore = (todayLog.rmssd != nil) ? rawBioScore : min(85.0, rawBioScore)
        }
        
        // ---------------------------------------------------------
        // 4. KINETIC LOAD SCORING (The "Adaptation Window")
        // ---------------------------------------------------------
        let tsb = loadProfile.tsb
        var kineticScore: Double = 0.0
        
        if tsb >= -15 && tsb <= 15 {
            // Optimal adaptation phase (Productive Stress / Tapered)
            kineticScore = 100.0
        } else if tsb > 15 {
            // Under-training or detraining penalty
            kineticScore = max(0.0, 100.0 - ((tsb - 15.0) * 2.0))
        } else {
            // Over-reaching / Accumulating fatigue penalty
            kineticScore = max(0.0, 100.0 + (tsb * 2.0))
        }
        
        // ---------------------------------------------------------
        // 5. SYSTEMIC FUSION
        // ---------------------------------------------------------
        if loadProfile.ctl == 0 && loadProfile.atl == 0 {
            return biologicalScore // Fallback if no kinetic history exists
        }
        
        // 70% Biological State, 30% Cumulative Kinetic Strain
        return (biologicalScore * 0.7) + (kineticScore * 0.3)
    }
    
    /// Flags severe systemic fatigue requiring an immediate training halt.
    /// Renamed to frame rest as an intentional strategy, soothing ADHD impatience.
    static func requiresStrategicRecovery(readiness: Double) -> Bool {
        return readiness < 40.0
    }
}
