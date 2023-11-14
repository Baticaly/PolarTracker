//
//  BLEHandler.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 14/09/23.
//

import Foundation
import CoreBluetooth
import MapKit

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var connectedPeripheralName: String?
    @Published var characteristicValue = "No data"
    @Published var discoveredPeripherals: [CBPeripheral] = []
    @Published var isConnected = false
    
    @Published var locationData = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    @Published var timeData = "N/A"
    @Published var altitudeData: Double = 0.0
    @Published var speedData: Double = 0.0
    @Published var satellitesData: Int = 0
    @Published var environmentData: EnvironmentData?
    @Published var healthData: HealthData?

    @Published var SNRData: Double = 0.0
    @Published var RSSIData: Int = 0
    @Published var FreqErrData: Int = 0

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    
    var sessionHandler = SessionHandler()
    let dataHandler = DataHandling()
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startBLEConnection() {
        discoveredPeripherals.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        sessionHandler.startSession()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on. Scanning for peripherals...")
        default:
            print("Bluetooth is not available or powered off.")
            isConnected = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
        }
    }
    
    func connect(to peripheral: CBPeripheral) {
        centralManager.stopScan()
        self.peripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }

    func disconnectCurrentPeripheral() {
        if let peripheral = self.peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.connectedPeripheralName = peripheral.name
        print("Connected to peripheral: \(peripheral)")
        isConnected = true
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral)")
        isConnected = false
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        sessionHandler.endSession()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                let characteristicUUID = CBUUID(string: "4ac8a682-9736-4e5d-932b-e9b31405049c")
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.properties.contains(.read) {
                    peripheral.readValue(for: characteristic)
                }
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic) // Enable notifications
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            if let value = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.characteristicValue = value
                    self.dataHandler.parseAndProcessValue(value)
                    
                    // Parse Message to components
                    if let jsonData = value.data(using: .utf8) {
                        do {
                            let messageData = try JSONDecoder().decode(MessageData.self, from: jsonData)
                            let locationString = messageData.message.components(separatedBy: "|")
                            self.SNRData = messageData.SNR
                            self.RSSIData = messageData.RSSI
                            self.FreqErrData = messageData.FreqErr
                            
                            DispatchQueue.main.async {
                                if let parsedLocationData = self.dataHandler.parseLocationString(locationString[1]) {
                                    self.locationData = parsedLocationData
                                    self.timeData = self.dataHandler.extractTime(from: messageData.message)
                                    if let (altitude, speed, satellites) = self.dataHandler.extractAltitudeSpeedSatellites(from: messageData.message) {
                                        self.altitudeData = altitude
                                        self.speedData = speed
                                        self.satellitesData = satellites
                                        if let (temp, humidity, extTemp, extHumidity, pressure, approxAltitude) = self.dataHandler.extractEnvironmentData(from: messageData.message) {
                                            let environmentData = EnvironmentData(temperature: temp, humidity: humidity, externalTemperature: extTemp, externalHumidity: extHumidity, pressure: pressure, approxAltitude: approxAltitude)
                                            self.environmentData = environmentData
                                            if let (heartrateValueLast, fallDetected, buttonPressed) = self.dataHandler.extractHealthData(from: messageData.message) {
                                                let healthData = HealthData(heartrateValueLast: heartrateValueLast, fallDetected: fallDetected, buttonPressed: buttonPressed)
                                                self.healthData = healthData
                                                
                                                // Create a new packet with all the data and add it to the current session
                                                self.sessionHandler.addPacketData(parsedLocationData, altitude: altitude, speed: speed, satellites: satellites, environment: environmentData, health: healthData)
                                            }
                                        }
                                    }
                                }
                            }
                            
                        } catch {
                            print("Error decoding JSON data: \(error)")
                        }
                    }
                }
            }
        }
    }
}
