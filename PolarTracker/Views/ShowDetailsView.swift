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
    @State private var lockRegionToLocationData = false // Track lock button state
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.0, longitude: 34.0),
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )
    
    var body: some View {
        VStack {
            Text("Connection Status: \(bleManager.isConnected ? "Connected" : "Disconnected")")
                .font(.title3)
            
            VStack{
                Text("Time: \(bleManager.timeData)").font(.title3)
                Text("Latitude: \(bleManager.locationData.latitude)").font(.title3)
                Text("Longitude: \(bleManager.locationData.longitude)").font(.title3)
                Text("Altitude: \(bleManager.altitudeData)").font(.title3)
                Text("Speed: \(bleManager.speedData)").font(.title3)
                Text("Satellites: \(bleManager.satellitesData)").font(.title3)
                if let (temperature, humidity, externalTemperature, externalHumidity, pressure, approxAltitude) = bleManager.environmentData {
                    Text("Temperature: \(temperature)").font(.title3)
                    Text("Humidity: \(humidity)").font(.title3)
                    Text("External Temperature: \(externalTemperature)").font(.title3)
                    Text("External Humidity: \(externalHumidity)").font(.title3)
                    Text("Pressure: \(pressure)").font(.title3)
                    Text("Approx Altitude: \(approxAltitude)").font(.title3)
                }
                if let (heartrateValueLast, fallDetected, buttonPressed) = bleManager.healthData {
                    Text("Last Heart Rate Value: \(heartrateValueLast)").font(.title3)
                    Text("Fall Detected: \(fallDetected)").font(.title3)
                    Text("Button Pressed: \(buttonPressed)").font(.title3)
                }
            }
            
            // Text indicating GPS Lock status
            Text("GPS Clock: \(bleManager.timeData)")
                .font(.title.bold())
                .padding()
        }
        .navigationBarTitle("Show Details")
    }
}