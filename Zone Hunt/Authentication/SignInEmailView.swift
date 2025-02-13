//
//  SignInEmailView.swift
//  Zone Hunt
//
//  Created by Liam Colton on 9/20/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class SignInEmailViewModel: ObservableObject {
    
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var username: String? // Store username after sign-in
    
    private let db = Firestore.firestore()
    
    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "No email or password found."
            showError = true
            return
        }
        
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            let userId = authResult.user.uid
            
            if let fetchedUsername = await fetchUsername(for: userId) {
                username = fetchedUsername
                // Store username and userId in UserDefaults
                UserDefaults.standard.set(fetchedUsername, forKey: "username")
                UserDefaults.standard.set(userId, forKey: "userId")
            } else {
                return
            }
            // If sign-in is successful, set error message to nil
            errorMessage = nil
        } catch let authError as NSError {
            switch authError.code {
            case AuthErrorCode.userNotFound.rawValue:
                errorMessage = "No account found for this email."
            case AuthErrorCode.wrongPassword.rawValue:
                errorMessage = "Incorrect password."
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "Invalid email format."
            default:
                errorMessage = "Sign-in failed: \(authError.localizedDescription)"
            }
            showError = true
        }
    }
    
    func fetchUsername(for userId: String) async -> String? {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let data = document.data(), let fetchedUsername = data["username"] as? String {
                return fetchedUsername
            } else {
                errorMessage = "No username found. Please set up a username."
                showError = true
                return nil
            }
        } catch {
            errorMessage = "Error fetching user data: \(error.localizedDescription)"
            showError = true
            return nil
        }
    }
}

struct SigninEmailView: View {
    
    @StateObject private var viewModel = SignInEmailViewModel()
    @Environment(\.presentationMode) var presentationMode // Access the presentation mode
    
    var body: some View {
        VStack {
            TextField("Email...", text: $viewModel.email)
                .padding()
                .background(Color.gray.opacity(0.4))
                .cornerRadius(10)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            SecureField("Password...", text: $viewModel.password)
                .padding()
                .background(Color.gray.opacity(0.4))
                .cornerRadius(10)
            
            Button {
                Task {
                    await viewModel.signIn()
                    if viewModel.errorMessage == nil {
                        // Dismiss the view upon successful sign-in
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } label: {
                Text("Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .alert(isPresented: $viewModel.showError) {
                Alert(title: Text("Error"),
                      message: Text(viewModel.errorMessage ?? "Unknown error"),
                      dismissButton: .default(Text("OK")))
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Sign In With Email")
    }
}

struct SigninEmailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SigninEmailView()
        }
    }
}
