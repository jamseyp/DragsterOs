import Foundation
import SwiftData
import SwiftUI

// MARK: - 📐 KINETIC SESSION MODEL
@Model
final class KineticSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var discipline: String
    var durationMinutes: Double
    var distanceKM: Double
    var averageHR: Double
    var rpe: Int
    var coachNotes: String
    
    // TELEMETRY
    var avgCadence: Double?
    var avgPower: Double?
    var shoeName: String?
    
    // ADVANCED BIOMECHANICS
    var groundContactTime: Double?
    var verticalOscillation: Double?
    var elevationGain: Double?
    
    // ✨ THE MISSING LINK TO THE TRAINING PLAN
    var linkedDirectiveID: UUID?
    
    // Add this to your KineticSession class properties
    var isSyncedToEquipment: Bool = false
    
    // MARK: - 🎨 UI COMPUTED PROPERTIES
    @Transient var disciplineColor: Color {
        switch discipline {
        case "RUN": return .cyan
        case "ROW": return .blue
        case "SPIN": return .yellow
        case "STRENGTH": return .purple
        default: return .gray
        }
    }
    
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
        shoeName: String? = nil,
        groundContactTime: Double? = nil,
        verticalOscillation: Double? = nil,
        elevationGain: Double? = nil,
        linkedDirectiveID: UUID? = nil // ✨ NOW THE COMPILER KNOWS IT EXISTS
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
        self.groundContactTime = groundContactTime
        self.verticalOscillation = verticalOscillation
        self.elevationGain = elevationGain
        self.linkedDirectiveID = linkedDirectiveID // ✨ SAVED TO DATABASE
    }
    
    // MARK: - 🧠 MECHANICAL LOAD CALCULATOR (TSS)
    @Transient
    var trainingStressScore: Double {
        let assumedFTP = 250.0
        if let power = avgPower, discipline == "SPIN" {
            let durationSecs = durationMinutes * 60.0
            let intensityFactor = power / assumedFTP
            return (durationSecs * power * intensityFactor) / (assumedFTP * 3600.0) * 100.0
        } else {
            let rpeFactor = pow(Double(rpe) / 10.0, 2)
            return rpeFactor * durationMinutes * (100.0 / 60.0)
        }
    }
}

// MARK: - 🤖 AI COACH TRANSLATION
extension KineticSession {
    // ✨ FIXED THE "PLAN" SCOPE ERROR: Now explicitly uses 'mission'
    func generateFullTacticalExcerpt(readiness: Int?, mission: OperationalDirective?) -> String {
        let pace = durationMinutes / (distanceKM > 0 ? distanceKM : 1.0)
        let mins = Int(pace)
        let secs = Int((pace - Double(mins)) * 60)
        let paceString = distanceKM > 0 ? String(format: "%d:%02d/km", mins, secs) : "N/A"
        
        let missionTitle = mission?.missionTitle ?? "FREE RUN (NO DIRECTIVE)"
        let missionGoal = mission?.missionNotes
        let ef = (avgPower != nil && averageHR > 0) ? String(format: "%.2f", avgPower! / averageHR) : "N/A"
        
        return """
        🏎️ DRAGSTER OS: FULL SPECTRUM DEBRIEF
        ---
        SESSION: \(discipline) | \(date.formatted(date: .abbreviated, time: .shortened))
        
        [TACTICAL COMPLIANCE]
        - ASSIGNED MISSION: \(missionTitle)
        - STATED GOAL: \(missionGoal)
        
        [BIOLOGICAL CONTEXT]
        - MORNING READINESS: \(readiness != nil ? "\(readiness!)/100" : "DATA UNMAPPED")
        - SUBJECTIVE RPE: \(rpe)/10
        
        [KINETIC TELEMETRY]
        - DISTANCE: \(String(format: "%.2f", distanceKM)) KM
        - DURATION: \(Int(durationMinutes)) MIN
        - AVG PACE: \(paceString)
        - AVG POWER: \(avgPower != nil ? "\(Int(avgPower!))W" : "N/A")
        - AVG CADENCE: \(avgCadence != nil ? "\(Int(avgCadence!)) SPM" : "N/A")
        
        [ADVANCED BIOMECHANICS]
        - GCT: \(groundContactTime != nil ? "\(Int(groundContactTime!)) ms" : "N/A")
        - OSCILLATION: \(verticalOscillation != nil ? String(format: "%.1f cm", verticalOscillation!) : "N/A")
        - ELEVATION GAIN: \(elevationGain != nil ? "\(Int(elevationGain!)) m" : "N/A")
        
        [STRUCTURAL LOAD]
        - AVG HEART RATE: \(Int(averageHR)) BPM
        - BIO-KINETIC RATIO (EF): \(ef) W/bpm
        
        [ATHLETE NOTES]
        "\(coachNotes.isEmpty ? "None." : coachNotes)"
        
        ---
        INSTRUCTION TO AI COACH: 
        Perform a Bio-Kinetic Diagnostic for the current training phase (10k/HM).
        1. DIRECTIVE COMPLIANCE: Compare this session against the [TACTICAL COMPLIANCE] block. Did the athlete execute the prescribed intensity, or was there "Executive Over-reach"?
        2. ENGINE EFFICIENCY: Analyze the Efficiency Factor (EF: Power/HR). Is the cardiovascular engine becoming more economical at this specific intensity?
        3. MECHANICAL DURABILITY: Evaluate GCT and Oscillation. Identify any "wattage leaks" or structural breakdown indicative of fatigue for a 95kg chassis.
        """
    }
}
