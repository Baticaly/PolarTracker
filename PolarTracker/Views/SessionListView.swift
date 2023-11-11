//
//  SessionListView.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 11/11/23.
//

import SwiftUI

struct SessionListView: View {
    @EnvironmentObject var bleManager: BLEManager

    var body: some View {
        List {
            ForEach(bleManager.sessionHandler.sessions, id: \.startTime) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    VStack(alignment: .leading) {
                        Text("Session started at \(session.startTime)")
                        Text("Session ended at \(session.endTime ?? Date())")
                        ExportButton(session: session)
                            .environmentObject(bleManager)
                    }
                }
            }
            .onDelete(perform: deleteSession)
        }
        .navigationBarTitle("Saved Sessions")
    }

    private func deleteSession(at offsets: IndexSet) {
        bleManager.sessionHandler.sessions.remove(atOffsets: offsets)
    }
}

struct SessionDetailView: View {
    var session: BLESession

    var body: some View {
        List {
            ForEach(session.packets, id: \.time) { packet in
                VStack(alignment: .leading) {
                    Text("Time: \(packet.time)")
                    Text("Latitude: \(String(format: "%.2f", packet.location.latitude)), Longitude: \(String(format: "%.2f", packet.location.longitude))")
                    Text("Altitude: \(String(format: "%.2f", packet.altitude))")
                    Text("Speed: \(String(format: "%.2f", packet.speed))")
                    Text("Satellites: \(packet.satellites)")
                    Text("Environment Data: \(packet.environment.description)")
                    Text("Health Data: \(packet.health.description)")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.bottom, 10)
            }
        }
        .navigationBarTitle("Session Details", displayMode: .inline)
    }
}

struct ExportButton: View {
    @EnvironmentObject var bleManager: BLEManager
    var session: BLESession

    var body: some View {
        Button(action: {
            if let data = bleManager.sessionHandler.exportSession(session) {
                let filename = "session.json"
                let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                do {
                    try data.write(to: tmpURL)
                    let documentPicker = UIDocumentPickerViewController(forExporting: [tmpURL])
                    UIApplication.shared.windows.first?.rootViewController?.present(documentPicker, animated: true)
                } catch {
                    print("Error writing session to file: \(error)")
                }
            }
        }) {
            Text("Export Session")
        }
    }
}