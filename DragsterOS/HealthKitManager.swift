// HealthKitManager.swift
import HealthKit
import Foundation

class HealthKitManager: ObservableObject {
    // 1. Mark the store as private to protect the data layer
    private let healthStore = HKHealthStore()
    
    @Published var latestHR: Double = 0
    @Published var latestHRV: Double = 0
    @Published var sensorName: String = "Detecting..."
    
    func requestAuthorization() {
        // 2. Safely unwrap the quantity types
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return
        }
        
        let typesToRead: Set = [hrType, hrvType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                self.fetchLatestHeartRate()
            } else if let error = error {
                print("System Error: Authorization denied. \(error.localizedDescription)")
            }
        }
    }

    func fetchLatestHeartRate() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: hrType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, results, _ in
            guard let self = self,
                  let sample = results?.first as? HKQuantitySample else { return }
            
            let unit = HKUnit(from: "count/min")
            let value = sample.quantity.doubleValue(for: unit)
            let source = sample.sourceRevision.source.name
            
            // 3. Ensure UI updates happen on the main thread safely
            DispatchQueue.main.async {
                self.latestHR = value
                self.sensorName = source
            }
        }
        healthStore.execute(query)
    }
}
