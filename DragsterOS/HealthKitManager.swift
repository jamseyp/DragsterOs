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
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.workoutType(),
            // ✨ THE MISSING PERMISSIONS: You MUST request these to get the data!
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .runningPower)!,
            HKObjectType.quantityType(forIdentifier: .cyclingPower)!,
            HKObjectType.quantityType(forIdentifier: .cyclingCadence)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!
        ]
        
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
        
        await MainActor.run {
            self.isAuthorized = true
        }
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
