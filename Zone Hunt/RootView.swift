//
//  RootView.swift
//  Zone Hunt
//
//  Created by Liam Colton on 3/14/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel

    var body: some View {
        Group {
            if authVM.isSignedIn {
                ContentView() // Your main app view
            } else {
                NavigationStack {
                    AuthenticationView() // No need for an extra binding here
                }
            }
        }
        .onAppear {
            authVM.checkSignInStatus()
        }
    }
}
