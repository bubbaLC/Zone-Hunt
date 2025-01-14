//
//  SettingsView.swift
//  Zone Hunt
//
//  Created by Liam Colton on 9/10/24.
//

import SwiftUI
@MainActor
final class SettingsViewModel: ObservableObject {
    
    @Published var authProviders: [AuthProviderOption] = []
    
    func loadAuthProviders() {
        do {
            authProviders = try AuthenticationManager.shared.getProviders()
        } catch {
            print("Failed to load auth providers: \(error)")
        }
    }
    
    func signOut() throws {
        try AuthenticationManager.shared.signOut()
    }
    
    func resetPassword() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticationUser()
        
        guard let email = authUser.email else {
            throw URLError(.fileDoesNotExist)
        }
        try await AuthenticationManager.shared.resetPassword(email: email)
    }
    
    func updateEmail() async throws {
        let email = "hello123@gmail.com"
        try await AuthenticationManager.shared.updateEmail(email: email)
    }
    
    func updatePassword() async throws {
        let password = "Hello123!"
        try await AuthenticationManager.shared.updatePassword(password: password)
    }
}
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var volume: Double = UserDefaults.standard.double(forKey: "savedVolume")
    @StateObject private var viewModel = SettingsViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image("BackButtonImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 40)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                        .padding()
                }
                Spacer()
            }
            
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
                .padding()
            // Volume slider and label directly below "Settings" title
            Text("Volume")
                .font(.headline)
                .padding(.top, 20)
            Slider(value: $volume, in: 0...1, step: 0.01, onEditingChanged: { _ in
                saveVolume()
            })
                .accentColor(.yellow)
                .padding(.horizontal, 20)
            Text(String(format: "Volume: %.0f%%", volume * 100))
                .font(.subheadline)
                .padding(.top, 10)
            // Account Settings Button
            NavigationLink(destination: AuthenticationView(showSignInView: $showSignInView)) {
                Text("Account Settings")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.top, 30)
            }
            
            List {
                Button("Log out") {
                    Task {
                        do {
                            try viewModel.signOut()
                            showSignInView = true
                        } catch {
                            print(error)
                        }
                    }
                }
                
                if viewModel.authProviders.contains(.email) {
                    Section {
                        Button("Reset password") {
                            Task {
                                do {
                                    try await viewModel.resetPassword()
                                    print("PASSWORD RESET!")
                                } catch {
                                    print(error)
                                }
                            }
                        }
                        Button("Update password") {
                            Task {
                                do {
                                    try await viewModel.updatePassword()
                                    print("PASSWORD UPDATED!")
                                } catch {
                                    print(error)
                                }
                            }
                        }
                        Button("Update email") {
                            Task {
                                do {
                                    try await viewModel.updateEmail()
                                    print("EMAIL UPDATED!")
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    } header: {
                        Text("Email functions")
                    }
                }
            }
            .onAppear {
                viewModel.loadAuthProviders()
            }
            
            Spacer()
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .onAppear {
            loadVolume()
        }
    }
    private func saveVolume() {
        UserDefaults.standard.set(volume, forKey: "savedVolume")
    }
    private func loadVolume() {
        volume = UserDefaults.standard.object(forKey: "savedVolume") as? Double ?? 0.5
    }
}
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView(showSignInView: .constant(true))
        }
    }
}
