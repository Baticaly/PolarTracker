//
//  DataHandling.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 14/09/23.
//

import Foundation
struct SensorData: Codable {
    let sender: String
    let recipient: String
    let message: String
    let SNR: String
    let RSSI: String
    let FreqErr: String
}

