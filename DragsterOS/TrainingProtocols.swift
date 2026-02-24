//
//  TrainingProtocols.swift
//  DragsterOS
//
//  Created by James Parker on 24/02/2026.
//

import Foundation
import SwiftUI

/// 📐 ARCHITECTURAL REASONING:
/// By using a Protocol, your 'MissionView' or 'Dashboard' won't care
/// if the data comes from Core Data (today) or SwiftData (tomorrow).
protocol DisplayableWorkout {
    var title: String { get }
    var targetIntensity: String { get }
    var missionNote: String { get }
    var fuelRequired: String { get }
    var accentColor: Color { get }
}
