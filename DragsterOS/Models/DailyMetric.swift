//
//  DailyMetric.swift
//  DragsterOS
//
//  Created by James Parker on 25/02/2026.
//

import SwiftData
import Foundation

@Model
class DailyMetric {
    var date: Date
    var weight: Double
    var hrvScore: Double
    var protienGrams: Double
    var powerOutput: Double? //optional for interval days
    
    init(date: Date, weight: Double, hrvScore: Double, protienGrams: Double, powerOutput: Double? = nil) {
        self.date = date
        self.weight = weight
        self.hrvScore = hrvScore
        self.protienGrams = protienGrams
        self.powerOutput = powerOutput
    }
}
