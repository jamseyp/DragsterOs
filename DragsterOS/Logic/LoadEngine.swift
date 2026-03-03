import Foundation
//
// 
/// A deterministic service that calculates the Exponentially Weighted Moving Average (EWMA)
/// of an athlete's training stress to model cumulative fitness and fatigue.
struct LoadEngine {
    
    /// The physical state of the chassis at a specific point in time.
    struct LoadProfile {
        /// Chronic Training Load (Fitness). A 42-day rolling average of daily TSS.
        let ctl: Double
        /// Acute Training Load (Fatigue). A 7-day rolling average of daily TSS.
        let atl: Double
        /// Training Stress Balance (Form). A positive number indicates the athlete is primed/tapered.
        var tsb: Double { ctl - atl }
    }
    
    /// Computes the physical load profile up to a specific date.
    /// - Parameters:
    ///   - history: The raw array of completed kinetic sessions.
    ///   - targetDate: The date to calculate the load for (defaults to today in the UI, but can be a future date for forecasting).
    /// - Returns: A `LoadProfile` representing Fitness, Fatigue, and Form.
    static func computeLoad(history: [KineticSession], upTo targetDate: Date) -> LoadProfile {
        guard !history.isEmpty else { return LoadProfile(ctl: 0, atl: 0) }
        
        let calendar = Calendar.current
        
        // 1. Group sessions by Day (O(N) operation) for lightning-fast lookups
        let groupedSessions = Dictionary(grouping: history) { session in
            calendar.startOfDay(for: session.date)
        }
        
        // 2. Determine our timeline
        let sortedDates = groupedSessions.keys.sorted()
        guard let startDate = sortedDates.first else { return LoadProfile(ctl: 0, atl: 0) }
        let endDate = calendar.startOfDay(for: targetDate)
        
        let daysPassed = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        guard daysPassed >= 0 else { return LoadProfile(ctl: 0, atl: 0) } // Prevent negative time travel
        
        var currentCTL = 0.0
        var currentATL = 0.0
        
        // 3. The EWMA Calculation Loop
        for dayOffset in 0...daysPassed {
            guard let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            
            // O(1) dictionary lookup instead of O(N) array filtering. Massive performance gain.
            let dailySessions = groupedSessions[currentDate] ?? []
            let dailyTSS = dailySessions.reduce(0.0) { $0 + $1.trainingStressScore }
            
            // Apply the EWMA mathematical decay
            currentCTL = currentCTL + (dailyTSS - currentCTL) * (1.0 / 42.0)
            currentATL = currentATL + (dailyTSS - currentATL) * (1.0 / 7.0)
        }
        
        return LoadProfile(ctl: currentCTL, atl: currentATL)
    }
}
