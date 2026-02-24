//
//  HealthKitManager.swift
//  DragsterOS
//
//  Created by James Parker on 23/02/2026.
//

import HealthKit
import Foundation
import SwiftUI

class healthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var latestHR: Double = 0
    @Published var latestHRV: Double = 0
    @Published var sensorName: String = "Detecting..."
    
    func requestAuthorization() {
            let typesToRead: Set = [
                HKObjectType.quantityType(forIdentifier: .heartRate)!,
                HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
            ]
            
            healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
                if success {
                    self.fetchLatestHeartRate()
                }
            }
        }

        func fetchLatestHeartRate() {
            let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(sampleType: hrType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
                guard let sample = results?.first as? HKQuantitySample else { return }
                
                let unit = HKUnit(from: "count/min")
                let value = sample.quantity.doubleValue(for: unit)
                
                // This captures WHICH device sent the data (Strap vs Beats)
                let source = sample.sourceRevision.source.name
                
                DispatchQueue.main.async {
                    self.latestHR = value
                    self.sensorName = source
                }
            }
            healthStore.execute(query)
        }
    }
