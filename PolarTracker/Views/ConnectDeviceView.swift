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
            ConnectionStatusCard(bleManager: bleManager)
            
            if !bleManager.isConnected {
                List(bleManager.discoveredPeripherals, id: \.self) { peripheral in
                    Button(action: {
                        bleManager.connect(to: peripheral)
                    }) {
                        Text(peripheral.name ?? "Unnamed")
                    }
                }
            }

            if bleManager.isConnected {
                Button("Disconnect and Save Session") {
                    bleManager.disconnectCurrentPeripheral()
                    bleManager.sessionHandler.endSession()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Button("Scan for BLE Devices") {
                    bleManager.startBLEConnection()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .navigationBarTitle("BLE Devices")
    }
}