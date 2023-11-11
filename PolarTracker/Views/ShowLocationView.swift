//
//  ShowLocationView.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 10/11/23.
//

import SwiftUI
import MapKit

struct ShowLocationView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var annotations: [MKPointAnnotation] = []
    @State private var polyline: MKPolyline? = nil
    @State private var recentCoordinate: CLLocationCoordinate2D?
    @State private var selectedSession: BLESession?
    @State private var shouldZoomIn = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var sessions: [BLESession]

    private func updateMapViewForSession() {
        let currentSession = selectedSession ?? bleManager.sessionHandler.currentSession
        if let currentSession = currentSession {
            let allPackets = currentSession.packets
            if let lastPacket = allPackets.last {
                let annotation = MKPointAnnotation()
                annotation.coordinate = lastPacket.location.clLocationCoordinate2D
                annotations = [annotation]
            }
            let coordinates = allPackets.map { $0.location.clLocationCoordinate2D }
            polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        }
    }

    var body: some View {
        ZStack {
            MapView(annotations: $annotations, polyline: $polyline, recentCoordinate: $recentCoordinate, shouldZoomIn: $shouldZoomIn)
                .ignoresSafeArea(.all) // Make the map full screen
                .onAppear {
                    updateMapViewForSession()
                }
                .onChange(of: bleManager.sessionHandler.currentSession?.packets) { _ in
                    updateMapViewForSession()
                }
                .onChange(of: selectedSession) { _ in
                    updateMapViewForSession()
                }
            
            VStack {
                HStack {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left") // use arrow.left for a different arrow style
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 10)
                    .padding(.top, 10)
                    
                    Spacer()

                    Button(action: {
                        if let lastPacket = sessions.flatMap({ $0.packets }).last {
                            recentCoordinate = lastPacket.location.clLocationCoordinate2D
                            shouldZoomIn = true
                        }
                    }) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.top, 10)
                    .padding(.trailing, 10)
                }
                
                Spacer()

                Picker("Select Session", selection: $selectedSession) {
                Text("Live").tag(nil as BLESession?)
                ForEach(sessions, id: \.self) { session in
                    Text("\(session.startTime)").tag(session as BLESession?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .foregroundColor(.black) // Change the text color to black
            .background(Color.white.opacity(0.3)) // Add a white background with 0.3 opacity
            .cornerRadius(10) // Make the corners of the background card rounded
            .padding(.horizontal, 10) // Add horizontal padding to the Picker
            .padding(.bottom, 10) // Add bottom padding to the Picker
            }
        }
        .navigationBarHidden(true) // Hide navigation bar
    }
}

struct MapView: UIViewRepresentable {
    @Binding var annotations: [MKPointAnnotation]
    @Binding var polyline: MKPolyline?
    @Binding var recentCoordinate: CLLocationCoordinate2D?
    @Binding var shouldZoomIn: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        uiView.addAnnotations(annotations)
        if let polyline = polyline {
            uiView.addOverlay(polyline)
        }
        if let recentCoordinate = recentCoordinate, shouldZoomIn {
            setRegion(recentCoordinate, in: uiView)
            DispatchQueue.main.async {
                shouldZoomIn = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func setRegion(_ coordinate: CLLocationCoordinate2D, in mapView: MKMapView) {
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

extension Packet: Equatable {
    static func == (lhs: Packet, rhs: Packet) -> Bool {
        // Compare the properties that uniquely identify a packet
        return lhs.time == rhs.time && lhs.location == rhs.location
    }
}

extension BLESession: Hashable {
    static func == (lhs: BLESession, rhs: BLESession) -> Bool {
        // Compare the properties that uniquely identify a BLESession
        return lhs.startTime == rhs.startTime // replace with your own comparison
    }

    func hash(into hasher: inout Hasher) {
        // Include the properties that uniquely identify a BLESession
        hasher.combine(startTime) // replace with your own properties
    }
}