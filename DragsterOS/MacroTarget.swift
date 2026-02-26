//
//  MacroTarget.swift
//  DragsterOS
//
//  Created by James Parker on 27/02/2026.
//


import Foundation

// MARK: - 🎯 MACRO TARGET MODEL
struct MacroTarget: Codable {
    var protein: Double
    var carbs: Double
    var fat: Double
    
    // 🧠 Autonomous Calorie Calculation: (P*4) + (C*4) + (F*9)
    var calories: Double {
        return (protein * 4) + (carbs * 4) + (fat * 9)
    }
}

// MARK: - ⚙️ NUTRITION ENGINE (PERSISTENT SETTINGS)
struct NutritionEngine {
    
    // The Factory Defaults
    private static let defaultLow = MacroTarget(protein: 215, carbs: 165, fat: 80)
    private static let defaultMed = MacroTarget(protein: 215, carbs: 265, fat: 80)
    private static let defaultHigh = MacroTarget(protein: 215, carbs: 375, fat: 75)
    private static let defaultRace = MacroTarget(protein: 215, carbs: 450, fat: 75)
    
    /// Retrieves the custom target from memory, or provides the factory default
    static func getTarget(for fuelTier: String?) -> MacroTarget {
        let tier = fuelTier?.uppercased() ?? "LOW"
        let storageKey = "DRAGSTER_FUEL_TIER_\(tier)"
        
        // 1. Check for User-Defined Target
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let savedTarget = try? JSONDecoder().decode(MacroTarget.self, from: data) {
            return savedTarget
        }
        
        // 2. Fallback to Defaults
        if tier.contains("HIGH") || tier.contains("CARB LOAD") { return defaultHigh }
        if tier.contains("MED") { return defaultMed }
        if tier.contains("RACE") { return defaultRace }
        return defaultLow
    }
    
    /// Saves a new custom configuration to the device memory
    static func saveTarget(_ target: MacroTarget, for tier: String) {
        let storageKey = "DRAGSTER_FUEL_TIER_\(tier.uppercased())"
        if let data = try? JSONEncoder().encode(target) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
