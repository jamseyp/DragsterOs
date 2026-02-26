import Foundation
import SwiftData

@Model
final class StrategicObjective {
    var eventName: String
    var targetDate: Date
    var targetPower: Int
    var targetPace: String
    var location: String
    
    init(eventName: String = "HALF MARATHON ENGAGEMENT",
         targetDate: Date = Date().addingTimeInterval(86400 * 30),
         targetPower: Int = 250,
         targetPace: String = "4:30 /km",
         location: String = "LONDON") {
        self.eventName = eventName
        self.targetDate = targetDate
        self.targetPower = targetPower
        self.targetPace = targetPace
        self.location = location
    }
}
