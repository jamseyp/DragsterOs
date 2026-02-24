import Foundation

struct ReadinessEngine {
    
    /// Calculates a 0.0 - 100.0 score based on recovery telemetry
    /// We removed 'static' so the initialized engine in ContentView can call this directly.
    func calculateScore(hrv: Double, sleepHours: Double, rhr: Double, baselineHRV: Double) -> Double {
        // 1. HRV Ratio (Higher is better)
        // We look for stability. If HRV is within 5% of baseline, it's optimal.
        let hrvFactor = (hrv / baselineHRV)
        let hrvScore = min(max(hrvFactor * 45.0, 0.0), 45.0) // Weighted to 45 points
        
        // 2. Sleep Factor (Target: 8 Hours)
        let sleepFactor = sleepHours / 8.0
        let sleepScore = min(max(sleepFactor * 35.0, 0.0), 35.0) // Weighted to 35 points
        
        // 3. RHR Stress (Lower is better)
        // If RHR is 5+ beats above normal, we penalize the score
        let rhrPenalty = rhr > 60.0 ? Double(rhr - 60.0) * 1.5 : 0.0
        let rhrScore = max(20.0 - rhrPenalty, 0.0) // Weighted to 20 points
        
        let total = hrvScore + sleepScore + rhrScore
        
        // Ensure we never return more than 100% readiness
        return min(total, 100.0)
    }
}
