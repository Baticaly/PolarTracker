//
//  ShowDetailsView.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 10/11/23.
//

import SwiftUI
import MapKit

struct ShowDetailsView: View {
    @EnvironmentObject var bleManager: BLEManager

    var body: some View {
        ScrollView {
            VStack {
                ConnectionStatusCard(bleManager: bleManager)
                LocationDataCard(bleManager: bleManager)
                EnvironmentDataCard(bleManager: bleManager)
                HealthDataCard(bleManager: bleManager)
            }
            .frame(maxWidth: .infinity) // Make the VStack fill the available width
            .padding()
        }
        .frame(maxWidth: .infinity) // Make the VStack fill the available width
        .navigationBarTitle("Show Details")
    }
}

struct ConnectionStatusCard: View {
    @ObservedObject var bleManager: BLEManager

    var body: some View {
        VStack(alignment: .leading) {
            Text("Connection Status")
                .font(.headline)
            Text(bleManager.isConnected ? "Connected" : "Disconnected")
                .font(.title3)
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Align text to the left
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct LocationDataCard: View {
    @ObservedObject var bleManager: BLEManager

    var body: some View {
        VStack(alignment: .leading) {
            Text("Location Data")
                .font(.headline)
            Text("Latitude: \(bleManager.locationData.latitude)")
                .font(.title3)
            Text("Longitude: \(bleManager.locationData.longitude)")
                .font(.title3)
            Text("Altitude: \(bleManager.altitudeData)")
                .font(.title3)
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Align text to the left
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct EnvironmentDataCard: View {
    @ObservedObject var bleManager: BLEManager

    var body: some View {
        VStack(alignment: .leading) {
            Text("Environment Data")
                .font(.headline)
            if let environmentData = bleManager.environmentData {
                Text("Temperature: \(String(format: "%.2f", environmentData.temperature))°C")
                    .font(.title3)
                Text("Humidity: \(String(format: "%.2f", environmentData.humidity))%")
                    .font(.title3)
                Text("External Temperature: \(String(format: "%.2f", environmentData.externalTemperature))°C")
                    .font(.title3)
                Text("External Humidity: \(String(format: "%.2f", environmentData.externalHumidity))%")
                    .font(.title3)
                Text("Pressure: \(String(format: "%.2f", environmentData.pressure))")
                    .font(.title3)
                Text("Approx Altitude: \(String(format: "%.2f", environmentData.approxAltitude))")
                    .font(.title3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Align text to the left
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct HealthDataCard: View {
    @ObservedObject var bleManager: BLEManager

    var body: some View {
        VStack(alignment: .leading) {
            Text("Health Data")
                .font(.headline)
            if let healthData = bleManager.healthData {
            Text("Last Heart Rate Value: \(healthData.heartrateValueLast)")
                .font(.title3)
            Text("Fall Detected: \(healthData.fallDetected)")
                .font(.title3)
            Text("Button Pressed: \(healthData.buttonPressed)")
                .font(.title3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Align text to the left
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}