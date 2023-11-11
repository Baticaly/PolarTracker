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
                    CardView(imageName: "rectangle.connected.to.line.below", title: "Connect", description: "Connect to a BLE device.")
                }
                .listRowInsets(EdgeInsets())
                NavigationLink(destination: ShowLocationView(sessions: bleManager.sessionHandler.sessions)) {
                    CardView(imageName: "map.fill", title: "Map", description: "Show the current location.")
                }
                .listRowInsets(EdgeInsets())
                NavigationLink(destination: ShowDetailsView()) {
                    CardView(imageName: "info.circle.fill", title: "Details", description: "Show detailed information.")
                }
                .listRowInsets(EdgeInsets())
                NavigationLink(destination: SessionListView().environmentObject(bleManager)) {
                    CardView(imageName: "doc.text.fill", title: "Saved Sessions", description: "Show previously saved sessions.")
                }
                .listRowInsets(EdgeInsets())
            }
            .navigationBarTitle("Polar Tracker")
            .navigationBarItems(trailing: Text(bleManager.isConnected ? "Connected to: \(bleManager.connectedPeripheralName ?? "Unnamed")" : "Disconnected"))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct CardView: View {
    let imageName: String
    let title: String
    let description: String

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading) {
                HStack {
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: imageName)
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .cornerRadius(10)
        }
    }
}