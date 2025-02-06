//
//  LobbyDetailView.swift
//  Zone Hunt
//
//  Created by Liam Colton on 2/4/25.
//

import SwiftUI
import FirebaseFirestore

struct LobbyDetailView: View {
    let lobbyId: String
    @State private var lobbyData: LobbyData?
    @State private var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack {
            if let lobbyData = lobbyData {
                Text("Lobby \(lobbyData.gameCode)")
                    .font(.largeTitle)
                    .padding(.top)
                
                Text("Game State: \(lobbyData.gameState)")
                    .font(.headline)
                
                Text("Players:")
                    .font(.title2)
                    .padding(.top)
                ForEach(lobbyData.users, id: \.self) { user in
                    Text(user)
                        .padding(4)
                }
                Spacer()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                ProgressView("Loading lobby...")
            }
        }
        .padding()
        .navigationBarTitle("Lobby", displayMode: .inline)
        .onAppear(perform: subscribeToLobby)
    }
    
    func subscribeToLobby() {
        db.collection("lobbies").document(lobbyId)
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let data = snapshot?.data() else {
                        self.errorMessage = "Lobby deleted."
                        return
                    }
                    
                    self.lobbyData = LobbyData(from: data)
                }
            }
    }
}
