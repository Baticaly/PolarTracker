//
//  SessionListView.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 11/11/23.
//

import SwiftUI

struct SessionListView: View {
    @EnvironmentObject var bleManager: BLEManager
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        List {
            ForEach(bleManager.sessionHandler.sessions, id: \.startTime) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    VStack(alignment: .leading) {
                        let formattedStartTime = formatter.string(from: session.startTime)
                        let formattedEndTime = formatter.string(from: session.endTime ?? Date())
                        let fileSize = bleManager.sessionHandler.fileSize(of: session)
                        Text("Session started at \(formattedStartTime)")
                        Text("Session ended at \(formattedEndTime)")
                        Text("Size: \(fileSize)")
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
    @EnvironmentObject var bleManager: BLEManager
    var session: BLESession

    var body: some View {
        ScrollView {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Time").frame(width: 70, alignment: .leading)
                        Divider()
                        Text("Location").frame(width: 160, alignment: .leading)
                        Divider()
                        Text("Temperature").frame(width: 130, alignment: .leading)
                        Divider()
                        Text("Humidity %").frame(width: 130, alignment: .leading)
                        Divider()
                        Text("Pressure (hPa)").frame(width: 70, alignment: .leading)
                    }
                    .font(.headline)
                    .padding()

                    ForEach(Array(session.packets.prefix(100).enumerated()), id: \.offset) { index, packet in
                        ScrollView(.horizontal, showsIndicators: false) {
                            PacketRowView(packet: packet)
                                .padding()
                        }
                    }
                }
            }
        }
        .navigationBarTitle("Session Details", displayMode: .inline)
        .navigationBarItems(trailing: ExportButton(session: session).environmentObject(bleManager))
    }
}

struct PacketRowView: View {
    var packet: Packet

    var body: some View {
        HStack {
            Text("\(packet.time)").frame(width: 70, alignment: .leading)
            Divider()
            Text("\(packet.location.latitude), \(packet.location.longitude)").frame(width: 160, alignment: .leading)
            Divider()
            Text("\(String(format: "%.2f", packet.environment.temperature))°C / \(String(format: "%.2f", packet.environment.externalTemperature))°C").frame(width: 130, alignment: .leading)
            Divider()
            Text("\(String(format: "%.2f", packet.environment.humidity))% / \(String(format: "%.2f", packet.environment.externalHumidity))%").frame(width: 130, alignment: .leading)
            Divider()
            Text("\(String(format: "%.2f", packet.environment.pressure)) hPa").frame(width: 70, alignment: .leading)
        }
    }
}

struct ExportButton: View {
    @EnvironmentObject var bleManager: BLEManager
    var session: BLESession

    var body: some View {
        Button(action: {
            if let csvString = bleManager.sessionHandler.exportSessionAsCSV(session) {
                let filename = "session.csv"
                let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                do {
                    try csvString.write(to: tmpURL, atomically: true, encoding: .utf8)
                    let documentPicker = UIDocumentPickerViewController(forExporting: [tmpURL])
                    UIApplication.shared.windows.first?.rootViewController?.present(documentPicker, animated: true)
                } catch {
                    print("Error writing session to file: \(error)")
                }
            }
        }) {
            Image(systemName: "square.and.arrow.up") // System symbol for 'Share'
        }
    }
}