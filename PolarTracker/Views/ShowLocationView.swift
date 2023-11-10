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
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var sessions: [BLESession]

    var body: some View {
        ZStack {
            MapView(annotations: $annotations)
                .ignoresSafeArea(.all) // Make the map full screen
                .onAppear {
                    annotations = sessions.flatMap { session in
                        session.packets.map { packet in
                            let annotation = MKPointAnnotation()
                            annotation.coordinate = packet.location.clLocationCoordinate2D
                            return annotation
                        }
                    }
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
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true) // Hide navigation bar
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