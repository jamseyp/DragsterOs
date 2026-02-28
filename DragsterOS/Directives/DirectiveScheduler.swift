import Foundation
import WorkoutKit
import HealthKit

class DirectiveScheduler {
    static let shared = DirectiveScheduler()
    
    private init() {}
    
    /// Maps the SwiftData OperationalDirective directly to a native Apple Watch workout
    func pushMissionToWatch(directive: OperationalDirective) async throws {
        
        let discipline = directive.discipline.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // 🚨 0. REST DAY PROTOCOL
        if discipline == "REST" {
            print("System: REST directive acknowledged. No Watch transmission required.")
            return
        }
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        
        // 🚨 1. STRENGTH DAY PROTOCOL
        // WorkoutKit prohibits CustomWorkout for lifting. We must use SingleGoalWorkout.
        if discipline == "STRENGTH" {
            let totalTime = directive.warmupMinutes + directive.workDurationMinutes + directive.cooldownMinutes
            let safeTime = max(1, totalTime)
            
            let goalWorkout = SingleGoalWorkout(activity: .traditionalStrengthTraining, goal: .time(Double(safeTime), .minutes))
            let workoutPlan = WorkoutPlan(.goal(goalWorkout))
            
            await WorkoutScheduler.shared.schedule(workoutPlan, at: dateComponents)
            print("Tactical Directive [\(directive.missionTitle)] transmitted to Command System (Single Goal).")
            return
        }
        
        // 🚨 2. KINETIC PROTOCOL (RUN & SPIN)
        let activityType: HKWorkoutActivityType = (discipline == "SPIN") ? .cycling : .running
        
        // Generate Power Alert safely
        var powerAlert: PowerRangeAlert? = nil
        if directive.workTargetWatts > 0 {
            let lowerBound = Double(max(0, directive.workTargetWatts - 15))
            let upperBound = Double(directive.workTargetWatts + 15)
            powerAlert = .power(lowerBound...upperBound, unit: .watts)
        }
        
        // Build the Main Set dynamically to prevent 0-minute crash
        let workStep: WorkoutStep
        if let alert = powerAlert {
            workStep = WorkoutStep(goal: .time(Double(directive.workDurationMinutes), .minutes), alert: alert)
        } else {
            workStep = WorkoutStep(goal: .time(Double(directive.workDurationMinutes), .minutes))
        }
        
        var stepsToInclude: [IntervalStep] = [IntervalStep(.work, step: workStep)]
        
        // ⚠️ CRASH AVOIDANCE: Only append a recovery step if the duration is mathematically > 0
        if directive.recoveryDurationMinutes > 0 {
            let recoveryStep = WorkoutStep(goal: .time(Double(directive.recoveryDurationMinutes), .minutes))
            stepsToInclude.append(IntervalStep(.recovery, step: recoveryStep))
        }
        
        let safeIterations = max(1, directive.intervalSets)
        let mainBlock = IntervalBlock(steps: stepsToInclude, iterations: safeIterations)
        
        // ⚠️ CRASH AVOIDANCE: Warmup and Cooldown must be nil if 0
        let warmupStep: WorkoutStep? = directive.warmupMinutes > 0 ? WorkoutStep(goal: .time(Double(directive.warmupMinutes), .minutes)) : nil
        let cooldownStep: WorkoutStep? = directive.cooldownMinutes > 0 ? WorkoutStep(goal: .time(Double(directive.cooldownMinutes), .minutes)) : nil
        
        // Assemble the final object
        let customWorkout = CustomWorkout(
            activity: activityType,
            displayName: directive.missionTitle,
            warmup: warmupStep,
            blocks: [mainBlock],
            cooldown: cooldownStep
        )
        
        let workoutPlan = WorkoutPlan(.custom(customWorkout))
        
        await WorkoutScheduler.shared.schedule(workoutPlan, at: dateComponents)
        print("Tactical Directive [\(directive.missionTitle)] transmitted to Command System (Custom Intervals).")
    }
}
