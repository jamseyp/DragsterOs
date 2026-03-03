//
//  SessionCategory.swift
//  DragsterOS
//
//  Created by James Parker on 01/03/2026.
//


import Foundation

// MARK: - 🦴 THE SKELETON MODELS
enum SessionCategory: String, CaseIterable, Identifiable, Codable {
    var id: String { self.rawValue }
    
    // Running
    case easyRun = "Easy Base Run"
    case speedRun = "VO2 Max Intervals"
    case thresholdRun = "Threshold Run"
    case longRun = "Long Endurance Run"
    
    // Cross-Training (The Engine Builders)
    case recoverySpin = "Active Recovery Spin"
    case baseRow = "Aerobic Base Row"     // ✨ INJECTED
    case powerRow = "Kinetic Power Row"   // ✨ INJECTED
    
    // Chassis Reinforcement
    case strengthUpper = "Upper Body Strength"
    case strengthLower = "Lower Body Strength"
    case strengthFull = "Full Body Strength"
    
    // Recovery
    case rest = "Complete Rest"
    
    // Maps the user-friendly category back to the Engine's required discipline
    var baseDiscipline: String {
        if self.rawValue.contains("Run") { return "RUN" }
        if self.rawValue.contains("Spin") { return "SPIN" }
        if self.rawValue.contains("Row") { return "ROW" } // ✨ MAPPED
        if self.rawValue.contains("Strength") { return "STRENGTH" }
        return "REST"
    }
}

enum TimeOfDay: String, CaseIterable, Identifiable, Codable {
    var id: String { self.rawValue }
    case am = "AM"
    case pm = "PM"
}

struct BlueprintSlot: Identifiable, Codable, Hashable {
    var id = UUID()
    var category: SessionCategory
    var timeOfDay: TimeOfDay
}
