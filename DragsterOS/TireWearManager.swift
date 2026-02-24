import SwiftUI

// 1. THE TIRE COMPOUND STRUCT
struct Tire: Identifiable {
    let id = UUID()
    let name: String
    let compound: String // Soft, Medium, Hard
    let compoundColor: Color
    let currentMileage: Double
    let maxMileage: Double = 500.0 // Standard retirement distance in KM
    
    var wearPercentage: Double {
        return currentMileage / maxMileage
    }
}

// 2. THE GARAGE INVENTORY
class TireWearManager: ObservableObject {
    @Published var activeTires: [Tire]
    
    init() {
        // Pre-loaded with your actual garage inventory
        self.activeTires = [
            Tire(name: "Adidas Boston 12", compound: "SOFT (SPEED)", compoundColor: .red, currentMileage: 120.5),
            Tire(name: "Nike Vomero 17", compound: "MEDIUM (DAILY)", compoundColor: .yellow, currentMileage: 285.0),
            Tire(name: "Mizuno Neo Vista", compound: "HARD (LONG RUN)", compoundColor: .white, currentMileage: 410.2) // Danger zone!
        ]
    }
}
