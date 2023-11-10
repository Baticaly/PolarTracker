//
//  DataHandling.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 14/09/23.
//

import Foundation
import SwiftUI
import CoreLocation

struct MessageData: Codable {
    let sender: Int
    let recipient: Int
    let message: String
    let SNR: Double
    let RSSI: Int
    let FreqErr: Int
}

class DataHandling: ObservableObject {
    
    func parseAndProcessValue(_ value: String) {
        print("Received value from BLE: \(value)")
        // {"sender":1, "recipient":255, "message":"19:42:58 | 0.000000,0.000000 | 0.00,0.00,0 | 19.45,74.55,19.12,72.39,1005.47,65.08 | 0,0,0", "SNR":9.75, "RSSI":-33, "FreqErr":662}

        if let jsonData = value.data(using: .utf8) {
            do {
                let messageData = try JSONDecoder().decode(MessageData.self, from: jsonData)
            } catch {
                print("Error decoding JSON data: \(error)")
            }
        }
        
    }

    func extractTime(from message: String) -> String {
        let components = message.components(separatedBy: " | ")
        if components.count > 0 {
            let timeInfo = components[0]
            return timeInfo
        } else {
            return "N/A"
        }
    }
    
    func parseLocationString(_ locationString: String) -> CLLocationCoordinate2D? {
        // Split the locationString by comma to get latitude and longitude strings
        let components = locationString.components(separatedBy: ",")
        
        // Trim whitespace characters from latitude and longitude components
        let trimmedLatitude = components[0].trimmingCharacters(in: .whitespaces)
        let trimmedLongitude = components[1].trimmingCharacters(in: .whitespaces)
        
        // Attempt to convert trimmed latitude and longitude components to Double
        guard let latitude = Double(trimmedLatitude), let longitude = Double(trimmedLongitude) else {
            return nil
        }
        
        // Create a CLLocationCoordinate2D instance
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        return coordinate
    }

    func extractAltitudeSpeedSatellites(from message: String) -> (Double, Double, Int)? {
        let components = message.components(separatedBy: " | ")
        if components.count > 2 {
            let subComponents = components[2].components(separatedBy: ",")
            if subComponents.count == 3,
            let altitude = Double(subComponents[0]),
            let speed = Double(subComponents[1]),
            let satellites = Int(subComponents[2]) {
                return (altitude, speed, satellites)
            }
        }
        return nil
    }

    func extractEnvironmentData(from message: String) -> (Double, Double, Double, Double, Double, Double)? {
        let components = message.components(separatedBy: " | ")
        if components.count > 3 {
            let subComponents = components[3].components(separatedBy: ",")
            if subComponents.count == 6,
            let temperature = Double(subComponents[0]),
            let humidity = Double(subComponents[1]),
            let externalTemperature = Double(subComponents[2]),
            let externalHumidity = Double(subComponents[3]),
            let pressure = Double(subComponents[4]),
            let approxAltitude = Double(subComponents[5]) {
                return (temperature, humidity, externalTemperature, externalHumidity, pressure, approxAltitude)
            }
        }
        return nil
    }

    func extractHealthData(from message: String) -> (Int, Int, Int)? {
        let components = message.components(separatedBy: " | ")
        if components.count > 4 {
            let subComponents = components[4].components(separatedBy: ",")
            if subComponents.count == 3,
            let heartrateValueLast = Int(subComponents[0]),
            let fallDetected = Int(subComponents[1]),
            let buttonPressed = Int(subComponents[2]) {
                return (heartrateValueLast, fallDetected, buttonPressed)
            }
        }
        return nil
    }
}
