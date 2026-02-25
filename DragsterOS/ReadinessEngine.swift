import Foundation
import SwiftData

// 📐 ARCHITECTURE: The proprietary algorithm for Dragster OS.
// This calculates the daily Readiness Score (0-100) by analyzing
// raw HealthKit telemetry against the athlete's rolling physiological baseline.

struct ReadinessEngine {
    
    /// Computes the 0-100 Readiness Score
    /// - Parameters:
    ///   - todayHRV: Today's Heart Rate Variability in ms
    ///   - todaySleep: Last night's sleep duration in hours
    ///   - history: The historical database of TelemetryLogs to establish a baseline
    /// - Returns: A beautifully calculated double between 1.0 and 100.0
    static func computeReadiness(todayHRV: Double, todaySleep: Double, history: [TelemetryLog]) -> Double {
        
        // ✨ THE POLISH: We divide the score into two weighted pillars.
        // 1. Nervous System Recovery (HRV) - 65% weight
        // 2. Physical Restitution (Sleep) - 35% weight
        // HRV is the ultimate source of truth for central nervous system fatigue.
        
        let hrvWeight = 0.65
        let sleepWeight = 0.35
        
        // --- 1. NERVOUS SYSTEM ANALYSIS (HRV) ---
        let baselineHRV = calculateBaselineHRV(history: history)
        let hrvScore: Double
        
        if baselineHRV < 10.0 {
            // Day 1 Heuristic: If we lack historical data, we use a generalized fallback.
            // 50ms is a healthy generic average to assume a baseline of 75/100.
            hrvScore = todayHRV > 45.0 ? 80.0 : 50.0
        } else {
            // The core algorithm: Ratio of today vs. the 14-day rolling average.
            let hrvRatio = todayHRV / baselineHRV
            
            // If HRV is 1.2x your baseline, you are peaking (100).
            // If it drops to 0.6x, your nervous system is depleted.
            // We use a linear map clamped between 10 and 100.
            let rawHRVScore = (hrvRatio * 100.0) - 10.0
            hrvScore = min(max(rawHRVScore, 10.0), 100.0)
        }
        
        // --- 2. PHYSICAL RESTITUTION (SLEEP) ---
        // Target is mathematically fixed at 8.0 hours for elite recovery.
        let optimalSleep = 8.0
        let sleepRatio = todaySleep / optimalSleep
        let sleepScore = min(sleepRatio * 100.0, 100.0)
        
        // --- 3. THE SYNTHESIS ---
        let finalScore = (hrvScore * hrvWeight) + (sleepScore * sleepWeight)
        
        return min(max(finalScore, 1.0), 100.0) // Clamp safely between 1 and 100
    }
    
    // 🧠 Calculates a 14-day rolling average to establish the athlete's unique baseline
    private static func calculateBaselineHRV(history: [TelemetryLog]) -> Double {
        guard !history.isEmpty else { return 0.0 }
        
        // Filter out zero-values to prevent mathematically skewing the baseline downward
        let validLogs = history.filter { $0.hrv > 0.0 }
        guard !validLogs.isEmpty else { return 0.0 }
        
        // We look at the most recent 14 days of valid data
        let recentLogs = validLogs.prefix(14)
        let totalHRV = recentLogs.reduce(0.0) { $0 + $1.hrv }
        
        return totalHRV / Double(recentLogs.count)
    }
}
