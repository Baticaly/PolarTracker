//
//  ConnectDeviceView.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 10/11/23.
//

import SwiftUI

struct ConnectDeviceView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    var body: some View {
        VStack {
            if bleManager.isConnected {
                if let connectedPeripheralName = bleManager.connectedPeripheralName {
                    Text("Connected to: \(connectedPeripheralName)")
                        .font(.title)
                        .padding()
                }
            } else {
                Text("Disconnected")
                    .font(.title)
                    .padding()
            }
            
            List(bleManager.discoveredPeripherals, id: \.self) { peripheral in
                Button(action: {
                    bleManager.connect(to: peripheral)
                }) {
                    Text(peripheral.name ?? "Unnamed")
                }
            }
            
            Button("Scan for BLE Devices") {
                bleManager.startBLEConnection()
            }
            .padding()
        }
        .navigationBarTitle("Connect a Device")
    }
}