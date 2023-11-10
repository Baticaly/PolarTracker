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
                NavigationLink(destination: ShowLocationView(sessions: bleManager.sessionHandler.sessions)) {
                    Text("Show Location")
                }
                NavigationLink(destination: ShowDetailsView()) {
                    Text("Show Details")
                }
                NavigationLink(destination: SessionListView().environmentObject(bleManager)) {
                    Text("Show Saved Sessions")
                }
            }
            .navigationBarTitle("Main Menu")
            .navigationBarItems(trailing: Text(bleManager.isConnected ? "Connected to: \(bleManager.connectedPeripheralName ?? "Unnamed")" : "Disconnected"))
        }
    }
}