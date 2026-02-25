import Foundation
import SwiftData
import SwiftUI

// MARK: - 📐 KINETIC SESSION MODEL
/// The master record for a completed physical mission.
/// This model captures the intersection of kinetic work (Power/Pace)
/// and biological cost (Heart Rate/RPE).
@Model
final class KineticSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var discipline: String // e.g., "RUN", "ROW", "SPIN", "STRENGTH"
    var durationMinutes: Double
    var distanceKM: Double
    var averageHR: Double
    var rpe: Int
    var coachNotes: String
    
    // ✨ HIGH-RESOLUTION TELEMETRY
    var avgCadence: Double?
    var avgPower: Double?
    var shoeName: String?
    
    // MARK: - 🎨 UI COMPUTED PROPERTIES
    
    /// Assigns a specific neon accent color based on the discipline.
    @Transient var disciplineColor: Color {
        switch discipline {
        case "RUN": return .cyan
        case "ROW": return .blue
        case "SPIN": return .yellow
        case "STRENGTH": return .purple
        default: return .gray
        }
    }
    
    /// Maps the discipline to the appropriate SF Symbol.
    @Transient var disciplineIcon: String {
        switch discipline {
        case "RUN": return "figure.run"
        case "ROW": return "figure.rower"
        case "SPIN": return "figure.indoor.cycle"
        case "STRENGTH": return "dumbbell.fill"
        default: return "bolt.fill"
        }
    }
    
    // MARK: - 🛠️ INITIALIZER
    init(
        date: Date = .now,
        discipline: String,
        durationMinutes: Double,
        distanceKM: Double,
        averageHR: Double,
        rpe: Int,
        coachNotes: String = "",
        avgCadence: Double? = nil,
        avgPower: Double? = nil,
        shoeName: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.discipline = discipline
        self.durationMinutes = durationMinutes
        self.distanceKM = distanceKM
        self.averageHR = averageHR
        self.rpe = rpe
        self.coachNotes = coachNotes
        self.avgCadence = avgCadence
        self.avgPower = avgPower
        self.shoeName = shoeName
    }
}

// MARK: - 🤖 AI COACH TRANSLATION
/// Extension to handle the high-density data export for LLM analysis.
extension KineticSession {
    
    /// Generates a structured Markdown excerpt designed for Gemini/GPT coaching analysis.
    func generateFullTacticalExcerpt(readiness: Int?) -> String {
        let pace = durationMinutes / (distanceKM > 0 ? distanceKM : 1.0)
        let mins = Int(pace)
        let secs = Int((pace - Double(mins)) * 60)
        let paceString = distanceKM > 0 ? String(format: "%d:%02d/km", mins, secs) : "N/A"
        
        return """
        🏎️ DRAGSTER OS: FULL SPECTRUM DEBRIEF
        ---
        SESSION: \(discipline) | \(date.formatted(date: .abbreviated, time: .shortened))
        
        [BIOLOGICAL CONTEXT]
        - MORNING READINESS: \(readiness != nil ? "\(readiness!)/100" : "DATA UNMAPPED")
        - SUBJECTIVE RPE: \(rpe)/10
        
        [KINETIC TELEMETRY]
        - DISTANCE: \(String(format: "%.2f", distanceKM)) KM
        - DURATION: \(Int(durationMinutes)) MIN
        - AVG PACE: \(paceString)
        - AVG POWER: \(avgPower != nil ? "\(Int(avgPower!))W" : "N/A")
        - AVG CADENCE: \(avgCadence != nil ? "\(Int(avgCadence!)) SPM" : "N/A")
        
        [STRUCTURAL LOAD]
        - CHASSIS (SHOES): \(shoeName ?? "Not Specified")
        - HEART RATE: \(Int(averageHR)) BPM
        
        [ATHLETE NOTES]
        "\(coachNotes.isEmpty ? "None." : coachNotes)"
        
        ---
        INSTRUCTION TO AI COACH: Review this \(discipline) data against my morning readiness. Analyze if I over-reached given my recovery state. Evaluate my mechanical efficiency (Power/HR ratio) and check if these shoes are still providing optimal energy return for this pace.
        """
    }
}
