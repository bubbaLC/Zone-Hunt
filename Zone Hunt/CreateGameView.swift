import SwiftUI
import MapKit
import FirebaseFirestore

class LobbyViewModel: ObservableObject {
    @Published var users: [String] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func listenForLobbyUpdates(lobbyId: String) {
        listener = db.collection("lobbies").document(lobbyId).addSnapshotListener { document, error in
            guard let document = document, document.exists else {
                print("Lobby document does not exist")
                return
            }
            
            if let usersArray = document.data()?["users"] as? [String] {
                DispatchQueue.main.async {
                    self.users = usersArray
                }
            }
        }
    }
    
    func stopListening() {
        listener?.remove()
    }
}

struct CreateGameView: View {
    @State private var gameCode: Int = 0
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var userTrackingMode: MKUserTrackingMode = .follow
    @State private var isLoading = false
    @State private var radius: Double = 500.0
    @State private var lobbyCreated = false
    @State private var lobbyId: String = ""
    
    @StateObject private var lobbyViewModel = LobbyViewModel()
    
    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Text("Game Code: \(String(gameCode))")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(22)
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
                .frame(height: 200)

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

                Button(action: {
                    startGame()
                }) {
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
                gameCode = generateUniqueGameCode()
                createLobby()
            }
        }
        .onDisappear {
            lobbyViewModel.stopListening()
        }
    }

    func createLobby() {
        lobbyCreated = true
        let hostId = UserDefaults.standard.string(forKey: "userId") ?? ""
        lobbyId = UUID().uuidString

        let gameData: [String: Any] = [
            "gameCode": gameCode,
            "createdAt": Timestamp(),
            "users": [hostId], // Host is the first user
            "hostLocation": [region.center.latitude, region.center.longitude],
            "zoneRadius": radius,
            "gameState": "waiting",
            "hostId": hostId,
            "lobbyChat": [],
            "lobbyId": lobbyId
        ]

        db.collection("lobbies").document(lobbyId).setData(gameData) { error in
            if let error = error {
                print("Error creating game: \(error.localizedDescription)")
            } else {
                print("Lobby created!")
                lobbyViewModel.listenForLobbyUpdates(lobbyId: lobbyId)
            }
        }
    }

    func startGame() {
        isLoading = true
        db.collection("lobbies").document(lobbyId).updateData([
            "gameState": "active"
        ]) { error in
            isLoading = false
            if let error = error {
                print("Error starting game: \(error.localizedDescription)")
            } else {
                print("Game started!")
            }
        }
    }

    func generateUniqueGameCode() -> Int {
        var code = Int.random(in: 100000..<999999)
        while hasAdjacentEqualDigits(code: code) {
            code = Int.random(in: 100000..<999999)
        }
        return code
    }

    func hasAdjacentEqualDigits(code: Int) -> Bool {
        let digits = Array(String(code))
        for i in 0..<digits.count - 1 {
            if digits[i] == digits[i + 1] {
                return true
            }
        }
        return false
    }
}


struct CreateGameView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGameView()
    }
}
