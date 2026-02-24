//  LogEntry+CoreDataProperties.swift
//  Updated for Architectural Parity

import Foundation
import CoreData

extension LogEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LogEntry> {
        return NSFetchRequest<LogEntry>(entityName: "LogEntry")
    }

    // Existing Vitals
    @NSManaged public var date: Date?
    @NSManaged public var sleep: Double
    @NSManaged public var hrv: Double
    @NSManaged public var restingHR: Double // Added for Telemetry parity
    @NSManaged public var soreness: Double
    @NSManaged public var score: Double

    // Added Performance Telemetry
    @NSManaged public var maxPower: Double   // Watts
    @NSManaged public var avgCadence: Double // SPM
    @NSManaged public var intervalPace: String? // "4:50/km"
}
