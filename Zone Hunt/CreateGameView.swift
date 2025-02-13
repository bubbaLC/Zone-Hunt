import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth

class LobbyViewModel: ObservableObject {
    @Published var users: [String] = []
    @Published var messages: [Message] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func listenForLobbyUpdates(lobbyId: String) {
        guard listener == nil else { return } // Prevent multiple listeners

        listener = db.collection("lobbies").document(lobbyId).addSnapshotListener { document, error in
            guard let document = document, document.exists else {
                print("Lobby document does not exist")
                return
            }
            
            if let usersArray = document.data()?["users"] as? [String] {
                DispatchQueue.main.async {
                    self.users = usersArray
                }
                if let chatArray = document.data()?["lobbyChat"] as? [[String: String]] {
                    DispatchQueue.main.async {
                        self.messages = chatArray.compactMap { dict in
                            guard let user = dict["user"], let text = dict["message"] else { return nil }
                            return Message(userId: user, text: text)
                        }
                    }
                }
            }
        }
    }
    
    func sendMessage(lobbyId: String, userId: String, message: String) {
        guard !message.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let newMessage: [String: String] = ["user": userId, "message": message]
        
        db.collection("lobbies").document(lobbyId).updateData([
            "lobbyChat": FieldValue.arrayUnion([newMessage])
        ]) { error in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
}

struct CreateGameView: View {
    @State private var gameCode: Int = 0
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var isLoading = false
    @State private var radius: Double = 500.0
    @State private var lobbyCreated = false
    @State private var lobbyId: String = ""
    @State private var messageText: String = ""
    
    @StateObject private var lobbyViewModel = LobbyViewModel()
    
    private let db = Firestore.firestore()

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
                    Text(userId)
                        .font(.headline)
                        .foregroundColor(.black)
                }
                .frame(height: 150)
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
                
                NavigationLink(destination: EditGameSettings(gameView: self)) {
                    Text("Edit Game Settings")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .cornerRadius(10)
                        .padding(.horizontal, 25)
                }

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
        }
        .onAppear {
            if !lobbyCreated {
                createLobby()
            } else {
                lobbyViewModel.listenForLobbyUpdates(lobbyId: lobbyId)
            }
        }
        .onDisappear {
            lobbyViewModel.stopListening()
            leaveLobby()
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
        let hostId = user.uid
        
        generateUniqueGameCode { code in
            guard let code = code else {
                print("Failed to generate unique code")
                return
            }
            
            DispatchQueue.main.async {
                self.gameCode = code
            }
            
            let gameCodeString = "\(code)" // Ensures consistent Firestore storage
            let gameData: [String: Any] = [
                "gameCode": code,
                "createdAt": Timestamp(),
                "users": [hostId],
                "hostLocation": [region.center.latitude, region.center.longitude],
                "zoneRadius": radius,
                "gameState": "waiting",
                "hostId": hostId,
                "lobbyChat": []
            ]
            
            db.collection("lobbies").document(gameCodeString).setData(gameData) { error in
                if let error = error {
                    print("Error creating game: \(error.localizedDescription)")
                } else {
                    print("Lobby created with code \(code)!")
                    DispatchQueue.main.async {
                        self.lobbyViewModel.listenForLobbyUpdates(lobbyId: gameCodeString)
                        self.lobbyId = gameCodeString
                    }
                }
            }
        }
    }

    func generateUniqueGameCode(completion: @escaping (Int?) -> Void) {
        let maxAttempts = 5
        var attempts = 0

        func generateCode() {
            let code = Int.random(in: 100000..<999999)
            let codeString = String(code)

            db.collection("lobbies").document(codeString).getDocument { snapshot, _ in
                if snapshot?.exists == true, attempts < maxAttempts {
                    attempts += 1
                    generateCode()
                } else {
                    completion(snapshot?.exists == true ? nil : code)
                }
            }
        }

        generateCode()
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

struct Message: Identifiable, Equatable {
    let id = UUID()  // Ensures uniqueness
    let userId: String
    let text: String
}

struct BlurredBackground: View {
    var body: some View {
        Color.black.opacity(0.2) // Light grey translucent effect
            .blur(radius: 10)
            .background(Color.gray.opacity(0.2)) // Adds a subtle background color
    }
}

struct CreateGameView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGameView()
    }
}
