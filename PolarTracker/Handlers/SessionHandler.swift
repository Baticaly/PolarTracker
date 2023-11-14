//
//  SessionHandler.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 11/11/23.
//

import Foundation
import CoreLocation
import UIKit

struct EnvironmentData: Codable {
    var temperature: Double = 0.0
    var humidity: Double = 0.0
    var externalTemperature: Double = 0.0
    var externalHumidity: Double = 0.0
    var pressure: Double = 0.0
    var approxAltitude: Double = 0.0

    var description: String {
        return "Temperature: \(temperature), Humidity: \(humidity), External Temperature: \(externalTemperature), External Humidity: \(externalHumidity), Pressure: \(pressure), Approx Altitude: \(approxAltitude)"
    }
}

struct HealthData: Codable {
    var heartrateValueLast: Int = 0
    var fallDetected: Int = 0
    var buttonPressed: Int = 0

    var description: String {
        return "Heartrate Value Last: \(heartrateValueLast), Fall Detected: \(fallDetected), Button Pressed: \(buttonPressed)"
    }
}

struct Packet: Codable {
    var time: String
    var location: CodableCLLocationCoordinate2D
    var altitude: Double
    var speed: Double
    var satellites: Int
    var environment: EnvironmentData
    var health: HealthData

    init(time: String, location: CodableCLLocationCoordinate2D, altitude: Double, speed: Double, satellites: Int, environment: EnvironmentData, health: HealthData) {
        self.time = time
        self.location = location
        self.altitude = altitude
        self.speed = speed
        self.satellites = satellites
        self.environment = environment
        self.health = health
    }
}

struct BLESession: Codable {
    let startTime: Date
    var endTime: Date?
    var packets: [Packet]

    var path: [CLLocationCoordinate2D] {
        return packets.map { $0.location.clLocationCoordinate2D }
    }
}

class SessionHandler: ObservableObject {
    @Published var currentSession: BLESession?

    var sessions = [BLESession]() {
        didSet {
            saveSessionsToFile()
        }
    }

    init() {
        loadSessionsFromFile()
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    func saveSessionsToFile() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(sessions) {
            let url = getDocumentsDirectory().appendingPathComponent("sessions.json")
            try? encoded.write(to: url)
        }
    }

    func loadSessionsFromFile() {
        let url = getDocumentsDirectory().appendingPathComponent("sessions.json")
        if let data = try? Data(contentsOf: url) {
            let decoder = JSONDecoder()
            if let loadedSessions = try? decoder.decode([BLESession].self, from: data) {
                self.sessions = loadedSessions
            }
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func startSession() {
        currentSession = BLESession(startTime: Date(), packets: [])
    }

    func addPacketData(_ locationData: CLLocationCoordinate2D, altitude: Double, speed: Double, satellites: Int, environment: EnvironmentData, health: HealthData) {
        let codableLocationData = CodableCLLocationCoordinate2D(from: locationData)
        let packet = Packet(time: getCurrentTime(), location: codableLocationData, altitude: altitude, speed: speed, satellites: satellites, environment: environment, health: health)
        currentSession?.packets.append(packet)
    }

    func endSession() {
        currentSession?.endTime = Date()
        if let currentSession = currentSession {
            sessions.append(currentSession)
        }
        currentSession = nil
    }

    func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }

    func fileSize(of session: BLESession) -> String {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(session) {
            let byteCount = data.count
            // bytes
            if byteCount < 1023 {
                return "\(byteCount) B"
            }
            // kilobytes
            let kiloByteCount = Double(byteCount) / 1024.0
            if kiloByteCount < 1023 {
                return String(format: "%.2f KB", kiloByteCount)
            }
            // megabytes
            let megaByteCount = kiloByteCount / 1024.0
            return String(format: "%.2f MB", megaByteCount)
        } else {
            return "Calculating..."
        }
    }

    func exportSessionAsCSV(_ session: BLESession) -> String? {
        var csvString = "Time,Latitude,Longitude,Altitude,Speed,Satellites,Temperature,Humidity,External Temperature,External Humidity,Pressure,Approx Altitude,Heart Rate,Fall Detected,Button Pressed\n"
        for packet in session.packets {
            let line = "\(packet.time),\(packet.location.latitude), \(packet.location.longitude),\(packet.altitude),\(packet.speed),\(packet.satellites),\(packet.environment.temperature),\(packet.environment.humidity),\(packet.environment.externalTemperature),\(packet.environment.externalHumidity),\(packet.environment.pressure),\(packet.environment.approxAltitude),\(packet.health.heartrateValueLast),\(packet.health.fallDetected),\(packet.health.buttonPressed)\n"
            csvString += line
        }
        return csvString
    }

    @objc func appWillResignActive() {
        endSession()
    }

    @objc func appDidEnterBackground() {
        endSession()
        saveSessionsToFile()
    }
}

struct CodableCLLocationCoordinate2D: Codable, Hashable, Identifiable {
    let id = UUID()
    var latitude: Double
    var longitude: Double

    var clLocationCoordinate2D: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(from coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}