//
//  TrainingEngineService.swift
//  DragsterOS
//
//  Created by James Parker on 28/02/2026.
//

import Foundation

/// 🧠 THE ENGINE: A deterministic service that distributes Brad Hudson's 80/20
/// mathematical load into a user-defined Hybrid Training Skeleton.
struct TrainingEngineService {
    
    enum EngineError: Error {
        case insufficientLeadTime
        case excessiveInitialVolume
        case invalidTargetDate
        case missingSkeleton
    }
    
    struct PlanConfiguration {
        let objective: StrategicObjective
        let registry: UserRegistry
        let currentCTL: Double
        let startDate: Date
        let initialWeeklyMinutes: Double
        let skeleton: [Int: [BlueprintSlot]] // ✨ THE NEW SKELETON INJECTION
    }
    
    // MARK: - 🚀 The Ignition
    
    static func generatePlan(config: PlanConfiguration) throws -> [OperationalDirective] {
        guard !config.skeleton.isEmpty else { throw EngineError.missingSkeleton }
        
        let calendar = Calendar.current
        let totalDays = calendar.dateComponents([.day], from: calendar.startOfDay(for: config.startDate), to: calendar.startOfDay(for: config.objective.targetDate)).day ?? 0
        guard totalDays >= 28 else { throw EngineError.insufficientLeadTime }
        
        let totalWeeks = Int(ceil(Double(totalDays) / 7.0))
        
        let baseEnd = Int(Double(totalWeeks) * 0.50)
        let buildEnd = baseEnd + Int(Double(totalWeeks) * 0.30)
        let peakEnd = buildEnd + Int(Double(totalWeeks) * 0.15)
        
        var plan: [OperationalDirective] = []
        var currentVolume = config.initialWeeklyMinutes
        
        for weekIndex in 0..<totalWeeks {
            let weekStartDate = calendar.date(byAdding: .day, value: weekIndex * 7, to: calendar.startOfDay(for: config.startDate))!
            let isRaceWeek = (weekIndex == totalWeeks - 1)
            
            if isRaceWeek {
                // Taper & Race Protocol overrides the Skeleton
                plan.append(contentsOf: generateRaceWeekMicrocycle(weekStartDate: weekStartDate, config: config, calendar: calendar))
            } else {
                let isDeloadWeek = (weekIndex + 1) % 4 == 0
                let phase = determinePhase(index: weekIndex, base: baseEnd, build: buildEnd, peak: peakEnd)
                
                if isDeloadWeek {
                    currentVolume *= 0.85
                } else if weekIndex > 0 && (weekIndex % 4 != 0) {
                    currentVolume *= 1.10
                }
                
                let weeklyDirectives = generateDynamicMicrocycle(
                    weekStartDate: weekStartDate,
                    totalVolume: currentVolume,
                    phase: phase,
                    config: config,
                    calendar: calendar
                )
                plan.append(contentsOf: weeklyDirectives)
            }
        }
        
        return plan
    }
    
    // MARK: - 🧪 The Skeleton Math Algorithm
    
    private static func generateDynamicMicrocycle(
            weekStartDate: Date,
            totalVolume: Double,
            phase: TrainingPhase,
            config: PlanConfiguration,
            calendar: Calendar
        ) -> [OperationalDirective] {
            
            var directives: [OperationalDirective] = []
            let allSlots = config.skeleton.values.flatMap { $0 }
            
            // Volume Math...
            let qualityMinsTotal = totalVolume * 0.20
            let aerobicMinsTotal = totalVolume * 0.80
            let qualityCount = allSlots.filter { isQuality($0.category) }.count
            let longRunCount = allSlots.filter { $0.category == .longRun }.count
            let aerobicCount = allSlots.filter { isAerobic($0.category) && $0.category != .longRun }.count
            
            let longRunMinsTotal = longRunCount > 0 ? min(totalVolume * 0.45, aerobicMinsTotal * 0.6) : 0
            let remainingAerobicMins = aerobicMinsTotal - longRunMinsTotal
            
            let minsPerQuality = qualityCount > 0 ? (qualityMinsTotal / Double(qualityCount)) : 0
            let minsPerLong = longRunCount > 0 ? (longRunMinsTotal / Double(longRunCount)) : 0
            let minsPerAerobic = aerobicCount > 0 ? (remainingAerobicMins / Double(aerobicCount)) : 0
            
            for dayOffset in 0..<7 {
                let specificDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate)!
                
                if let dailySlots = config.skeleton[dayOffset] {
                    for slot in dailySlots {
                        let totalMins = Int(isQuality(slot.category) ? minsPerQuality : (slot.category == .longRun ? minsPerLong : minsPerAerobic))
                        
                        var fuel = "LOW"
                        var notes = ""
                        var warmup = 0
                        var intervalSets = 1
                        var workDur = totalMins
                        var recoveryDur = 0
                        var cooldown = 0
                        var targetWatts = 0
                        
                        // ✨ HIGH FIDELITY WORKOUT STRUCTURING
                        if slot.category == .speedRun {
                            fuel = "HIGH"
                            warmup = min(15, totalMins / 4)
                            cooldown = min(10, totalMins / 5)
                            let activeMins = max(5, totalMins - warmup - cooldown) // Remaining time for intervals
                            intervalSets = max(1, activeMins / 5) // 3m work + 2m rest = 5m block
                            workDur = 3
                            recoveryDur = 2
                            notes = "VO2 Max Intervals. Run hard for \(workDur)m, jog for \(recoveryDur)m."
                            
                        } else if slot.category == .thresholdRun {
                            fuel = "HIGH"
                            warmup = 15
                            cooldown = 10
                            let activeMins = max(10, totalMins - warmup - cooldown)
                            intervalSets = max(1, activeMins / 15) // Long 15-minute tempo blocks
                            workDur = 12
                            recoveryDur = 3
                            notes = "Threshold Pace. Comfortably hard. Do not exceed Z4."
                            
                        } else if slot.category == .longRun {
                            fuel = "LOW"
                            workDur = totalMins
                            notes = "Keep heart rate strictly in Zone 2. Time on feet is the goal."
                            
                        } else if slot.category == .powerRow {
                            fuel = "HIGH"
                            warmup = 10
                            cooldown = 5
                            intervalSets = 8
                            workDur = 2 // 2 min power sprints
                            recoveryDur = 1
                            targetWatts = config.registry.ftp + 30 // Push above FTP
                            notes = "Concept2 Power Intervals. Hit \(targetWatts)W during work phases."
                            
                        } else if isAerobic(slot.category) {
                            fuel = slot.category == .baseRow ? "MED" : "LOW"
                            workDur = totalMins
                            notes = "Active recovery and aerobic base building. Conversational pace."
                            
                        } else if isStrength(slot.category) {
                            fuel = "MED"
                            workDur = 45
                            notes = "Focus on form and lean mass preservation."
                        } else if slot.category == .rest {
                            workDur = 0
                            notes = "Active rest. Prioritize sleep and hydration."
                        }
                        
                        let title = "[\(slot.timeOfDay.rawValue)] \(slot.category.rawValue)"
                        
                        directives.append(OperationalDirective(
                            assignedDate: specificDate,
                            discipline: slot.category.baseDiscipline,
                            missionTitle: title,
                            missionNotes: "System Generated",
                            warmupMinutes: warmup,
                            intervalSets: intervalSets,
                            workDurationMinutes: workDur,
                            workTargetWatts: targetWatts,
                            recoveryDurationMinutes: recoveryDur,
                            cooldownMinutes: cooldown,
                            fuelTier: fuel,
                            targetLoad: Int(Double(totalMins) * 0.8), // Rough TSS estimation
                            coachNotes: notes
                        ))
                    }
                }
            }
            
            return directives
        }
    
    // MARK: - Legacy Race Prep & Helpers
    
    private static func generateRaceWeekMicrocycle(weekStartDate: Date, config: PlanConfiguration, calendar: Calendar) -> [OperationalDirective] {
        var directives: [OperationalDirective] = []
        let targetDate = calendar.startOfDay(for: config.objective.targetDate)
        var currentDate = calendar.startOfDay(for: weekStartDate)
        
        while currentDate <= targetDate {
            let daysUntilRace = calendar.dateComponents([.day], from: currentDate, to: targetDate).day ?? 0
            
            if daysUntilRace == 0 {
                directives.append(createDirective(date: currentDate, title: "RACE DAY: \(config.objective.eventName)", duration: 120, type: "RUN", fuel: "RACE", notes: "Trust your training. Execute."))
            } else if daysUntilRace == 1 {
                directives.append(createDirective(date: currentDate, title: "Rest & Carb Load", duration: 0, type: "REST", fuel: "HIGH", notes: "Zero output. Maximize glycogen stores."))
            } else if daysUntilRace == 2 {
                directives.append(createDirective(date: currentDate, title: "Shakeout Run", duration: 20, type: "RUN", fuel: "LOW", notes: "Very light jog. Keep CNS primed."))
            } else if daysUntilRace == 3 {
                directives.append(createDirective(date: currentDate, title: "Active Mobility", duration: 20, type: "REST", fuel: "MED", notes: "Conserve energy."))
            } else {
                directives.append(createDirective(date: currentDate, title: "Taper Aerobic Flush", duration: 30, type: "SPIN", fuel: "LOW", notes: "Shed residual fatigue."))
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return directives
    }
    
    private static func createDirective(date: Date, title: String, duration: Double, type: String, fuel: String, notes: String) -> OperationalDirective {
        return OperationalDirective(
            assignedDate: date, discipline: type, missionTitle: title,
            missionNotes: "System Generated", workDurationMinutes: Int(duration),
            fuelTier: fuel, coachNotes: notes
        )
    }
    
    private static func determinePhase(index: Int, base: Int, build: Int, peak: Int) -> TrainingPhase {
        if index < base { return .base }
        if index < build { return .build }
        if index < peak { return .peak }
        return .taper
    }
    
    private static func isQuality(_ category: SessionCategory) -> Bool {
        return category == .speedRun || category == .thresholdRun || category == .powerRow
    }
    
    private static func isAerobic(_ category: SessionCategory) -> Bool {
        return category == .easyRun || category == .recoverySpin || category == .baseRow || category == .longRun
    }
    
    private static func isStrength(_ category: SessionCategory) -> Bool {
        return category == .strengthUpper || category == .strengthLower || category == .strengthFull
    }
    
    enum TrainingPhase: String {
        case base, build, peak, taper
    }
}
