import Foundation
import SwiftData

// MARK: - 📐 STRUCTURAL TRACKING MODEL
/// Monitors the exact degradation of foam and carbon plates over time.
@Model
final class RunningShoe {
    @Attribute(.unique) var id: UUID
    var brand: String
    var model: String
    var terrainType: String
    var purpose: String
    
    // DEGRADATION METRICS
    var currentMileage: Double
    var maxLifespan: Double
    var isActive: Bool
    
    // MARK: - 🧠 ALIASES FOR SYSTEM HARMONY
    // These properties ensure SystemAlertManager and TireWearView both work.

    /// Alias for SystemAlertManager: Returns 0.0 (new) to 1.0 (worn out)
    @Transient var integrityRatio: Double {
        return min(max(currentMileage / maxLifespan, 0.0), 1.0)
    }

    /// Alias for SystemAlertManager: Returns the combined name
    @Transient var name: String {
        return "\(brand) \(model)"
    }

    /// Returns the percentage of lifespan remaining (1.0 = New, 0.0 = Dead)
    @Transient var structuralIntegrity: Double {
        let ratio = 1.0 - (currentMileage / maxLifespan)
        return min(max(ratio, 0.0), 1.0)
    }
    
    // MARK: - 🛠️ INITIALIZER
    init(
        brand: String,
        model: String,
        terrainType: String = "Road",
        purpose: String = "Daily",
        currentMileage: Double = 0.0,
        maxLifespan: Double = 500.0,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.brand = brand
        self.model = model
        self.terrainType = terrainType
        self.purpose = purpose
        self.currentMileage = currentMileage
        self.maxLifespan = maxLifespan
        self.isActive = isActive
    }
}
