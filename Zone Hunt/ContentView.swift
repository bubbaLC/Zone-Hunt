//
//  ContentView.swift
//  Zone Hunt
//
//  Created by Liam Colton on 9/10/24.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var showSignInView = false  // Still needed if your SettingsView uses it
    @EnvironmentObject var authVM: AuthenticationViewModel  // Shared instance for authentication state
    
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
                    
                    // (Optional) Remove this bottom settings button if you want only the top-right one.
                    // NavigationLink(destination: SettingsView(showSignInView: $showSignInView)) {
                    //     Text("Settings")
                    //         .font(.system(size: 25, weight: .heavy, design: .monospaced))
                    //         .foregroundColor(.white)
                    //         .padding()
                    //         .frame(maxWidth: .infinity)
                    //         .background(Color.black.opacity(0.7))
                    //         .cornerRadius(10)
                    // }
                    // .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            // Remove .navigationBarHidden(true) so the toolbar shows
            .navigationBarItems(trailing:
                NavigationLink(destination: SettingsView(showSignInView: $showSignInView)) {
                    HStack(spacing: 8) {
                        if let username = authVM.username {
                            Text(username)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                    }
                }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContentView()
                .environmentObject(AuthenticationViewModel())
        }
    }
}
