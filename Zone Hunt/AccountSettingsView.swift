//
//  AccountSettingsView.swift
//  Zone Hunt
//
//  Created by Liam Colton on 9/10/24.
//

import SwiftUI
struct AccountSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    // Current username variable
    @State private var username: String = UserDefaults.standard.string(forKey: "username") ?? "Default Username"
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
            Text("Account Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            HStack {
                Text("Username:")
                    .padding(.horizontal, 25)
                // Editable text box for the username
                TextField("Enter your username", text: $username, onCommit: {
                    saveUsername() // Press Enter to save username
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)
            }
            Spacer()
            // Save button for username
            Button(action: {
                saveUsername()
            }) {
                Text("Save Username")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .onAppear {
            loadUsername() // Load the saved username when the view appears
        }
    }
    // Saves the username
    private func saveUsername() {
        UserDefaults.standard.set(username, forKey: "username")
    }
    // Load the saved username
    private func loadUsername() {
        if let savedUsername = UserDefaults.standard.string(forKey: "username") {
            username = savedUsername
        }
    }
}
struct AccountSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountSettingsView()
    }
}

