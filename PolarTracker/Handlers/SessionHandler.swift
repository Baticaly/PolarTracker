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
    @Published var sessions: [BLESession] = []
    @Published var currentSession: BLESession?

    init() {
        loadSessionsFromFile()
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }

    func startSession() {
        currentSession = BLESession(startTime: Date(), endTime: nil, packets: [])
    }

    func endSession() {
        currentSession?.endTime = Date()
        if let session = currentSession {
            sessions.append(session)
        }
        currentSession = nil

        saveSessionsToFile()
    }

    func addPacketData(_ locationData: CLLocationCoordinate2D, altitude: Double, speed: Double, satellites: Int, environment: EnvironmentData, health: HealthData) {
        let codableLocationData = CodableCLLocationCoordinate2D(from: locationData)
        let packet = Packet(time: getCurrentTime(), location: codableLocationData, altitude: altitude, speed: speed, satellites: satellites, environment: environment, health: health)
        currentSession?.packets.append(packet)
    }

    func saveSessionsToFile() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("sessions.json")

        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: fileURL)
        } catch {
            print("Error saving sessions: \(error)")
        }
    }

    func loadSessionsFromFile() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("sessions.json")

        do {
            let data = try Data(contentsOf: fileURL)
            sessions = try JSONDecoder().decode([BLESession].self, from: data)
        } catch {
            print("Error loading sessions: \(error)")
            if (error as NSError).domain == NSCocoaErrorDomain && (error as NSError).code == NSFileReadNoSuchFileError {
                print("No previous sessions found")
            }
        }
    }

    func exportSession(_ session: BLESession) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(session)
            return data
        } catch {
            print("Error encoding session: \(error)")
            return nil
        }
    }

    func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }

    func fileSize(of session: BLESession) -> String {
        if let data = exportSession(session) {
            let byteCount = data.count
            // Convert to Kilobytes
            let kilobytes = Double(byteCount) / 1024.0
            return String(format: "%.2f KB", kilobytes)
        }
        return "Unknown size"
    }

    @objc func appWillResignActive() {
        endSession()
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