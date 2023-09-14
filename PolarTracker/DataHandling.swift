//
//  DataHandling.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 14/09/23.
//

import Foundation
import SwiftUI

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
    
    func extractHourData(from message: String) -> String {
        let components = message.components(separatedBy: " | ")
        if components.count > 0 {
            let hourInfo = components[0]
            return hourInfo
        } else {
            return "N/A"
        }
    }
    
    func extractLocationData(from message: String) -> String {
        let components = message.components(separatedBy: " | ")
        if components.count > 0 {
            let locationInfo = components[1]
            return locationInfo
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
