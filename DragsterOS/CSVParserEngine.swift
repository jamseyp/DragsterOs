import Foundation

// 📐 ARCHITECTURE: The Macro-Cycle Ingestion Engine.
// Exclusively designed to parse the HMPlan.csv and generate dynamic daily missions.

// 3️⃣ THE CSV INGESTION PIPELINE

struct CSVParserEngine {
    
    static func fetchTodayMission() -> TacticalMission? {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        let todayString = formatter.string(from: today)
        return parseCSV(lookingFor: todayString)
    }
    
    static func testSpecificDateMission(dateString: String) -> TacticalMission? {
        return parseCSV(lookingFor: dateString)
    }
    
    static func fetchFullMacroCycle() -> [TacticalMission] {
        guard let filepath = Bundle.main.path(forResource: "HMPlan", ofType: "csv") else {
            print("❌ SYSTEM FAULT: 'HMPlan.csv' not found. Check Xcode Target Membership.")
            return []
        }
        
        var macroCycle: [TacticalMission] = []
        
        do {
            let contents = try String(contentsOfFile: filepath)
            let rows = contents.components(separatedBy: .newlines)
            
            for row in rows {
                // Strip hidden return characters (\r) which often corrupt CSV parsing
                let cleanRow = row.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanRow.isEmpty || cleanRow.hasPrefix("Week") || cleanRow.hasPrefix(",,,") { continue }
                
                let columns = parseCSVRow(cleanRow)
                if columns.count >= 9 {
                    macroCycle.append(constructMission(from: columns))
                } else {
                    print("⚠️ Dropped malformed row: \(cleanRow)")
                }
            }
        } catch {
            print("❌ CSV Parsing Fault: \(error.localizedDescription)")
        }
        return macroCycle
    }
    
    private static func parseCSV(lookingFor targetDate: String) -> TacticalMission? {
        guard let filepath = Bundle.main.path(forResource: "HMPlan", ofType: "csv") else {
            print("❌ SYSTEM FAULT: 'hmPlan.csv' not found. Check Xcode Target Membership.")
            return nil
        }
        
        do {
            let contents = try String(contentsOfFile: filepath)
            let rows = contents.components(separatedBy: .newlines)
            
            for row in rows {
                let cleanRow = row.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanRow.isEmpty || cleanRow.hasPrefix("Week") { continue }
                
                let columns = parseCSVRow(cleanRow)
                if columns.count >= 9 {
                    let dateCol = columns[1].trimmingCharacters(in: .whitespaces)
                    if dateCol == targetDate {
                        return constructMission(from: columns)
                    }
                }
            }
        } catch {
            print("❌ CSV Parsing Fault: \(error.localizedDescription)")
        }
        return nil
    }
    
    // ✨ THE UPGRADE: A quote-aware algorithm that prevents commas inside notes from breaking the array
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
    
    private static func constructMission(from columns: [String]) -> TacticalMission {
        let dateCol = columns[1]
        let activity = columns[3]
        let intensity = columns[4]
        let strength = columns[5]
        let fuelTier = columns[7]
        let notes = columns[8]
        
        var finalNotes = notes
        if strength.lowercased() != "rest" && !strength.isEmpty {
            finalNotes = "STRUCTURAL LOAD: \(strength). " + finalNotes
        }
        
        let mappedFuel: FuelTier
        if fuelTier.contains("LOW") { mappedFuel = .low }
        else if fuelTier.contains("MED") { mappedFuel = .medium }
        else if fuelTier.contains("HIGH") { mappedFuel = .high }
        else if fuelTier.contains("RACE") { mappedFuel = .race }
        else { mappedFuel = .medium }
        
        return TacticalMission(
            dateString: dateCol,
            title: activity.uppercased(),
            powerTarget: intensity.uppercased(),
            fuel: mappedFuel,
            coachNotes: finalNotes,
            isAltered: false
        )
    }
}
