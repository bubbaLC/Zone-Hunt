//  LobbyView.swift

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct LobbyView: View {
    @State private var gameCode: String = ""
    //    @State private var isCreatingGame = false
    //    @State private var isJoiningGame = false
    @State private var navigateToLobbyDetail = false  // Used for programmatic navigation
    @State private var errorMessage: String? // Add error handling
    
    let charLimit = 6
    
    /// Adds the current user's ID to the lobby's "users" field.
    func joinLobby(lobbyId: String) {
        let userId = Auth.auth().currentUser?.uid ?? ""
        let lobbyRef = Firestore.firestore().collection("lobbies").document(lobbyId)
        
        // Check if the lobby exists
        lobbyRef.getDocument { snapshot, error in
            guard let document = snapshot, document.exists else {
                DispatchQueue.main.async {
                    self.errorMessage = "Lobby not found."
                }
                return
            }
            
            // Add the user to the lobby's "users" field if not already in
            lobbyRef.updateData(["users": FieldValue.arrayUnion([userId])]) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = "Failed to join. Try again. \(error.localizedDescription)"
                    } else {
                        // Ensure the game code is properly passed to JoinGameView
                        self.gameCode = lobbyId
                        self.navigateToLobbyDetail = true // Navigate to the lobby
                    }
                }
            }
        }
    }

    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("BackgroundImage")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Text("GeoTag Lobby")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .fontWeight(.heavy)
                        .padding(60)
                    
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    
                    // Create Game Button (navigates to CreateGameView)
                    NavigationLink(destination: CreateGameView(/*lobbyId: gameCode*/)) {
                        Text("Create Game")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    TextField("Enter Game Code", text: $gameCode)
                        .keyboardType(.numberPad)
                        .onChange(of: gameCode) { newValue, _ in
                            if newValue.count > charLimit {
                                gameCode = String(newValue.prefix(charLimit))
                            }
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 17)
                        .padding(.vertical, 5)
                        .cornerRadius(10)
                    
                    // Join Game Button
                    Button(action: { joinLobby(lobbyId: gameCode) }) {
                        Text("Join Game")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(gameCode.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(gameCode.isEmpty)
                    
                    Spacer()
                    
                    // Hidden NavigationLink for programmatic navigation to the LobbyDetailView.
                    NavigationLink(
                        destination: JoinGameView(gameCode: Int(gameCode) ?? 0),
                        isActive: $navigateToLobbyDetail
                    ) {
                        EmptyView()
                    }
                }
            }
        }
    }
}

struct LobbyView_Previews: PreviewProvider {
    static var previews: some View {
        LobbyView()
    }
}


