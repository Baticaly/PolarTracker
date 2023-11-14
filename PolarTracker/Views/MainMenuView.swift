//
//  MainMenuView.swift
//  PolarTracker
//
//  Created by Batuhan Ergun on 10/11/23.
//

import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var bleManager: BLEManager
    @StateObject var mapViewModel = MapViewModel()

    var body: some View {
        NavigationView {
            VStack {
                DeviceStatusView(bleManager: bleManager)
                ScrollView {
                    NavigationLink(destination: ConnectDeviceView()) {
                        CardView(imageName: "antenna.radiowaves.left.and.right", title: "Connect Device", description: "Connect to a BLE device.")
                    }
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                    NavigationLink(destination: ShowLocationView(sessions: bleManager.sessionHandler.sessions, mapViewModel: mapViewModel)) {
                        CardView(imageName: "map", title: "Live Map", description: "Show the current location.")
                    }
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                    NavigationLink(destination: ShowDetailsView()) {
                        CardView(imageName: "doc.text.viewfinder", title: "Overview", description: "Show packet details")
                    }
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                    NavigationLink(destination: SessionListView().environmentObject(bleManager)) {
                        CardView(imageName: "clock.arrow.circlepath", title: "Saved Sessions", description: "Show previously saved sessions.")
                    }
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                    Spacer()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct CardView: View {
    let imageName: String
    let title: String
    let description: String

    var body: some View {
        ZStack(alignment: .center) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline) // Adjusted font size
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(description)
                        .font(.subheadline) // Adjusted font size
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: imageName)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
            }
            .padding(.top, 40)
            .padding(.bottom, 40)
            .padding(.leading, 35)
            .padding(.trailing, 35)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor(hex: "#111111"))) // Dark gray background for better contrast with white text
            .cornerRadius(10)
        }
    }
}

struct DeviceStatusView: View {
    @ObservedObject var bleManager: BLEManager

    var body: some View {
        HStack {
            Image("deviceIllustration")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .padding(.all, 10)

            VStack(alignment: .leading) {
                Text(bleManager.connectedPeripheralName ?? "Base Station 01")
                    .font(.headline)
                    .fontWeight(.bold)
                HStack {
                    Circle()
                        .fill(bleManager.isConnected ? Color.green : Color.gray)
                        .frame(width: 10, height: 10)
                    Text(bleManager.isConnected ? "Recording" : "Offline")
                        .font(.subheadline)
                }
            }
            .padding(.all, 3)
            Spacer()
        }
        .padding()
        .background(Color(UIColor(hex: "#1c1c1b")))
    }
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.hasPrefix("#") ? hex.index(after: hex.startIndex) : hex.startIndex

        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff

        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, 
            alpha: 1
        )
    }
}
