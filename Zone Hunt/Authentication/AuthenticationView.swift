//
//  AuthenticationView.swift
//  Zone Hunt
//
//  Created by Liam Colton on 9/20/24.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
@MainActor
final class AuthenticationViewModel: ObservableObject {
    
    
    func signInGoogle() async throws {
//        let something = GIDSignIN.sharedInstance.signIn(withPresenting: UIViewController)
    }
    
}
struct AuthenticationView: View {
    
    @StateObject private var viewModel = AuthenticationViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        VStack {
            
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
                
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Sign In")
    }
}
struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack{
            AuthenticationView(showSignInView: .constant(true))
        }
    }
}
