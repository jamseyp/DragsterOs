import Foundation
import SwiftData

struct LoadEngine {
    
    struct LoadProfile {
        let ctl: Double // Chronic Training Load (Fitness - 42 Days)
        let atl: Double // Acute Training Load (Fatigue - 7 Days)
        var tsb: Double { ctl - atl } // Training Stress Balance (Form)
    }
    
    /// Scans the database and computes the current physical load profile
    static func computeCurrentLoad(history: [KineticSession]) -> LoadProfile {
        // Sort chronologically from oldest to newest
        let sortedSessions = history.sorted { $0.date < $1.date }
        guard let firstSession = sortedSessions.first else {
            return LoadProfile(ctl: 0, atl: 0)
        }
        
        var currentCTL = 0.0
        var currentATL = 0.0
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: firstSession.date)
        let today = calendar.startOfDay(for: .now)
        
        let daysPassed = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        
        // Loop through every day from the first workout to today
        for dayOffset in 0...daysPassed {
            let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate)!
            
            // Find all sessions on this specific day and sum their TSS
            let dailySessions = sortedSessions.filter { calendar.isDate($0.date, inSameDayAs: currentDate) }
            let dailyTSS = dailySessions.reduce(0.0) { $0 + $1.trainingStressScore }
            
            // Apply the EWMA mathematical decay
            currentCTL = currentCTL + (dailyTSS - currentCTL) * (1.0 / 42.0)
            currentATL = currentATL + (dailyTSS - currentATL) * (1.0 / 7.0)
        }
        
        return LoadProfile(ctl: currentCTL, atl: currentATL)
    }
}
