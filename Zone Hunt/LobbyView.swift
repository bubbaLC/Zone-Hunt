//
//  LobbyView.swift
//  Zone Hunt
//
//  Created by Liam Colton on 9/11/24.
//

import SwiftUI
import FirebaseFirestore

struct LobbyView: View {
    @State private var gameCode: String = ""
    //    @State private var isCreatingGame = false
    //    @State private var isJoiningGame = false
    @State private var navigateToLobbyDetail = false  // Used for programmatic navigation
    @State private var errorMessage: String? // Add error handling
    
    let charLimit = 6
    
    /// Adds the current user's ID to the lobby's "users" field.
    func joinLobby(lobbyId: String) {
        let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
        let lobbyRef = Firestore.firestore().collection("lobbies").document(lobbyId)
        
        // First check if lobby exists
        lobbyRef.getDocument { snapshot, error in
            guard snapshot?.exists == true else {
                DispatchQueue.main.async {
                    self.errorMessage = "Lobby not found." // Show error
                }
                return
            }
            
            // Add user to lobby
            lobbyRef.updateData(["users": FieldValue.arrayUnion([userId])]) { error in
                DispatchQueue.main.async {
                    if error == nil {
                        navigateToLobbyDetail = true // Trigger navigation
                    } else {
                        self.errorMessage = "Failed to join. Try again."
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
                    NavigationLink(destination: CreateGameView()) {
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
                    .navigationDestination(isPresented: $navigateToLobbyDetail) {
                        LobbyDetailView(lobbyId: gameCode)
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
}


