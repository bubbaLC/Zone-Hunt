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
    
    @Published var shouldPromptForUsername: Bool = false
    @Published var username: String? = nil
    @Published var isSignedIn: Bool = false
    
    func signInGoogle() async throws {
        let helper = SignInGoogleHelper()
        let tokens = try await helper.signIn()
        
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        let authResult = try await Auth.auth().signIn(with: credential)
        let user = authResult.user
        
        // Store user ID
        UserDefaults.standard.set(user.uid, forKey: "userId")
        
        // Ensure user is added to Firestore
        try await addUserToFirestore(uid: user.uid, email: user.email ?? "")

        // Fetch or prompt for username
        await fetchAndStoreUsername(for: user.uid)

        self.isSignedIn = true
    }
    
    private func fetchAndStoreUsername(for userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let data = document.data(), let fetchedUsername = data["username"] as? String, !fetchedUsername.isEmpty {
                print("Fetched username: \(fetchedUsername)") // Debugging line
                UserDefaults.standard.set(fetchedUsername, forKey: "username")
                self.username = fetchedUsername
                self.shouldPromptForUsername = false
            } else {
                print("No username found, prompting user.") // Debugging line
                self.shouldPromptForUsername = true
            }
        } catch {
            print("Error fetching username: \(error)")
            self.shouldPromptForUsername = true
        }
    }
    
    private func addUserToFirestore(uid: String, email: String) async throws {
        let userDocument = db.collection("users").document(uid)

        let document = try await userDocument.getDocument()
        if !document.exists {
            let data: [String: Any] = [
                "uid": uid,
                "username": "",
                "currentLobbyId": "",
                "inLobby": false,
                "email": email
            ]
            try await userDocument.setData(data)
        }
    }
    
    func updateUsername(for userId: String, username: String) async {
        do {
            try await db.collection("users").document(userId).updateData(["username": username])
            print("Updated username in Firestore: \(username)") // Debugging line
            UserDefaults.standard.set(username, forKey: "username")
            self.username = username
            self.shouldPromptForUsername = false
        } catch {
            print("Error updating username: \(error)")
        }
    }
    
    func checkSignInStatus() {
        if let user = Auth.auth().currentUser {
            self.isSignedIn = true
            self.username = UserDefaults.standard.string(forKey: "username")
            print("Loaded username from UserDefaults: \(self.username ?? "None")") // Debugging line
            if username == nil {
                Task {
                    await fetchAndStoreUsername(for: user.uid)
                }
            }
        } else {
            self.isSignedIn = false
            self.username = nil
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isSignedIn = false
            self.username = nil
            UserDefaults.standard.removeObject(forKey: "username")
            UserDefaults.standard.removeObject(forKey: "userId")
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

struct AuthenticationView: View {
    
    @StateObject private var viewModel = AuthenticationViewModel()
    @Binding var showSignInView: Bool
    
    @State private var newUsername: String = ""

    var body: some View {
        VStack {
            if viewModel.isSignedIn, let username = viewModel.username {
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
                    } catch {
                        print("Error signing in: \(error)")
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Sign In")
        .onAppear {
            viewModel.checkSignInStatus()
        }
        .sheet(isPresented: $viewModel.shouldPromptForUsername) {
            VStack {
                Text("Create a Username")
                    .font(.headline)
                    .padding()

                TextField("Enter your username", text: $newUsername)
                    .padding()
                    .background(Color.gray.opacity(0.4))
                    .cornerRadius(10)

                Button("Save Username") {
                    if let userId = UserDefaults.standard.string(forKey: "userId") {
                        Task {
                            await viewModel.updateUsername(for: userId, username: newUsername)
                        }
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
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
