//
//  JoinGameView.swift
//  Zone Hunt
//
//  Created by Liam Colton on 2/4/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct JoinGameView: View {
    @State private var gameCode: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var navigateToLobbyDetail = false // For navigation

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Enter game code", text: $gameCode)
                    .padding()
                    .keyboardType(.numberPad)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                
                if isLoading {
                    ProgressView()
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                
                Button("Join Game") {
                    joinGame()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
            .navigationDestination(isPresented: $navigateToLobbyDetail) {
                LobbyDetailView(lobbyId: gameCode)
            }
        }
    }
    
    func joinGame() {
        guard !gameCode.isEmpty else {
            errorMessage = "Please enter a valid game code."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let lobbyRef = db.collection("lobbies").document(gameCode) // Document ID = game code
        
         /* I Dont know if I need this code I replaced it with the code below */
        
//        lobbyRef.getDocument { snapshot, error in
//            guard snapshot?.exists == true else {
//                errorMessage = "Lobby not found."
//                isLoading = false
//                return
//            }
//            
//            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
//                errorMessage = "Lobby not found."
//                isLoading = false
//                return
//            }
//            
//            guard let currentUser = Auth.auth().currentUser else {
//                errorMessage = "You must be logged in to join a game."
//                isLoading = false
//                return
//            }
//            
//            let currentUserId = currentUser.uid
//            var users = data["users"] as? [String] ?? []
//            
//            if !users.contains(currentUserId) {
//                users.append(currentUserId)
//            }
//            
//            lobbyRef.updateData(["users": FieldValue.arrayUnion([currentUserId])]) { error in
//                DispatchQueue.main.async {
//                    isLoading = false
//                    if error == nil {
//                        navigateToLobbyDetail = true // Trigger navigation
//                    } else {
//                        errorMessage = "Join failed. Try again."
//                    }
//                }
//            }
//        }
        
        // 1. Check if lobby exists
        lobbyRef.getDocument { snapshot, error in
            guard snapshot?.exists == true else {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Lobby not found."
                }
                return
            }
            
            guard let currentUser = Auth.auth().currentUser else {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "You must be logged in to join a game."
                }
                return
            }
            
            let userId = currentUser.uid
            
            // 2. Add user to lobby
            lobbyRef.updateData(["users": FieldValue.arrayUnion([userId])]) { error in
                DispatchQueue.main.async {
                    isLoading = false
                    if error == nil {
                        navigateToLobbyDetail = true // Trigger navigation
                    } else {
                        errorMessage = "Join failed. Try again."
                    }
                }
            }
        }
    }
}
