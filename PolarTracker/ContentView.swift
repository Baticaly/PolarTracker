//
//  ContentView.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 14/09/23.
//

import SwiftUI
import MapKit

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
    @ObservedObject var bleManager = BLEManager()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Connected Status: \(bleManager.isConnected ? "Connected" : "Disconnected")")
                    .font(.title3)
                    .padding()
                
                Text("Characteristic Value: \(bleManager.characteristicValue)")
                    .font(.title3)
                    .padding()
                
                Text("Location: \(bleManager.locationData)")
                    .font(.title3)
                    .padding()
                
                List(bleManager.discoveredPeripherals, id: \.self) { peripheral in
                    Button(action: {
                        bleManager.connect(to: peripheral)
                    }) {
                        Text(peripheral.name ?? "Unnamed")
                    }
                }
                .padding()
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
                    Text("Swipe Up to Open Menu")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.top, 50)
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
            .onAppear {
                // Initialize and update your annotations here
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                annotation.title = "San Francisco"
                annotations.append(annotation)
            }
            .sheet(isPresented: $isShowingAnotherView) {
                DetailView()
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true) // Hide navigation bar
    }
}
