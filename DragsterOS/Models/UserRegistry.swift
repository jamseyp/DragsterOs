import Foundation
import SwiftData

// MARK: - 🫀 SYSTEM CALIBRATION REGISTRY
@Model
final class UserRegistry {
    @Attribute(.unique) var id: String = "SINGLETON"
    
    // 🫀 CORE BIOMETRICS
    var targetWeight: Double
    var restingHR: Int
    var maxHR: Int
    var vo2Max: Double // Replaced Lactate Threshold
    
    // ⚡️ POWER / PERFORMANCE
    var functionalThresholdPower: Int
    var targetRacePaceSeconds: Int
    
    // 🧪 HR ZONES
    var zone1Max: Int
    var zone2Max: Int
    var zone3Max: Int
    var zone4Max: Int
    
    // ⚖️ THERMODYNAMICS
    var manualTDEE: Int
    var isTDEEOverridden: Bool
    
    // 🧠 COMPUTED TDEE
    // Dynamically calculates baseline energy needs unless explicitly overridden
    var effectiveTDEE: Int {
        if isTDEEOverridden { return manualTDEE }
        // Standard baseline for an active endurance athlete: ~35 kcal per kg
        return Int(targetWeight * 35.0)
    }
    
    init(
        targetWeight: Double = 75.0,
        restingHR: Int = 50,
        maxHR: Int = 190,
        vo2Max: Double = 50.0,
        ftp: Int = 250,
        targetRacePaceSeconds: Int = 300,
        z1: Int = 130,
        z2: Int = 145,
        z3: Int = 160,
        z4: Int = 175,
        manualTDEE: Int = 2600,
        isTDEEOverridden: Bool = false
    ) {
        self.targetWeight = targetWeight
        self.restingHR = restingHR
        self.maxHR = maxHR
        self.vo2Max = vo2Max
        self.functionalThresholdPower = ftp
        self.targetRacePaceSeconds = targetRacePaceSeconds
        self.zone1Max = z1
        self.zone2Max = z2
        self.zone3Max = z3
        self.zone4Max = z4
        self.manualTDEE = manualTDEE
        self.isTDEEOverridden = isTDEEOverridden
    }
}
