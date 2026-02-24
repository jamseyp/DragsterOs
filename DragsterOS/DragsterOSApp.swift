//
//  DragsterOSApp.swift
//  DragsterOS
//
//  Created by James Parker on 23/02/2026.
//

import SwiftUI

@main
struct DragsterOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
            WindowGroup {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
}
