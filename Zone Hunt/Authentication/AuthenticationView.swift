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
    }

    private func addUserToFirestore(uid: String, email: String) async throws {
        let userDocument = db.collection("users").document(uid)

        let data: [String: Any] = [
            "uid": uid,
            "name": "guest",
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
    
    var body: some View {
        VStack {
            
            

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
                SigninEmailView(showSignInView: $showSignInView)
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
                        print(error)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Sign In")
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AuthenticationView(showSignInView: .constant(true))
        }
    }
}
