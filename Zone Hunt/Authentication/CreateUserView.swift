//
//  CreateUserView.swift
//  Zone Hunt
//
//  Created by Lukas Krzeminski on 2/4/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreateUserView: View {
    @State private var uid = ""
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @StateObject private var locationManager = LocationManager()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Create a GeoTag Account")
                .font(.title)
                .padding()

            TextField("Email", text: $email)
                .textInputAutocapitalization(.none)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            TextField("Username", text: $username)
                .textInputAutocapitalization(.none)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            SecureField("Password", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Sign Up") {
                signUp()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

            Spacer()
        }
        .padding()
    }

    func signUp() {
        guard validateInputs() else { return }

        let db = Firestore.firestore()

        // Check if username already exists
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { (snapshot, error) in
            if let error = error {
                errorMessage = "Error checking username: \(error.localizedDescription)"
                return
            }
            if let snapshot = snapshot, !snapshot.isEmpty {
                errorMessage = "Username already taken"
                return
            }

            // Sign out any existing user to prevent session conflicts
            try? Auth.auth().signOut()

            // Create user with Firebase Auth
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    errorMessage = "Error creating account: \(error.localizedDescription)"
                    return
                }

                guard let userId = result?.user.uid else { return }

                // Request location permission and get user's location
                locationManager.requestPermission()
                locationManager.requestLocation { location in
                    let latitude = location?.latitude ?? 37.779026 // Default to SF City Hall for testing
                    let longitude = location?.longitude ?? -122.419906

                    // Save user info in Firestore
                    let userData: [String: Any] = [
                        "uid": userId,
                        "username": username,
                        "currentLobbyId": "",
                        "inLobby": false,
                        "email": email,
                        "latitude": latitude,
                        "longitude": longitude
                    ]

                    db.collection("users").document(userId).setData(userData) { error in
                        if let error = error {
                            errorMessage = "Error saving user: \(error.localizedDescription)"
                        } else {
                            // Start continuous location updates
                            locationManager.startUpdatingLocation()
                            Auth.auth().currentUser?.reload { reloadError in
                                if let reloadError = reloadError {
                                    errorMessage = "Error refreshing user session: \(reloadError.localizedDescription)"
                                    return
                                }
                                fetchUserData(userId: userId)
                            }
                        }
                    }
                }
            }
        }
    }
    // Fetch the user data immediately after sign-up
    func fetchUserData(userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                self.username = data?["username"] as? String ?? "Unknown"
                self.uid = data?["uid"] as? String ?? ""

                // Dismiss the view after successful data fetch
                DispatchQueue.main.async {
                    presentationMode.wrappedValue.dismiss()
                }
            } else {
                errorMessage = "Error fetching user data: \(error?.localizedDescription ?? "Unknown error")"
            }
        }
    }

    func validateInputs() -> Bool {
        if email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            errorMessage = "All fields must be filled"
            return false
        }
        if !password.matches("^(?=.*[A-Z])(?=.*\\d)[A-Za-z\\d]{8,}$") {
            errorMessage = "Password must be at least 8 characters, include 1 capital letter, 1 number, and no special characters"
            return false
        }
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            return false
        }
        return true
    }
}

extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression) != nil
    }
}
