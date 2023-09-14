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
    @Published var characteristicValue = "No data"
    @Published var discoveredPeripherals: [CBPeripheral] = []
    @Published var isConnected = false
    
    @Published var hourData = "N/A"
    @Published var gpsData = "N/A"
    @Published var locationData = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    
    let dataHandler = DataHandling()
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startBLEConnection() {
        discoveredPeripherals.removeAll()
        let serviceUUID = CBUUID(string: "ab0828b1-198e-4351-b779-901fa0e0371e")
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
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
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(peripheral)")
        isConnected = true
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral)")
        isConnected = false
        centralManager.scanForPeripherals(withServices: nil, options: nil)
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
                            
                            let parsedHourData = self.dataHandler.extractHourData(from: messageData.message)
                            let parsedMiscData = self.dataHandler.extractMiscData(from: messageData.message)
                            
                            let locationString = messageData.message.components(separatedBy: "|")
                            
                            DispatchQueue.main.async {
                                
                                if let parsedLocationData = self.dataHandler.parseLocationString(locationString[1]) {
                                    self.locationData = parsedLocationData
                                } else {
                                    self.locationData = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
                                }
                                
                                self.hourData = parsedHourData
                                self.gpsData = parsedMiscData
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
