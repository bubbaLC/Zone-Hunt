//  LobbyDetailView.swift

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

    /// Subscribes to Firestore updates and decodes the lobby document.
    func subscribeToLobby() {
        db.collection("lobbies").document(lobbyId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Firestore error: \(error.localizedDescription)"
                    }
                    return
                }

                guard let snapshot = snapshot else {
                    DispatchQueue.main.async {
                        self.errorMessage = "No snapshot found."
                    }
                    return
                }

                do {
                    // ✅ Firestore auto-decoding with Codable
                    let lobby = try snapshot.data(as: LobbyData.self)
                    DispatchQueue.main.async {
                        self.lobbyData = lobby
                        self.errorMessage = nil
                    }
                    print("✅ Successfully decoded lobby: \(lobby)")
                } catch {
                    print("❌ Auto-decoding failed: \(error.localizedDescription)")
                    print("🔍 Raw data: \(snapshot.data() ?? [:])")

                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to parse lobby data. Check Firestore structure."
                    }
                }
            }
    }
}

