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
        List {
            ForEach(session.packets, id: \.time) { packet in
                VStack(alignment: .leading) {
                    Text(String(describing: packet))
                }
                .font(.system(size: 8, design: .monospaced))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .navigationBarTitle("Session Details", displayMode: .inline)
        .navigationBarItems(trailing: ExportButton(session: session).environmentObject(bleManager))
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
            Image(systemName: "square.and.arrow.up") // System symbol for 'Share'
        }
    }
}