import Foundation
import HealthKit
import Observation

// 📐 ARCHITECTURE: Using Swift 5.9+ @Observable for seamless UI reactivity.
// This manager operates entirely asynchronously, ensuring the main UI thread
// remains at a locked 120fps (ProMotion) while we crunch the telemetry in the background.

@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    // Track authorization state to adapt the UI if permissions are missing
    var isAuthorized: Bool = false
    
    private init() {}
    
    // MARK: - 🔐 Authorization Protocol
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!, // ⚖️ Structural Mass
            HKObjectType.workoutType() // 🏃‍♂️ Workouts
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!
        ]
        
        // Modern Swift concurrency for requesting access
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
        
        await MainActor.run {
            self.isAuthorized = true
        }
    }
    
    // MARK: - 🧬 Telemetry Extraction (Async Pipeline)
    
    /// Fetches the biometric baseline for the current day
    func fetchMorningReadiness() async throws -> (hrv: Double, restingHR: Double, sleepHours: Double) {
        async let hrv = fetchLatestHRV()
        async let rhr = fetchLatestRestingHR()
        async let sleep = fetchLastNightSleep()
        
        // Await all three asynchronous queries concurrently for maximum performance
        return try await (hrv, rhr, sleep)
    }
    
    // 🫀 HRV Query (Standard Deviation of NN intervals)
    private func fetchLatestHRV() async throws -> Double {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return 0.0 }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: .now), end: .now)
        
        // Utilizing iOS 15+ HKSampleQueryDescriptor for pure async fetching
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: hrvType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        
        let results = try await descriptor.result(for: healthStore)
        guard let sample = results.first else { return 0.0 }
        
        return sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
    }
    
    // 🫀 Resting Heart Rate Query
    private func fetchLatestRestingHR() async throws -> Double {
        guard let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else { return 0.0 }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: .now), end: .now)
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: rhrType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        
        let results = try await descriptor.result(for: healthStore)
        guard let sample = results.first else { return 0.0 }
        
        // RHR is measured in beats per minute (count/min)
        let bpmUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        return sample.quantity.doubleValue(for: bpmUnit)
    }
    
    // 🛌 Sleep Duration Query (Asleep time only)
    private func fetchLastNightSleep() async throws -> Double {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return 0.0 }
        
        // Look back 24 hours to capture last night's sleep
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: .now)
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: []
        )
        
        let results = try await descriptor.result(for: healthStore)
        
        // Filter for actual 'asleep' stages (ignoring 'inBed' or 'awake' periods)
        let asleepSamples = results.filter {
            $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
            $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
            $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
            $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
        }
        
        let totalSleepSeconds = asleepSamples.reduce(0.0) { total, sample in
            total + sample.endDate.timeIntervalSince(sample.startDate)
        }
        
        return totalSleepSeconds / 3600.0 // Convert to hours
    }
    
    // MARK: - ⚖️ Structural Mass Query
    
    func fetchLatestWeight() async throws -> Double {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return 0.0 }
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: weightType)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        
        let results = try await descriptor.result(for: healthStore)
        guard let sample = results.first else { return 0.0 }
        
        return sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
    }
    
    
    // MARK: - ⌚️ Kinetic Output Query
        
        func fetchLatestWorkout() async throws -> HKWorkout? {
            let workoutType = HKObjectType.workoutType()
            
            // We only want to auto-fill workouts from the last 12 hours
            let twelveHoursAgo = Calendar.current.date(byAdding: .hour, value: -12, to: .now)!
            let predicate = HKQuery.predicateForSamples(withStart: twelveHoursAgo, end: .now, options: .strictStartDate)
            
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.sample(type: workoutType, predicate: predicate)],
                sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
                limit: 1
            )
            
            let results = try await descriptor.result(for: healthStore)
            
            // ✨ THE FIX: Explicitly cast the generic HKSample down to an HKWorkout
            return results.first as? HKWorkout
        }
    // MARK: - 📚 Historical Sync Engine
        
        /// Pulls a batch array of workouts over a given time horizon
        func fetchHistoricalWorkouts(daysBack: Int = 30) async throws -> [HKWorkout] {
            let workoutType = HKObjectType.workoutType()
            let startDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: .now)!
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: .now, options: .strictStartDate)
            
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.sample(type: workoutType, predicate: predicate)],
                sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
            )
            
            let results = try await descriptor.result(for: healthStore)
            // Explicitly cast the array of HKSamples to HKWorkouts
            return results.compactMap { $0 as? HKWorkout }
        }
}
