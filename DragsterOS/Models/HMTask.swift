import Foundation
import SwiftUI

/// 📐 ARCHITECTURAL REASONING:
/// We are using a 'CurrentSession' struct to bridge the gap between
/// your CSV data and the Dashboard. Tomorrow, this will become an @Observable class.
struct HMTask: Identifiable {
    let id = UUID()
    let date: Date
    let activity: String
    let intensity: String
    let coachNote: String
    let fuelTier: String
    var isMorphed: Bool = false
    var suggestedActivity: String? = nil
}

class HMPlanManager: ObservableObject {
    @Published var todaysTask: HMTask?
    
    // This logic lives here today so it's a "plug-and-play" tomorrow
    func evaluateReadiness(score: Int, originalTask: HMTask) {
        // If readiness is low (< 50) and it's a high-intensity session
        if score < 50 && (originalTask.intensity.contains("300W") || originalTask.intensity.contains("Intervals")) {
            var adjustedTask = originalTask
            adjustedTask.isMorphed = true
            adjustedTask.suggestedActivity = "Zone 1 Recovery Flush (30 mins)"
            self.todaysTask = adjustedTask
        } else {
            self.todaysTask = originalTask
        }
    }
}
