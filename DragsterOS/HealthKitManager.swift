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
 
    
    
    // MARK: - 🔐 AUTHORIZATION PROTOCOL
        func requestAuthorization() async throws {
            guard HKHealthStore.isHealthDataAvailable() else {
                throw NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."])
            }
            
            // 📥 DATA WE NEED TO READ (Ingestion)
            let readTypes: Set<HKObjectType> = [
                // Workouts & Kinematics
                HKObjectType.workoutType(),
                HKQuantityType(.heartRate),
                HKQuantityType(.distanceWalkingRunning),
                HKQuantityType(.distanceCycling),
                
                // ✨ NEW: BIOLOGICAL TELEMETRY
                HKQuantityType(.heartRateVariabilitySDNN), // Apple's native HRV format
                HKQuantityType(.restingHeartRate),         // RHR
                HKCategoryType(.sleepAnalysis),            // Sleep
                HKQuantityType(.bodyMass),                 // Weight/Mass
                
                // ✨ NEW: MECHANICAL TELEMETRY
                HKQuantityType(.cyclingPower),             // Bike Wattage
                HKQuantityType(.runningPower),             // Run Wattage (if using Stryd/Apple Watch)
                HKQuantityType(.cyclingCadence)   ,         // Spin Cadence
                // Add this to your readTypes matrix
                HKQuantityType(.stepCount), // Running cadence
                
                
                // ✨ NEW: THERMODYNAMIC LOGISTICS
                            HKQuantityType(.activeEnergyBurned),       // Movement / Workout Caloric Burn
                            HKQuantityType(.basalEnergyBurned),        // Resting Metabolic Rate (BMR)
                            HKQuantityType(.dietaryEnergyConsumed)     // Caloric Intake (Food Logged)
            ]
            
            // 📤 DATA WE NEED TO WRITE (If logging manual directives)
            let writeTypes: Set<HKSampleType> = [
                HKObjectType.workoutType(),
                HKQuantityType(.distanceWalkingRunning),
                HKQuantityType(.distanceCycling)
            ]
            
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        }
    
    // MARK: - 🧬 TELEMETRY EXTRACTION (Async Pipeline)
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
    
    // MARK: - 📊 HISTORICAL THERMODYNAMICS
        
        /// Fetches energy balance data for a rolling window (7, 14, or 30 days).
        func fetchHistoricalEnergyBalance(daysBack: Int) async -> [(date: Date, intake: Double, burned: Double, net: Double)] {
            var historicalData: [(date: Date, intake: Double, burned: Double, net: Double)] = []
            let calendar = Calendar.current
            let now = Date()
            
            // Loop backwards from today
            for i in 0..<daysBack {
                guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = (i == 0) ? now : calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                
                let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
                
                @Sendable func fetchSum(for typeIdentifier: HKQuantityTypeIdentifier) async -> Double {
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
                let burned = a + b
                
                historicalData.append((date: startOfDay, intake: d, burned: burned, net: d - burned))
            }
            
            return historicalData.sorted { $0.date < $1.date }
        }
    
    // MARK: - 🔋 PREVIOUS DAY FUEL CHECK
        func fetchYesterdayEnergyBalance() async -> Double {
            let calendar = Calendar.current
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return 0 }
            let data = await fetchEnergyBalance(_for: yesterday) // Ensure your fetchEnergyBalance accepts a date!
            return data.net
        }
    
    // MARK: - 🔋 THERMODYNAMIC ENGINE
        
        /// Calculates the net energy balance (Intake - Total Burn) for the current day.
    func fetchEnergyBalance(_for: Date = Date()) async -> (intake: Double, burned: Double, net: Double) {
            let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: _for)
            
            // Predicate for "Today"
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: _for, options: .strictStartDate)
            
            // Internal helper to sum calories for a specific type
            @Sendable func fetchSum(for typeIdentifier: HKQuantityTypeIdentifier) async -> Double {
                guard let type = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else { return 0.0 }
                
                return await withCheckedContinuation { continuation in
                    let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                        let sum = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0.0
                        continuation.resume(returning: sum)
                    }
                    healthStore.execute(query)
                }
            }
            
            // Execute concurrent fetches
            async let activeBurn = fetchSum(for: .activeEnergyBurned)
            async let basalBurn = fetchSum(for: .basalEnergyBurned)
            async let dietaryIntake = fetchSum(for: .dietaryEnergyConsumed)
            
            let (active, basal, intake) = await (activeBurn, basalBurn, dietaryIntake)
            
            let totalBurned = active + basal
            let netBalance = intake - totalBurned
            
            return (intake: intake, burned: totalBurned, net: netBalance)
        }
    
    
}

// MARK: - 📈 KINETIC TELEMETRY (SCALARS & VECTORS)
// ✨ THE MISSING CODE: This handles all the Heart Rate, Power, and Cadence fetching!
extension HealthKitManager {
    
    // --- 1. SCALAR FETCHERS (For the Grid) ---
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
            // Running Cadence (Steps per minute)
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
    
    // --- 2. VECTOR FETCHERS (For the Charts) ---
    private func fetchTimeSeriesData(identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, durationMinutes: Double) async -> [(date: Date, value: Double)] {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return [] }
        let end = Calendar.current.date(byAdding: .second, value: Int(durationMinutes * 60), to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: quantityType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)],
            limit: HKObjectQueryNoLimit // Pull the entire array
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
                // CYCLING: Natively stored as RPM (Revolutions Per Minute)
                return await fetchTimeSeriesData(
                    identifier: .cyclingCadence,
                    unit: HKUnit.count().unitDivided(by: .minute()),
                    start: start,
                    durationMinutes: durationMinutes
                )
            } else {
                // RUNNING: Natively stored as raw step counts. We must convert to SPM.
                guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return [] }
                let end = Calendar.current.date(byAdding: .second, value: Int(durationMinutes * 60), to: start)!
                let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
                
                let descriptor = HKSampleQueryDescriptor(
                    predicates: [.quantitySample(type: stepType, predicate: predicate)],
                    sortDescriptors: [SortDescriptor(\.startDate, order: .forward)],
                    limit: HKObjectQueryNoLimit
                )
                
                guard let results = try? await descriptor.result(for: healthStore) else { return [] }
                
                // Map the raw step packets into an SPM Vector Array
                return results.compactMap { sample in
                    let steps = sample.quantity.doubleValue(for: .count())
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    
                    guard duration > 0 else { return nil } // Prevent division by zero
                    
                    let spm = (steps / duration) * 60.0
                    return (date: sample.startDate, value: spm)
                }
            }
        }
}
// MARK: - 🕰️ HISTORICAL TELEMETRY ENGINE (30-DAY BACKFILL)
extension HealthKitManager {
    
    /// Scrapes HealthKit for daily biometric averages over a specified number of days in the past.
    func fetchHistoricalBiometrics(daysBack: Int = 30) async -> [(date: Date, hrv: Double, restingHR: Double, sleepHours: Double)] {
        var historicalData: [(Date, Double, Double, Double)] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        
        // Loop backward sequentially to respect HealthKit thread limits
        for dayOffset in 1...daysBack {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            let startOfDay = targetDate
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            let sleepStart = calendar.date(byAdding: .hour, value: -12, to: startOfDay)! // Look back to previous evening
            
            // Concurrently fetch the 3 core pillars of readiness for that specific date
            async let hrv = fetchQuantity(type: .heartRateVariabilitySDNN, start: startOfDay, end: endOfDay, unit: HKUnit.secondUnit(with: .milli))
            async let rhr = fetchQuantity(type: .restingHeartRate, start: startOfDay, end: endOfDay, unit: HKUnit.count().unitDivided(by: HKUnit.minute()))
            async let sleep = fetchSleepDuration(start: sleepStart, end: endOfDay)
            
            let metrics = await (hrv, rhr, sleep)
            
            // Only append if we have actual data (prevents zeroing out days you didn't wear a watch)
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
    
    // MARK: - ⚙️ PRIVATE GENERIC FETCHERS
    
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
// MARK: - 📤 TWO-WAY SYNC (WRITE TO APPLE HEALTH)
extension HealthKitManager {
    
    /// Pushes a manually logged Mission directly into the Apple Fitness/Health ecosystem
    // MARK: - 📤 TWO-WAY SYNC (WRITE TO APPLE HEALTH)
        
        /// Pushes a manually logged Mission directly into the Apple Fitness/Health ecosystem
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
            
            // 1. Begin Collection (Bridged to Async)
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                builder.beginCollection(withStart: start) { success, error in
                    if let error = error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: ()) }
                }
            }
            
            // 2. Add Distance
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
            
            // 3. Add Average HR
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
            
            // 4. Inject Metadata (Bridged to Async)
            var metadata: [String: Any] = [HKMetadataKeyTimeZone: TimeZone.current.identifier]
            if !notes.isEmpty {
                metadata["DragsterOS_Debrief"] = notes
            }
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                builder.addMetadata(metadata) { success, error in
                    if let error = error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: ()) }
                }
            }
            
            // 5. End Collection (Bridged to Async)
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                builder.endCollection(withEnd: end) { success, error in
                    if let error = error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: ()) }
                }
            }
            
            // 6. Finish Workout (Bridged to Async)
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                builder.finishWorkout { workout, error in
                    if let error = error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: ()) }
                }
            }
        }
}

