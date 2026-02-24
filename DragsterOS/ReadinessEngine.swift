//
//  ReadinessEngine.swift
//  DragsterOS
//
//  Created by James Parker on 23/02/2026.
//

import Foundation

struct ReadinessEngine {
    // These are the weights we discussed in the "Paddock"
    let hrvWeight = 0.5
    let sleepWeight = 0.3
    let sorenessWeight = 0.2
    
    // This function calculates your "Dragster Score"
    func calculateScore(hrv: Double, sleep: Double, soreness: Double)-> Double {
        // hrv, sleep, and soreness should be normalized 1-10
        let weightedHRV = hrv * hrvWeight
        let weightedSleep = sleep * sleepWeight
        let weightedSoreness = soreness * sorenessWeight
                
        return weightedHRV + weightedSleep + weightedSoreness
    }
}
