//
//  ContentView.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 14/09/23.
//

import SwiftUI
import MapKit

struct MapAnnotationItem: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var title: String
}

class MapViewModel: ObservableObject {
    @Published var annotations: [MapAnnotationItem] = []
    
    init() {
        // Initialize with some initial annotations
        self.annotations = [
            MapAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), title: "Marker 1")
        ]
        
        // Start a timer to update annotations periodically (e.g., every 5 seconds)
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            DispatchQueue.main.async {
                self.updateAnnotations()
            }
        }
    }
    
    // Function to update annotations
    func updateAnnotations() {
        // Simulate updating the annotations with new data
        let newAnnotations = [
            MapAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: 37.775, longitude: -122.42), title: "Updated Marker 1")
        ]
        annotations = newAnnotations
    }
}

struct MapView: UIViewRepresentable {
    @Binding var annotations: [MKPointAnnotation]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        uiView.addAnnotations(annotations)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
    }
}

struct DetailView: View {
    @ObservedObject var viewModel = MapViewModel()
    @ObservedObject var bleManager = BLEManager()
    @State private var lockRegionToLocationData = false // Track lock button state
    @State private var annotations: [MKPointAnnotation] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.0, longitude: 34.0),
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )
    
    func updateAnnotations() {
        // Calculate the new center coordinate based on all annotations
        let coordinates = annotations.map { $0.coordinate }
        let newCenter = CLLocationCoordinate2D(
            latitude: coordinates.reduce(0, { $0 + $1.latitude }) / Double(coordinates.count),
            longitude: coordinates.reduce(0, { $0 + $1.longitude }) / Double(coordinates.count)
        )
        
        // Update the region with the new center
        region = MKCoordinateRegion(
            center: newCenter,
            span: MKCoordinateSpan(
                latitudeDelta: region.span.latitudeDelta,
                longitudeDelta: region.span.longitudeDelta
            )
        )
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Connection Status: \(bleManager.isConnected ? "Connected" : "Disconnected")")
                    .font(.title3)
                
                HStack {
                    Button(action: {
                        lockRegionToLocationData.toggle()
                        if lockRegionToLocationData {
                            // When locked, set region.center to bleManager.locationData
                            region.center = bleManager.locationData
                            region.span.longitudeDelta = 0.015
                            region.span.latitudeDelta = 0.015
                        }
                    }) {
                        Image(systemName: "location.fill" )
                            .font(.title)
                            .foregroundColor( .blue)
                    }
                    .padding(.trailing, 4) // Add some spacing to the right of the button
                    
                    VStack{
                        Text("Latitude: \(bleManager.locationData.latitude)")
                            .font(.title3)
                        Text("Longitude: \(bleManager.locationData.longitude)")
                            .font(.title3)
                    }
                }
                
                
                List(bleManager.discoveredPeripherals, id: \.self) { peripheral in
                    Button(action: {
                        bleManager.connect(to: peripheral)
                    }) {
                        Text(peripheral.name ?? "Unnamed")
                    }
                }
                
                VStack{
                    Map(coordinateRegion: $region, showsUserLocation: false, annotationItems: [MapAnnotationItem(coordinate: bleManager.locationData, title: "PolarTracker")]) { annotation in
                        MapMarker(coordinate: bleManager.locationData, tint: .blue)
                    }
                    
                }
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                
                
                // Text indicating GPS Lock status
                Text("GPS Clock: \(bleManager.hourData)")
                    .font(.title.bold())
                    .padding()
                
                
                Button("Scan for BLE Devices") {
                    bleManager.startBLEConnection()
                }
                .padding()
            }
            .navigationBarTitle("BLE Device List")
        }
    }
}

struct MainMapView: View {
    @ObservedObject var bleManager = BLEManager()
    @State private var annotations: [MKPointAnnotation] = []
    @State private var isShowingAnotherView = false // State to control navigation
    @GestureState private var dragOffset = CGSize.zero // Track the drag offset
    
    var body: some View {
        NavigationView {
            ZStack {
                MapView(annotations: $annotations)
                    .ignoresSafeArea(.all) // Make the map full screen
                
                // Full-width bar with a fading black background at the bottom
                VStack {
                    Spacer()
                    Text("GPS Clock: \(bleManager.hourData)")
                        .font(.title.bold())
                        .padding()
                    VStack{
                        Spacer()
                        Text("Swipe Up for the tracker list")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding(.top, 50)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom)
                
                .background(LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            if value.translation.height < -100 {
                                isShowingAnotherView = true
                            }
                        }
                )
            }
            .sheet(isPresented: $isShowingAnotherView) {
                DetailView()
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true) // Hide navigation bar
    }
}
