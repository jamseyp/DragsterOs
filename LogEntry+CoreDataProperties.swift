//
//  LogEntry+CoreDataProperties.swift
//  DragsterOS
//
//  Created by James Parker on 23/02/2026.
//
//

import Foundation
import CoreData


extension LogEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LogEntry> {
        return NSFetchRequest<LogEntry>(entityName: "LogEntry")
    }

    @NSManaged public var date: Date?
    @NSManaged public var sleep: Double
    @NSManaged public var hrv: Double
    @NSManaged public var soreness: Double
    @NSManaged public var score: Double

}

extension LogEntry : Identifiable {

}
