//
//  InteractiveAds_vioApp.swift
//  InteractiveAds-vio
//
//  Created by Angelo Sepulveda on 04/03/2026.
//

import SwiftUI
import CoreData

@main
struct InteractiveAds_vioApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
