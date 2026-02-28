import Foundation
import HealthKit
import Observation

// MARK: - 📐 SYSTEM ARCHITECTURE
@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    var isAuthorized: Bool = false
    
    private init() {}
    
    // MARK: - 🔐 AUTHORIZATION PROTOCOL
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available."])
        }
        
        var readTypes: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.heartRate),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.restingHeartRate),
            HKCategoryType(.sleepAnalysis),
            HKQuantityType(.bodyMass),
            HKQuantityType(.cyclingPower),
            HKQuantityType(.runningPower),
            HKQuantityType(.cyclingCadence),
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.basalEnergyBurned),
            HKQuantityType(.dietaryEnergyConsumed),
            
            // ✨ BIOMECHANICS AUTHORIZATION
            HKQuantityType(.runningGroundContactTime),
            HKQuantityType(.runningVerticalOscillation),
            
            // ✨ BASELINE AUTHORIZATION (V1.1 UPDATES)
            HKQuantityType(.vo2Max),
            HKQuantityType(.bodyFatPercentage),
            
            // ✨ ADVANCED RECOVERY AUTHORIZATION (V1.2 UPDATES)
            HKQuantityType(.heartRateRecoveryOneMinute),
            HKQuantityType(.respiratoryRate),
            HKQuantityType(.appleSleepingWristTemperature),
            
            // Macronutrient info
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryCarbohydrates),
            HKQuantityType(.dietaryFatTotal)
        ]
        
        // ✨ iOS 18 TRUE RPE (EFFORT SCORE) AUTHORIZATION
        if #available(iOS 18.0, *) {
            readTypes.insert(HKQuantityType(.estimatedWorkoutEffortScore))
        }
        
        let writeTypes: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling)
        ]
        
        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        
        // Update local state upon successful authorization
        await MainActor.run {
            self.isAuthorized = true
        }
    }
    
    // MARK: - 🧬 CORE BIOMETRIC FETCHERS
    
    func fetchMorningReadiness() async throws -> (hrv: Double, restingHR: Double, sleepHours: Double) {
        async let hrv = fetchLatestHRV()
        async let rhr = fetchLatestRestingHR()
        async let sleep = fetchLastNightSleep()
        return try await (hrv, rhr, sleep)
    }
    
    private func fetchLatestHRV() async throws -> Double {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return 0.0 }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: .now), end: .now)
        let descriptor = HKSampleQueryDescriptor(predicates: [.quantitySample(type: hrvType, predicate: predicate)], sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)], limit: 1)
        let results = try await descriptor.result(for: healthStore)
        return results.first?.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) ?? 0.0
    }
    
    private func fetchLatestRestingHR() async throws -> Double {
        guard let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else { return 0.0 }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: .now), end: .now)
        let descriptor = HKSampleQueryDescriptor(predicates: [.quantitySample(type: rhrType, predicate: predicate)], sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)], limit: 1)
        let results = try await descriptor.result(for: healthStore)
        return results.first?.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) ?? 0.0
    }
    
    private func fetchLastNightSleep() async throws -> Double {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return 0.0 }
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: .now)
        let descriptor = HKSampleQueryDescriptor(predicates: [.categorySample(type: sleepType, predicate: predicate)], sortDescriptors: [])
        let results = try await descriptor.result(for: healthStore)
        let asleepSamples = results.filter {
            $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
            $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
            $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
            $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
        }
        let totalSleepSeconds = asleepSamples.reduce(0.0) { total, sample in total + sample.endDate.timeIntervalSince(sample.startDate) }
        return totalSleepSeconds / 3600.0
    }
    
    func fetchLatestWeight() async throws -> Double {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return 0.0 }
        let descriptor = HKSampleQueryDescriptor(predicates: [.quantitySample(type: weightType)], sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)], limit: 1)
        let results = try await descriptor.result(for: healthStore)
        return results.first?.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo)) ?? 0.0
    }
    
    func fetchLatestVO2Max() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .vo2Max) else { return 0.0 }
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        do {
            let samples = try await descriptor.result(for: healthStore)
            if let sample = samples.first {
                return sample.quantity.doubleValue(for: HKUnit(from: "ml/kg*min"))
            }
        } catch {
            print("❌ VO2 Max Fetch Fault: \(error)")
        }
        return 0.0
    }
    
    func fetchLatestBodyFat() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) else { return 0.0 }
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        do {
            let samples = try await descriptor.result(for: healthStore)
            if let sample = samples.first {
                return sample.quantity.doubleValue(for: HKUnit.percent()) * 100
            }
        } catch {
            print("❌ Body Fat Fetch Fault: \(error)")
        }
        return 0.0
    }
    
    func fetchLatestWorkout() async throws -> HKWorkout? {
        let workoutType = HKObjectType.workoutType()
        let twelveHoursAgo = Calendar.current.date(byAdding: .hour, value: -12, to: .now)!
        let predicate = HKQuery.predicateForSamples(withStart: twelveHoursAgo, end: .now, options: .strictStartDate)
        let descriptor = HKSampleQueryDescriptor(predicates: [.sample(type: workoutType, predicate: predicate)], sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)], limit: 1)
        let results = try await descriptor.result(for: healthStore)
        return results.first as? HKWorkout
    }
    
    func fetchHistoricalWorkouts(daysBack: Int = 30) async throws -> [HKWorkout] {
        let workoutType = HKObjectType.workoutType()
        let startDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: .now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: .now, options: .strictStartDate)
        let descriptor = HKSampleQueryDescriptor(predicates: [.sample(type: workoutType, predicate: predicate)], sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)])
        let results = try await descriptor.result(for: healthStore)
        return results.compactMap { $0 as? HKWorkout }
    }
}

// MARK: - 📈 KINETIC TELEMETRY (SCALARS)
extension HealthKitManager {
    // --- 1. SCALAR FETCHERS ---
    func fetchAverageHR(for workout: HKWorkout) async -> Double {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return 0.0 }
        let predicate = HKQuery.predicateForObjects(from: workout)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: hrType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
                let bpmUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                continuation.resume(returning: result?.averageQuantity()?.doubleValue(for: bpmUnit) ?? 0.0)
            }
            healthStore.execute(query)
        }
    }
    
    // ✨ NEW: TRUE RPE (EFFORT SCORE)
    func fetchTrueRPE(for workout: HKWorkout) async -> Double {
        if #available(iOS 18.0, *) {
            if let effortType = HKQuantityType.quantityType(forIdentifier: .estimatedWorkoutEffortScore) {
                
                // First, check if the score is bundled directly in the workout statistics
                if let stat = workout.statistics(for: effortType),
                   let quantity = stat.averageQuantity() ?? stat.mostRecentQuantity() {
                    return quantity.doubleValue(for: .count())
                }
                
                // Fallback: Query the HealthStore for it
                let predicate = HKQuery.predicateForObjects(from: workout)
                return await withCheckedContinuation { continuation in
                    let query = HKStatisticsQuery(quantityType: effortType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
                        let rpe = result?.averageQuantity()?.doubleValue(for: .count()) ?? result?.mostRecentQuantity()?.doubleValue(for: .count()) ?? 0.0
                        continuation.resume(returning: rpe)
                    }
                    healthStore.execute(query)
                }
            }
        }
        
        // Final fallback for manual entries or pre-iOS 18
        return workout.metadata?["CustomRPE"] as? Double ?? 0.0
    }
    
    func fetchAveragePower(for workout: HKWorkout, isRide: Bool) async -> Double {
        let typeId: HKQuantityTypeIdentifier = isRide ? .cyclingPower : .runningPower
        guard let qtyType = HKQuantityType.quantityType(forIdentifier: typeId) else { return 0.0 }
        let predicate = HKQuery.predicateForObjects(from: workout)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: qtyType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
                continuation.resume(returning: result?.averageQuantity()?.doubleValue(for: .watt()) ?? 0.0)
            }
            healthStore.execute(query)
        }
    }
    
    func fetchAverageCadence(for workout: HKWorkout, isRide: Bool) async -> Double {
        if isRide {
            guard let qtyType = HKQuantityType.quantityType(forIdentifier: .cyclingCadence) else { return 0.0 }
            let predicate = HKQuery.predicateForObjects(from: workout)
            return await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: qtyType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
                    let unit = HKUnit.count().unitDivided(by: .minute())
                    continuation.resume(returning: result?.averageQuantity()?.doubleValue(for: unit) ?? 0.0)
                }
                healthStore.execute(query)
            }
        } else {
            guard let qtyType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0.0 }
            let predicate = HKQuery.predicateForObjects(from: workout)
            return await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: qtyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                    let totalSteps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0.0
                    let minutes = workout.duration / 60.0
                    continuation.resume(returning: minutes > 0 ? (totalSteps / minutes) : 0.0)
                }
                healthStore.execute(query)
            }
        }
    }
    
    func fetchAverageGCT(for workout: HKWorkout) async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .runningGroundContactTime) else { return 0.0 }
        let predicate = HKQuery.predicateForObjects(from: workout)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
                continuation.resume(returning: result?.averageQuantity()?.doubleValue(for: HKUnit.secondUnit(with: .milli)) ?? 0.0)
            }
            healthStore.execute(query)
        }
    }
    
    func fetchAverageOscillation(for workout: HKWorkout) async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .runningVerticalOscillation) else { return 0.0 }
        let predicate = HKQuery.predicateForObjects(from: workout)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
                continuation.resume(returning: result?.averageQuantity()?.doubleValue(for: HKUnit.meterUnit(with: .centi)) ?? 0.0)
            }
            healthStore.execute(query)
        }
    }
    
    func fetchElevation(for workout: HKWorkout) -> Double {
        if let elevation = workout.metadata?[HKMetadataKeyElevationAscended] as? HKQuantity {
            return elevation.doubleValue(for: .meter())
        }
        return 0.0
    }
}

// MARK: - 📈 KINETIC TELEMETRY (VECTORS)
extension HealthKitManager {
    // --- 2. VECTOR FETCHERS ---
    private func fetchTimeSeriesData(identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, durationMinutes: Double) async -> [(date: Date, value: Double)] {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return [] }
        let end = Calendar.current.date(byAdding: .second, value: Int(durationMinutes * 60), to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: quantityType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)],
            limit: HKObjectQueryNoLimit
        )
        
        guard let results = try? await descriptor.result(for: healthStore) else { return [] }
        return results.map { (date: $0.startDate, value: $0.quantity.doubleValue(for: unit)) }
    }
    
    func fetchHRSeries(start: Date, durationMinutes: Double) async -> [(Date, Double)] {
        return await fetchTimeSeriesData(identifier: .heartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: start, durationMinutes: durationMinutes)
    }
    
    func fetchPowerSeries(start: Date, durationMinutes: Double, isRide: Bool) async -> [(Date, Double)] {
        let type: HKQuantityTypeIdentifier = isRide ? .cyclingPower : .runningPower
        return await fetchTimeSeriesData(identifier: type, unit: .watt(), start: start, durationMinutes: durationMinutes)
    }
    
    func fetchCadenceSeries(start: Date, durationMinutes: Double, isRide: Bool) async -> [(Date, Double)] {
        if isRide {
            return await fetchTimeSeriesData(
                identifier: .cyclingCadence,
                unit: HKUnit.count().unitDivided(by: .minute()),
                start: start,
                durationMinutes: durationMinutes
            )
        } else {
            guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return [] }
            let end = Calendar.current.date(byAdding: .second, value: Int(durationMinutes * 60), to: start)!
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.quantitySample(type: stepType, predicate: predicate)],
                sortDescriptors: [SortDescriptor(\.startDate, order: .forward)],
                limit: HKObjectQueryNoLimit
            )
            
            guard let results = try? await descriptor.result(for: healthStore) else { return [] }
            
            return results.compactMap { sample in
                let steps = sample.quantity.doubleValue(for: .count())
                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                guard duration > 0 else { return nil }
                
                let spm = (steps / duration) * 60.0
                return (date: sample.startDate, value: spm)
            }
        }
    }
    
    func fetchGCTSeries(start: Date, durationMinutes: Double) async -> [(Date, Double)] {
        return await fetchTimeSeriesData(
            identifier: .runningGroundContactTime,
            unit: HKUnit.secondUnit(with: .milli),
            start: start,
            durationMinutes: durationMinutes
        )
    }
    
    func fetchOscillationSeries(start: Date, durationMinutes: Double) async -> [(Date, Double)] {
        return await fetchTimeSeriesData(
            identifier: .runningVerticalOscillation,
            unit: HKUnit.meterUnit(with: .centi),
            start: start,
            durationMinutes: durationMinutes
        )
    }
}

// MARK: - 🕰️ HISTORICAL TELEMETRY ENGINE
extension HealthKitManager {
    func fetchHistoricalBiometrics(daysBack: Int = 30) async -> [(date: Date, hrv: Double, restingHR: Double, sleepHours: Double)] {
        var historicalData: [(Date, Double, Double, Double)] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        
        for dayOffset in 1...daysBack {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            let startOfDay = targetDate
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            let sleepStart = calendar.date(byAdding: .hour, value: -12, to: startOfDay)!
            
            async let hrv = fetchQuantity(type: .heartRateVariabilitySDNN, start: startOfDay, end: endOfDay, unit: HKUnit.secondUnit(with: .milli))
            async let rhr = fetchQuantity(type: .restingHeartRate, start: startOfDay, end: endOfDay, unit: HKUnit.count().unitDivided(by: HKUnit.minute()))
            async let sleep = fetchSleepDuration(start: sleepStart, end: endOfDay)
            
            let metrics = await (hrv, rhr, sleep)
            
            if metrics.0 > 0 || metrics.2 > 0 {
                historicalData.append((
                    date: targetDate,
                    hrv: metrics.0,
                    restingHR: metrics.1,
                    sleepHours: metrics.2
                ))
            }
        }
        return historicalData
    }
    
    private func fetchQuantity(type identifier: HKQuantityTypeIdentifier, start: Date, end: Date, unit: HKUnit) async -> Double {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0.0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: quantityType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        guard let results = try? await descriptor.result(for: healthStore), let sample = results.first else { return 0.0 }
        return sample.quantity.doubleValue(for: unit)
    }
    
    private func fetchSleepDuration(start: Date, end: Date) async -> Double {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return 0.0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: []
        )
        guard let results = try? await descriptor.result(for: healthStore) else { return 0.0 }
        
        let asleepSamples = results.filter {
            $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
            $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
            $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
            $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
        }
        
        let totalSleepSeconds = asleepSamples.reduce(0.0) { total, sample in
            total + sample.endDate.timeIntervalSince(sample.startDate)
        }
        return totalSleepSeconds / 3600.0
    }
}

// MARK: - 📤 TWO-WAY SYNC (WRITE TO APPLE HEALTH & NUTRITION)
extension HealthKitManager {
    
    func saveWorkoutToAppleHealth(discipline: String, durationMinutes: Double, distanceKM: Double, averageHR: Double, notes: String) async throws {
        let activityType: HKWorkoutActivityType
        switch discipline {
        case "RUN": activityType = .running
        case "SPIN": activityType = .cycling
        case "ROW": activityType = .rowing
        case "STRENGTH": activityType = .traditionalStrengthTraining
        default: activityType = .other
        }
        
        let start = Calendar.current.date(byAdding: .minute, value: -Int(durationMinutes), to: .now)!
        let end = Date()
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = activityType
        
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: workoutConfiguration, device: .local())
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.beginCollection(withStart: start) { success, error in
                if let error = error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: ()) }
            }
        }
        
        if distanceKM > 0 {
            let distanceType = discipline == "SPIN" ? HKQuantityType.quantityType(forIdentifier: .distanceCycling)! : HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
            let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: distanceKM * 1000.0)
            let distanceSample = HKCumulativeQuantitySample(type: distanceType, quantity: distanceQuantity, start: start, end: end)
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                builder.add([distanceSample]) { success, error in
                    if let error = error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: ()) }
                }
            }
        }
        
        if averageHR > 0 {
            let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            let hrQuantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: averageHR)
            let hrSample = HKQuantitySample(type: hrType, quantity: hrQuantity, start: start, end: end)
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                builder.add([hrSample]) { success, error in
                    if let error = error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: ()) }
                }
            }
        }
        
        var metadata: [String: Any] = [HKMetadataKeyTimeZone: TimeZone.current.identifier]
        if !notes.isEmpty { metadata["DragsterOS_Debrief"] = notes }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.addMetadata(metadata) { success, error in
                if let error = error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: ()) }
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.endCollection(withEnd: end) { success, error in
                if let error = error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: ()) }
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.finishWorkout { workout, error in
                if let error = error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: ()) }
            }
        }
    }
    
    func fetchEnergyBalance(for date: Date = .now) async -> (intake: Double, burned: Double, net: Double) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        func fetchSum(for typeIdentifier: HKQuantityTypeIdentifier) async -> Double {
            guard let type = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else { return 0.0 }
            return await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                    let sum = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0.0
                    continuation.resume(returning: sum)
                }
                healthStore.execute(query)
            }
        }
        
        async let active = fetchSum(for: .activeEnergyBurned)
        async let basal = fetchSum(for: .basalEnergyBurned)
        async let dietary = fetchSum(for: .dietaryEnergyConsumed)
        
        let (a, b, d) = await (active, basal, dietary)
        let totalBurned = a + b
        
        return (intake: d, burned: totalBurned, net: d - totalBurned)
    }

    func fetchYesterdayEnergyBalance() async -> Double {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return 0.0 }
        let data = await fetchEnergyBalance(for: yesterday)
        return data.net
    }

    func fetchHistoricalEnergyBalance(daysBack: Int) async -> [(date: Date, net: Double)] {
        var historical: [(Date, Double)] = []
        let calendar = Calendar.current
        
        for i in 1...daysBack {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let data = await fetchEnergyBalance(for: date)
            historical.append((date: date, net: data.net))
        }
    
        return historical.sorted(by: { $0.0 < $1.0 })
    }

    func fetchDailyMacros(for date: Date = .now) async -> (protein: Double, carbs: Double, fat: Double) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        func fetchSum(for typeIdentifier: HKQuantityTypeIdentifier) async -> Double {
            guard let type = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else { return 0.0 }
            return await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                    let sum = result?.sumQuantity()?.doubleValue(for: .gram()) ?? 0.0
                    continuation.resume(returning: sum)
                }
                healthStore.execute(query)
            }
        }
        
        async let p = fetchSum(for: .dietaryProtein)
        async let c = fetchSum(for: .dietaryCarbohydrates)
        async let f = fetchSum(for: .dietaryFatTotal)
        
        let (protein, carbs, fat) = await (p, c, f)
        return (protein: protein, carbs: carbs, fat: fat)
    }
}

// MARK: - 🔬 ADVANCED RECOVERY FETCHERS
extension HealthKitManager {
    
    /// Returns the exact heart rate drop (in BPM) 60 seconds post-workout
    func fetchLatestHeartRateRecovery() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRateRecoveryOneMinute) else { return 0.0 }
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        do {
            let samples = try await descriptor.result(for: healthStore)
            if let sample = samples.first {
                return sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            }
        } catch {
            print("❌ HR Recovery Fetch Fault: \(error)")
        }
        return 0.0
    }
    
    /// Averages the respiratory rate (breaths per minute) over the last 24 hours (primarily capturing sleep)
    func fetchSleepingRespiratoryRate() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else { return 0.0 }
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: .now)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
                let unit = HKUnit.count().unitDivided(by: .minute())
                continuation.resume(returning: result?.averageQuantity()?.doubleValue(for: unit) ?? 0.0)
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetches the latest nocturnal wrist temperature deviation in Celsius
    func fetchWristTemperatureDeviation() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .appleSleepingWristTemperature) else { return 0.0 }
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        do {
            let samples = try await descriptor.result(for: healthStore)
            if let sample = samples.first {
                return sample.quantity.doubleValue(for: .degreeCelsius())
            }
        } catch {
            print("❌ Wrist Temp Fetch Fault: \(error)")
        }
        return 0.0
    }
    
    /// Parses the exact breakdown of last night's sleep into Core, Deep, and REM stages (in hours)
    func fetchLastNightSleepArchitecture() async -> (deep: Double, rem: Double, core: Double) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return (0, 0, 0) }
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: .now)
        let descriptor = HKSampleQueryDescriptor(predicates: [.categorySample(type: sleepType, predicate: predicate)], sortDescriptors: [])
        
        do {
            let results = try await descriptor.result(for: healthStore)
            var deep: Double = 0
            var rem: Double = 0
            var core: Double = 0
            
            for sample in results {
                let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600.0 // Convert to hours
                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    deep += duration
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    rem += duration
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    core += duration
                default:
                    break
                }
            }
            return (deep, rem, core)
        } catch {
            print("❌ Sleep Architecture Fetch Fault: \(error)")
            return (0, 0, 0)
        }
    }
}
