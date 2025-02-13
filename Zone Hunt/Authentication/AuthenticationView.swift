//
//  AuthenticationView.swift
//  Zone Hunt
//
//  Created by Liam Colton on 9/20/24.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthenticationViewModel: ObservableObject {
    
    private let db = Firestore.firestore()

    func signInGoogle() async throws {
        let helper = SignInGoogleHelper()
        let tokens = try await helper.signIn()

        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        let authResult = try await Auth.auth().signIn(with: credential)
        let user = authResult.user

        // Store user ID in UserDefaults
        UserDefaults.standard.set(user.uid, forKey: "userId")

        try await addUserToFirestore(uid: user.uid, email: user.email ?? "guest@example.com")
        
        // Fetch and store username
        await fetchAndStoreUsername(for: user.uid)
    }
    
    private func fetchAndStoreUsername(for userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let data = document.data(), let fetchedUsername = data["username"] as? String {
                // Store username in UserDefaults
                UserDefaults.standard.set(fetchedUsername, forKey: "username")
            }
        } catch {
            print("Error fetching username: \(error)")
        }
    }
    
    private func addUserToFirestore(uid: String, email: String) async throws {
        let userDocument = db.collection("users").document(uid)

        let data: [String: Any] = [
            "uid": uid,
            "username": "Guest",  // Changed from "name" to "username" for consistency
            "currentLobbyId": "",
            "inLobby": false,
            "email": email
        ]

        let document = try await userDocument.getDocument()
        if !document.exists {
            try await userDocument.setData(data)
        }
    }
}

struct AuthenticationView: View {
    
    @StateObject private var viewModel = AuthenticationViewModel()
    @Binding var showSignInView: Bool
    
    @State private var isSignedIn: Bool = false
    @State private var username: String? = nil

    var body: some View {
        VStack {
            
            if isSignedIn, let username = username {
                Text("Currently signed in as \(username)")
                    .font(.headline)
                    .padding()
            } else {
                Text("Not signed in")
                    .font(.headline)
                    .padding()
            }
            
            NavigationLink {
                CreateUserView()
            } label: {
                Text("Create a GeoTag Account")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            
            NavigationLink {
                SigninEmailView()
            } label: {
                Text("Sign In With Email")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }

            GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {
                Task {
                    do {
                        try await viewModel.signInGoogle()
                        showSignInView = false
                        self.isSignedIn = true
                        // Try to get username from UserDefaults
                        if let username = UserDefaults.standard.string(forKey: "username") {
                            self.username = username
                        } else {
                            // Fetch from Firestore
                            if let user = Auth.auth().currentUser {
                                await fetchUsername(for: user.uid)
                            }
                        }
                    } catch {
                        print(error)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Sign In")
        .onAppear {
            // Check if user is signed in
            if let user = Auth.auth().currentUser {
                self.isSignedIn = true
                // Try to get username from UserDefaults
                if let storedUsername = UserDefaults.standard.string(forKey: "username") {
                    self.username = storedUsername
                } else {
                    // Fetch from Firestore
                    Task {
                        await fetchUsername(for: user.uid)
                    }
                }
            } else {
                self.isSignedIn = false
                self.username = nil
            }
        }
    }
    
    func fetchUsername(for userId: String) async {
        let db = Firestore.firestore()
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let data = document.data(), let fetchedUsername = data["username"] as? String {
                self.username = fetchedUsername
                // Store in UserDefaults
                UserDefaults.standard.set(fetchedUsername, forKey: "username")
            } else {
                self.username = "Unknown"
            }
        } catch {
            print("Error fetching username: \(error)")
            self.username = "Unknown"
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AuthenticationView(showSignInView: .constant(true))
        }
    }
}
