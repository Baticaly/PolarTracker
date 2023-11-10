//
//  PolarTrackerApp.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 14/09/23.
//

import SwiftUI

@main
struct PolarTrackerApp: App {
    @StateObject var bleManager = BLEManager()

    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environmentObject(bleManager)
        }
    }
}