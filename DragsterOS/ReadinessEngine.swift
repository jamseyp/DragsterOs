import Foundation

struct ReadinessEngine {
    
    /// Calculates a 0-100 score based on recovery telemetry
    static func calculateScore(hrv: Double, sleepHours: Double, rhr: Double, baselineHRV: Double) -> Double {
        // 1. HRV Ratio (Higher is better)
        // We look for stability. If HRV is within 5% of baseline, it's optimal.
        let hrvFactor = (hrv / baselineHRV)
        let hrvScore = min(max(hrvFactor * 45, 0), 45) // Weighted to 45 points
        
        // 2. Sleep Factor (Target: 8 Hours)
        let sleepFactor = sleepHours / 8.0
        let sleepScore = min(max(sleepFactor * 35, 0), 35) // Weighted to 35 points
        
        // 3. RHR Stress (Lower is better)
        // If RHR is 5+ beats above normal, we penalize the score
        let rhrPenalty = rhr > 60 ? Double(rhr - 60) * 1.5 : 0
        let rhrScore = max(20 - rhrPenalty, 0) // Weighted to 20 points
        
        let total = Double(hrvScore + sleepScore + rhrScore)
        return min(total, 100)
    }
}
