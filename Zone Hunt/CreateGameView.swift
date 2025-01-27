import SwiftUI
import MapKit
import FirebaseFirestore

struct CreateGameView: View {
    @State private var gameCode: Int = 0
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Example: San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var userTrackingMode: MKUserTrackingMode = .follow
    @State private var isLoading = false
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
            gameCode = generateUniqueGameCode()
        }
    }
    
    func startGame() {
        isLoading = true
        let gameData: [String: Any] = [
            "gameCode": gameCode,
            "createdAt": Timestamp(),
            "users": [], // Empty array initially
            "region": [
                "latitude": region.center.latitude,
                "longitude": region.center.longitude,
                "latitudeDelta": region.span.latitudeDelta,
                "longitudeDelta": region.span.longitudeDelta
            ]
        ]
        
        db.collection("lobbies").document("\(gameCode)").setData(gameData) { error in
            isLoading = false
            if let error = error {
                print("Error creating game: \(error.localizedDescription)")
            } else {
                print("Game created successfully!")
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
