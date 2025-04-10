//  JoinGameView.swift

import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth

struct JoinGameView: View {
    var gameCode: Int = 0
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var isLoading = false
    @State private var radius: Double = 500.0
    @State private var lobbyCreated = false
    @State private var lobbyId: String = ""
    @State private var messageText: String = ""
    @State private var isEditingSettings = false
    @State private var isGameStarted = false           // Added to trigger navigation
    @State private var userLocation: CLLocationCoordinate2D? = nil // Added binding for MapView
    @StateObject private var lobbyViewModel = LobbyViewModel()
    @StateObject private var playersLocationViewModel = PlayersLocationViewModel()

    private let db = Firestore.firestore()
    
    //var lobbyId: String // Use the passed-in lobbyId instead of a @State variable

    var body: some View {
        ZStack {
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Text("Game Code: \(String(gameCode))") // Ensures no commas
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.top, 55)

                Spacer()

                Text("Players in Lobby")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()

                List(lobbyViewModel.users, id: \.self) { userId in
                    if let username = lobbyViewModel.userNames[userId] {
                        Text(username) // Show the username
                            .font(.headline)
                            .foregroundColor(.black)
                    } else {
                        Text("Loading...") // Display a placeholder until the username is fetched
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                }
                .frame(height: 150)
                .background(BlurredBackground()) // Custom background modifier
                .cornerRadius(12)
                .padding(.horizontal)
                
                Text("Lobby Chat")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.top)

                List(lobbyViewModel.messages) { message in
                    VStack(alignment: .leading) {
                        Text(message.userId)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(message.text)
                            .font(.body)
                            .foregroundColor(.black)
                    }
                }
                .frame(height: 200)
                .background(BlurredBackground()) // Custom background modifier
                .cornerRadius(12)
                .padding(.horizontal)
                
                HStack {
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(height: 40)
                        .padding(.horizontal)
                        .padding(.vertical, 5)

                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)

                Button(action: startGame) {
                    Text("Start Game")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal, 25)
                        .padding(.top, 10)
                        .padding(.bottom, 65)
                }
                .disabled(isLoading)
            }
            .navigationBarHidden(true)
            
            // Hidden NavigationLink to MapView

            NavigationLink(
                destination: MapView(
                    region: $region,
                    radius: $radius,
                    userLocation: $userLocation,
                    playersLocations: playersLocationViewModel.playersLocations,
                    onExit: leaveLobby
                )
                .edgesIgnoringSafeArea(.all)
                .navigationBarHidden(true)
                .onDisappear {
                    leaveLobby()
                    isGameStarted = false
                },
                isActive: $isGameStarted
            ) {
                EmptyView()
            }

        }
        .onAppear {
            if !lobbyCreated {
                createLobby()
            } else {
                lobbyViewModel.listenForLobbyUpdates(lobbyId: lobbyId)
            }
            // Start listening for players' locations when the view appears
            playersLocationViewModel.listenForPlayers(userIds: lobbyViewModel.users)
        }
        // Update players' locations whenever the list of users in the lobby changes
        .onChange(of: lobbyViewModel.users) { newUserIds in
            playersLocationViewModel.listenForPlayers(userIds: newUserIds)
        }
        .onChange(of: lobbyViewModel.gameState) { newState in
            if newState == "active" && !isGameStarted {
                isGameStarted = true
            }
        }
        .onDisappear {
            if !isEditingSettings && !isGameStarted {
                lobbyViewModel.stopListening()
                leaveLobby()
            }
        }
        .onChange(of: lobbyViewModel.messages) { newMessages in
            print("Messages Updated: \(newMessages)")
        }
    }
    
    // MARK: - Helper Methods
    func sendMessage() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        lobbyViewModel.sendMessage(lobbyId: lobbyId, userId: userId, message: messageText)
        messageText = "" // Clear text field after sending
    }
    // MARK: - Firestore Logic
    func createLobby() {
        guard let user = Auth.auth().currentUser else {
            print("User not authenticated")
            return
        }
        
        lobbyCreated = true
        
        let gameCodeString = "\(gameCode)"
        self.lobbyViewModel.listenForLobbyUpdates(lobbyId: gameCodeString)
        self.lobbyId = gameCodeString
    }

    func leaveLobby() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let lobbyRef = Firestore.firestore().collection("lobbies").document(lobbyId)

        Firestore.firestore().runTransaction { transaction, errorPointer in
            let lobbyDoc: DocumentSnapshot
            do {
                lobbyDoc = try transaction.getDocument(lobbyRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            guard var users = lobbyDoc.data()?["users"] as? [String] else { return nil }
            
            // Remove the user from the lobby
            users.removeAll { $0 == userId }

            if users.isEmpty {
                // If no users are left, delete the lobby
                transaction.deleteDocument(lobbyRef)
            } else {
                // Otherwise, update the users list
                transaction.updateData(["users": users], forDocument: lobbyRef)
            }

            return nil
        } completion: { _, error in
            if let error = error {
                print("Error leaving lobby: \(error)")
            } else {
                print("Successfully left the lobby")
            }
        }
    }


    func startGame() {
        isLoading = true
        db.collection("lobbies").document(lobbyId).updateData([
            "gameState": "active"
        ]) { error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("Error starting game: \(error.localizedDescription)")
                } else {
                    print("Game started!")
                }
            }
        }
    }
}


struct JoinGameView_Previews: PreviewProvider {
    static var previews: some View {
        //CreateGameView(lobbyId: "123456")
        JoinGameView()
    }
}

