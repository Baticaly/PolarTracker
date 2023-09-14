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
}

class DataHandling: ObservableObject {
    
    func parseAndProcessValue(_ value: String) {
        //print("Received value from BLE: \(value)")
        
        if let jsonData = value.data(using: .utf8) {
            do {
                let messageData = try JSONDecoder().decode(MessageData.self, from: jsonData)
            } catch {
                print("Error decoding JSON data: \(error)")
            }
        }
        
    }
    
    func parseLocationString(_ locationString: String) -> CLLocationCoordinate2D? {
        // Split the locationString by comma to get latitude and longitude strings
        let components = locationString.components(separatedBy: ",")
        
        // Ensure there are two components (latitude and longitude)
        guard components.count == 2 else {
            return nil
        }
        
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


    
    func extractHourData(from message: String) -> String {
        let components = message.components(separatedBy: " | ")
        if components.count > 0 {
            let hourInfo = components[0]
            return hourInfo
        } else {
            return "N/A"
        }
    }
    
    func extractMiscData(from message: String) -> String {
        let components = message.components(separatedBy: ",")
        if components.count > 0 {
            let miscInfo = components[2]
            return miscInfo
        } else {
            return "N/A"
        }
    }
}
