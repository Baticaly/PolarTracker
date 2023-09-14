//
//  ContentView.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 14/09/23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var bleManager = BLEManager()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Connected Status: \(bleManager.isConnected ? "Connected" : "Disconnected")")
                    .font(.title3)
                    .padding()
                
                Text("Characteristic Value: \(bleManager.characteristicValue)")
                    .font(.title3)
                    .padding()
                
                Text("Location: \(bleManager.locationData)")
                    .font(.title3)
                    .padding()
                
                List(bleManager.discoveredPeripherals, id: \.self) { peripheral in
                    Button(action: {
                        bleManager.connect(to: peripheral)
                    }) {
                        Text(peripheral.name ?? "Unnamed")
                    }
                }
                .padding()
                Text("GPS Clock: \(bleManager.hourData)")
                    .font(.title.bold())
                    .padding()
                
                Button("Scan for BLE Devices") {
                    bleManager.startBLEConnection()
                }
                .padding()
            }
            .navigationBarTitle("BLE Device List")
            }
        }
    }
