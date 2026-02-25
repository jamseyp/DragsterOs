import Foundation
import UserNotifications
import SwiftData

// 📐 ARCHITECTURE: A highly efficient, thread-safe background manager.
// It actively monitors SwiftData metrics and schedules precision lock-screen alerts.

@Observable
final class SystemAlertManager {
    static let shared = SystemAlertManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    var isAuthorized: Bool = false
    
    private init() {}
    
    // MARK: - 🔐 System Permissions
    
    /// Requests access to the iOS notification canvas
    func requestAuthorization() async {
        do {
            // We request badges, sounds, and standard alerts for a premium feel
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }
        } catch {
            print("System Alert Fault: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 🧬 Physiological Monitoring
    
    /// Evaluates the daily Readiness Score and triggers alerts for severe central nervous system fatigue.
    func evaluatePhysiologicalLoad(currentReadiness: Double) {
        guard isAuthorized else { return }
        
        // ✨ THE ALGORITHM: We only alert on critical data deviations.
        // If readiness drops below 35, the athlete is structurally compromised.
        if currentReadiness < 35.0 {
            schedulePush(
                identifier: "critical_fatigue_alert",
                title: "SYSTEM FAULT: HIGH FATIGUE",
                body: "Readiness has dropped to \(Int(currentReadiness))/100. Central nervous system is depleted. Override today's mission and prioritize immediate recovery.",
                sound: .defaultCritical // A sharp, immediate system sound
            )
        }
    }
    
    // MARK: - 👟 Equipment Degradation
    
    /// Scans the active footwear database for structural breakdown.
    func evaluateEquipmentIntegrity(activeShoes: [RunningShoe]) {
        guard isAuthorized else { return }
        
        for shoe in activeShoes {
            // If the EVA foam/carbon plate is operating past 90% of its safe lifespan
            if shoe.integrityRatio > 0.90 {
                schedulePush(
                    identifier: "equipment_wear_\(shoe.id.uuidString)",
                    title: "EQUIPMENT WARNING: \(shoe.name.uppercased())",
                    body: "Structural integrity compromised (\(Int(shoe.currentMileage))km logged). Biomechanical risk elevated. Consider immediate replacement.",
                    sound: .default
                )
            }
        }
    }
    
    // MARK: - ⚙️ Core Scheduling Engine
    
    private func schedulePush(identifier: String, title: String, body: String, sound: UNNotificationSound) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        
        // We use a TimeIntervalNotificationTrigger to fire the alert shortly after the background data is crunched.
        // 5 seconds gives the app time to close or background cleanly before the push arrives.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to dispatch alert: \(error.localizedDescription)")
            }
        }
    }
}
