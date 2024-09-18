//
//  ContentView.swift
//  Zone Hunt
//
//  Created by Liam Colton on 9/10/24.
//

import SwiftUI
import MapKit
struct ContentView: View {
    @State private var showSignInView = false  // Add the State variable
    var body: some View {
        NavigationView {
            ZStack {
                // Background Image
                Image("BackgroundImage")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    Text("GeoTag")
                        //.font(.largeTitle)
                        .font(.system(size: 60, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .padding()
                    Spacer()
                    // Play button leads to the lobby view
                    NavigationLink(destination: LobbyView()) {
                        Text("Play")
                            .font(.system(size: 25, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    // Settings button with showSignInView binding
                    NavigationLink(destination: SettingsView(showSignInView: $showSignInView)) {  // Pass the binding
                        Text("Settings")
                            .font(.system(size: 25, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
