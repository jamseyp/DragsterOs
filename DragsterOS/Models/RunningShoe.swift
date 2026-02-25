import Foundation
import SwiftData

// 📐 ARCHITECTURE: The structural tracking model for footwear.
// This allows us to monitor the exact degradation of foam and carbon plates.

@Model
final class RunningShoe {
    @Attribute(.unique) var id: UUID
    var name: String
    var terrainType: String // e.g., "Road", "Trail"
    var purpose: String // e.g., "Speed", "Recovery", "Race"
    
    // The degradation metrics
    var currentMileage: Double
    var maxLifespan: Double
    var isActive: Bool
    
    // Calculated property to determine the structural integrity (0.0 to 1.0)
    @Transient var integrityRatio: Double {
        return min(max(currentMileage / maxLifespan, 0.0), 1.0)
    }
    
    init(
        name: String,
        terrainType: String,
        purpose: String,
        currentMileage: Double = 0.0,
        maxLifespan: Double = 500.0, // Standard 500km threshold
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.terrainType = terrainType
        self.purpose = purpose
        self.currentMileage = currentMileage
        self.maxLifespan = maxLifespan
        self.isActive = isActive
    }
}
