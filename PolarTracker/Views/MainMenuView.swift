//
//  MainMenuView.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 10/11/23.
//

import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var bleManager: BLEManager

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: ConnectDeviceView()) {
                    Text("Connect a Device")
                }
                NavigationLink(destination: ShowLocationView()) {
                    Text("Show Location")
                }
                NavigationLink(destination: ShowDetailsView()) {
                    Text("Show Details")
                }
            }
            .navigationBarTitle("Main Menu")
            .navigationBarItems(trailing: Text(bleManager.isConnected ? "Connected to: \(bleManager.connectedPeripheralName ?? "Unnamed")" : "Disconnected"))
        }
    }
}