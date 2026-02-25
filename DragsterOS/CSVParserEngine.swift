import Foundation
import SwiftData

// MARK: - 📐 CSV INGESTION ENGINE (DIAGNOSTIC MODE)
struct CSVParserEngine {
    
    static func generateMacroCycle() -> [PlannedMission] {
        // 1. CHECK IF FILE EXISTS
        guard let filepath = Bundle.main.path(forResource: "hmPlan", ofType: "csv") else {
            print("🚨 FATAL ERROR: 'hmPlan.csv' was not found in the App Bundle!")
            print("👉 FIX: Click hmPlan.csv in Xcode's left sidebar. Look at the right sidebar (File Inspector). Make sure the checkbox under 'Target Membership' for DragsterOS is CHECKED.")
            return []
        }
        
        var macroCycle: [PlannedMission] = []
        let currentYear = Calendar.current.component(.year, from: .now)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM-dd-yyyy"
        
        do {
            let contents = try String(contentsOfFile: filepath)
            let rows = contents.components(separatedBy: .newlines)
            print("🔍 DIAGNOSTIC: Found \(rows.count) total rows in the CSV file.")
            
            for (index, row) in rows.enumerated() {
                let cleanRow = row.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip headers and empty lines
                if cleanRow.isEmpty || cleanRow.lowercased().hasPrefix("week") || cleanRow.hasPrefix(",,,") { continue }
                
                let columns = parseCSVRow(cleanRow)
                
                // 2. CHECK COLUMN COUNT
                // Lowered from 9 to 8 just in case your CSV is missing a final notes column
                if columns.count >= 8 {
                    let week = Int(columns[0]) ?? 0
                    let dateString = columns[1].trimmingCharacters(in: .whitespaces)
                    let activity = columns.count > 3 ? columns[3] : "REST"
                    let intensity = columns.count > 4 ? columns[4] : ""
                    let strength = columns.count > 5 ? columns[5] : ""
                    let fuelTier = columns.count > 7 ? columns[7] : "MED FUEL TIER"
                    let notes = columns.count > 8 ? columns[8].replacingOccurrences(of: "\"", with: "") : ""
                    
                    let fullDateString = "\(dateString)-\(currentYear)"
                    let date = dateFormatter.date(from: fullDateString) ?? .now
                    
                    let mission = PlannedMission(
                        week: week,
                        dateString: dateString,
                        date: date,
                        activity: activity,
                        powerTarget: intensity,
                        strength: strength,
                        fuelTier: fuelTier,
                        coachNotes: notes
                    )
                    macroCycle.append(mission)
                } else {
                    print("⚠️ WARNING: Skipped Row \(index + 1). Only found \(columns.count) columns. Row data: \(cleanRow)")
                }
            }
            
            print("✅ DIAGNOSTIC COMPLETE: Successfully parsed \(macroCycle.count) missions out of \(rows.count) rows.")
            
        } catch {
            print("🚨 FATAL ERROR: Could not read the contents of hmPlan.csv. \(error.localizedDescription)")
        }
        
        return macroCycle
    }
    
    private static func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false
        
        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == ",", !insideQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
    }
}
