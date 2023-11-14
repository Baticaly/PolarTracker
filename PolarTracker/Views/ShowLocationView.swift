//
//  ShowLocationView.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 10/11/23.
//

import SwiftUI
import MapKit
import CoreLocation

struct ShowLocationView: View {
    var sessions: [BLESession]

    @EnvironmentObject var bleManager: BLEManager
    @ObservedObject var mapViewModel: MapViewModel
    @State private var recentCoordinate: CLLocationCoordinate2D?
    @State private var selectedSession: BLESession?
    @State private var shouldZoomIn = false
    @State private var showCurrentLocation = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private func updateMapViewForSession() {
        let currentSession = selectedSession ?? bleManager.sessionHandler.currentSession
        if let currentSession = currentSession {
            let allPackets = currentSession.packets
            if let lastPacket = allPackets.last {
                if let node01Annotation = mapViewModel.annotations.first(where: { $0.title == "Node 01" }) {
                    // Update the coordinate of the existing annotation
                    node01Annotation.coordinate = lastPacket.location.clLocationCoordinate2D
                } else {
                    // Create a new annotation if it doesn't exist
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = lastPacket.location.clLocationCoordinate2D
                    annotation.title = "Node 01"
                    annotation.subtitle = lastPacket.environment.description
                    mapViewModel.annotations.append(annotation)
                }
            }
            let coordinates = allPackets.map { $0.location.clLocationCoordinate2D }
            mapViewModel.polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        }
    }

    // Define the date formatter
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d, MMMM 'at' HH:mm"
        return formatter
    }()

    var body: some View {
        ZStack {
            MapView(annotations: $mapViewModel.annotations, polyline: $mapViewModel.polyline, recentCoordinate: $recentCoordinate, shouldZoomIn: $shouldZoomIn)
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
                .onChange(of: scenePhase) { newScenePhase in
                    if newScenePhase == .active {
                        updateMapViewForSession()
                    }
                }
            
            VStack {
                TopBarView(bleManager: bleManager)
                .padding(.top, 10)
                Spacer()
            }

            VStack {
                if verticalSizeClass == .regular && horizontalSizeClass == .compact {
                    Spacer().frame(height: 55)
                }
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

                    HStack {
                        Button(action: {
                            self.showCurrentLocation.toggle()
                            if self.showCurrentLocation {
                                self.mapViewModel.requestLocation()
                            } else {
                                self.mapViewModel.hideCurrentLocation()
                            }
                        }) {
                            Image(systemName: self.showCurrentLocation ? "location.fill" : "location")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.top, 10)
                        .padding(.trailing, 10)

                        Button(action: {
                            if let lastPacket = bleManager.sessionHandler.currentSession?.packets.last {
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
                }
                
                Spacer()

                HStack {
                    Spacer() // This will push the picker to the right
                    Picker("Select Session", selection: $selectedSession) {
                        Text("Live").tag(nil as BLESession?)
                        ForEach(sessions, id: \.self) { session in
                            Text(session.startTime, formatter: dateFormatter).tag(session as BLESession?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 10)
                    .accentColor(.white)
                }
            }

            VStack {
                Spacer()
                HStack {
                    EnvironmentDataView(bleManager: bleManager)
                    Spacer()
                }
                .padding(.bottom, 25)
            }

        }
        .navigationBarHidden(true) // Hide navigation bar
    }
}

class MapViewModel: NSObject, ObservableObject {
    @Published var annotations: [MKPointAnnotation] = []
    @Published var polyline: MKPolyline? = nil
    private var locationManager: CLLocationManager?

    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
    }

    func requestLocation() {
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }

    func hideCurrentLocation() {
        annotations.removeAll { $0.title == "Current Location" }
        locationManager?.stopUpdatingLocation()
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

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
            view.frame.size = CGSize(width: 20, height: 20)
            view.layer.cornerRadius = view.frame.size.width / 2
            view.layer.borderWidth = 0 // Remove the border

            let imageView = UIImageView()
            imageView.frame = CGRect(x: 2, y: 2, width: 16, height: 16) // Smaller size and offset for padding
            imageView.contentMode = .scaleAspectFit

            if annotation.title == "Current Location" {
                imageView.image = UIImage(systemName: "antenna.radiowaves.left.and.right")
                imageView.tintColor = .black
                view.layer.backgroundColor = UIColor.white.cgColor
            } else if annotation.title == "Node 01" {
                imageView.image = UIImage(systemName: "dot.radiowaves.left.and.right")
                imageView.tintColor = .white
                view.layer.backgroundColor = UIColor.orange.cgColor
            }

            view.addSubview(imageView)
            return view
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

struct EnvironmentDataView: View {
    @ObservedObject var bleManager: BLEManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if let environmentData = bleManager.environmentData {
            VStack(alignment: .leading) {
                Text("Temperature: \(String(format: "%.2f", environmentData.temperature))°C")
                Text("External Temperature: \(String(format: "%.2f", environmentData.externalTemperature))°C")
                Text("Humidity: \(String(format: "%.2f", environmentData.humidity))%")
                Text("External Humidity: \(String(format: "%.2f", environmentData.externalHumidity))%")
                Text("ΔT: \(String(format: "%.2f", environmentData.temperature - environmentData.externalTemperature))°C")
                Text("ΔHumidity: \(String(format: "%.2f", environmentData.humidity - environmentData.externalHumidity))%")
                Text("Pressure: \(String(format: "%.2f", environmentData.pressure)) hPa")
            }
            .font(.footnote)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
            .cornerRadius(10)
            .accentColor(.white)
        }
    }
}

struct TopBarView: View {
    @ObservedObject var bleManager: BLEManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            VStack {
                Image(systemName: "waveform.path.ecg")
                Text("SNR: \(String(format: "%.2f", bleManager.SNRData))")
            }
            VStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                Text("RSSI: \(bleManager.RSSIData)")
            }
            VStack {
                Image(systemName: "waveform")
                Text("FreqErr: \(bleManager.FreqErrData)")
            }
            VStack {
                Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                Text("Satellites: \(bleManager.satellitesData)")
            }
        }
        .font(.footnote)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(colorScheme == .dark ? Color.black.opacity(0.1) : Color.black.opacity(0.1))
        .cornerRadius(10)
        .accentColor(.white)
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

extension MapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        annotation.title = "Current Location"
        annotations.append(annotation)
        
        // Stop updating location after the first update
        manager.stopUpdatingLocation()
    }
}