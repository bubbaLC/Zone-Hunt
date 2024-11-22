//
//  SignInGoogleHelper.swift
//  Zone Hunt
//
//  Created by Lukas Krzeminski on 11/22/24.
//

import Foundation
import GoogleSignIn
import GoogleSignInSwift

struct GoogleSignInResultModel {
    let idToken: String
    let accessToken: String
}

final class SignInGoogleHelper {

    @MainActor
    func signIn() async throws -> GoogleSignInResultModel {
        // Fetch the top-most view controller to present the Google sign-in screen
        guard let topVC = Utilities.shared.topViewController() else {
            throw URLError(.cannotFindHost)
        }

        // Present the Google sign-in screen and wait for the result
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)

        // Ensure that the idToken and accessToken are properly retrieved from the result
        guard let idToken = gidSignInResult.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        let accessToken = gidSignInResult.user.accessToken.tokenString

        // Return the tokens wrapped in a custom result model
        return GoogleSignInResultModel(idToken: idToken, accessToken: accessToken)
    }
}

