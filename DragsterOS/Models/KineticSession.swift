import Foundation
import SwiftData
import SwiftUI

/// A discrete physical training event.
/// Captures cardiovascular strain, biomechanical efficiency, and mechanical load.
@Model
final class KineticSession {
    /// The immutable cryptographic identifier for the session.
    @Attribute(.unique) var id: UUID
    
    /// The timestamp of the workout execution.
    var date: Date
    
    /// The modality of the training (e.g., "RUN", "SPIN").
    var discipline: String
    
    /// Total duration of active movement.
    var durationMinutes: Double
    
    /// Total distance covered.
    var distanceKM: Double
    
    /// The mean cardiovascular response to the mechanical load.
    var averageHR: Double
    
    /// Rate of Perceived Exertion (1-10 scale).
    var rpe: Int
    
    /// Qualitative feedback and environmental context from the athlete.
    var coachNotes: String
    
    // MARK: - Biomechanics & Telemetry
    
    /// The stride or pedal rate per minute.
    var avgCadence: Double?
    
    /// The absolute mechanical work generated, measured in Watts.
    var avgPower: Double?
    
    /// The specific footwear utilized, critical for tracking structural degradation.
    var shoeName: String?
    
    /// Time spent on the ground per step in milliseconds (Lower is more efficient).
    var groundContactTime: Double?
    
    /// The vertical displacement of the torso in centimeters.
    var verticalOscillation: Double?
    
    /// Total positive elevation change in meters.
    var elevationGain: Double?
    
    // MARK: - Architecture & Linking
    
    /// The foreign key linking this executed session to a planned architectural directive.
    var linkedDirectiveID: UUID?
    
    /// Flags whether this data has been reconciled with hardware inventory.
    var isSyncedToEquipment: Bool = false
    
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
        linkedDirectiveID: UUID? = nil
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
        self.linkedDirectiveID = linkedDirectiveID
    }
    
    // MARK: - 🧠 Physiological Load Calculator
    
    /// Training Stress Score (TSS). A deterministic calculation of systemic strain.
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
