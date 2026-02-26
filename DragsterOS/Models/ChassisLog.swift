import Foundation
import SwiftData

@Model
final class ChassisLog {
    var date: Date
    var bodyMass: Double
    var leftThighCirc: Double // cm
    var rightThighCirc: Double // cm
    var maxWattage: Int
    
    var parityIndex: Double {
        let diff = abs(leftThighCirc - rightThighCirc)
        return (1.0 - (diff / max(leftThighCirc, rightThighCirc))) * 100.0
    }
    
    var powerToWeight: Double {
        return Double(maxWattage) / bodyMass
    }
    
    init(date: Date = Date(), bodyMass: Double, leftThigh: Double, rightThigh: Double, maxWatts: Int) {
        self.date = date
        self.bodyMass = bodyMass
        self.leftThighCirc = leftThigh
        self.rightThighCirc = rightThigh
        self.maxWattage = maxWatts
    }
}
