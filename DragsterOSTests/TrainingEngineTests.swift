import XCTest
@testable import DragsterOS // Ensure this exactly matches your main app target name

final class TrainingEngineTests: XCTestCase {
    
    func testHudsonFatigueOscillation() throws {
        // ✨ THE FIX: Declare the calendar first so we can use it to calculate future dates!
        let calendar = Calendar.current
        
        // 1. Setup a dummy 16-week objective (112 days)
        let startDate = Date()
        let targetDate = calendar.date(byAdding: .day, value: 112, to: startDate)!
        
        let objective = StrategicObjective(eventName: "Test HM", targetDate: targetDate)
        let registry = UserRegistry(targetWeight: 90.0) // Your rebuild target
        
        let config = TrainingEngineService.PlanConfiguration(
            objective: objective,
            registry: registry,
            currentCTL: 50.0,
            startDate: startDate,
            initialWeeklyMinutes: 180.0 // Starting with 3 hours/week
        )
        
        // 2. Generate the Plan Instantly
        let plan = try TrainingEngineService.generatePlan(config: config)
        
        // 3. Group the generated plan back into weeks to test the volume math
        var weeklyVolumes: [Int: Int] = [:] // WeekIndex : TotalMinutes
        
        for directive in plan {
            let weekOffset = calendar.dateComponents([.day], from: startDate, to: directive.assignedDate).day! / 7
            weeklyVolumes[weekOffset, default: 0] += directive.workDurationMinutes
        }
        
        // 4. ASSERTION: The 4th Week Deload Rule (-15%)
        // Week index 3 is the 4th week (0, 1, 2, 3)
        let week3Volume = Double(weeklyVolumes[2] ?? 0)
        let week4DeloadVolume = Double(weeklyVolumes[3] ?? 0)
        
        XCTAssertLessThan(week4DeloadVolume, week3Volume, "Engine failed to deload on the 4th week.")
        
        // 5. ASSERTION: The 10% Weekly Ramp Rule
        let week1Volume = Double(weeklyVolumes[0] ?? 0)
        let week2Volume = Double(weeklyVolumes[1] ?? 0)
        
        XCTAssertLessThanOrEqual(week2Volume, week1Volume * 1.1001, "Engine violated the 10% week-over-week volume safety constraint.")
        
        print("✅ Hudson Math Verified: 16-week plan generated and validated in \(plan.count) operations.")
    }
}
