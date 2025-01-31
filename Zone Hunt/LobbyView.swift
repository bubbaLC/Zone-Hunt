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
    @State private var isCreatingGame = false
    @State private var isJoiningGame = false
    let charLimit = 6
    
    var body: some View {
        NavigationView {
            ZStack{
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

                    // Create Game Button
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
                        .onChange(of: gameCode) {
                            if gameCode.count > charLimit {
                                gameCode = String(gameCode.prefix(charLimit))
                            }
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 17)
                        .padding(.vertical, 5)
                        .cornerRadius(10)

                    // Join Game Button
                    Button(action: {
                        joinLobby(lobbyId: gameCode)
                    }) {
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
                }
            }
        }
    }

    func joinLobby(lobbyId: String) {
        let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
        let lobbyRef = Firestore.firestore().collection("lobbies").document(lobbyId)

        lobbyRef.updateData([
            "users": FieldValue.arrayUnion([userId])
        ]) { error in
            if let error = error {
                print("Error joining lobby: \(error.localizedDescription)")
            } else {
                print("User \(userId) joined lobby \(lobbyId)")
                isJoiningGame = true // Update UI state if needed
            }
        }
    }
}

struct LobbyView_Previews: PreviewProvider {
    static var previews: some View {
        LobbyView()
    }
}



