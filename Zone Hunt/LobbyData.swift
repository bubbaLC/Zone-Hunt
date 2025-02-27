//  LobbyData.swift

import Foundation
import FirebaseFirestore

struct LobbyData: Identifiable, Codable {
    @DocumentID var id: String?
    let gameCode: Int  // Keep as Int to match Firestore data type
    let createdAt: Date
    let users: [String]
    let hostLocation: [Double]
    let zoneRadius: Int
    let gameState: String
    let hostId: String
    let lobbyChat: [ChatMessage]
//    let lobbyId: String
    
    struct ChatMessage: Codable {
        var message: String
        var timestamp: Date
        var user: String
    }
    
    init?(from data: [String: Any]) {
        print("Raw Data: \(data)")  // Debugging output

        guard let gameCode = data["gameCode"] as? Int,
              let timestamp = data["createdAt"] as? Timestamp,
              let usersArray = data["users"] as? [String],
              let hostLocationArray = data["hostLocation"] as? [Double],
              let zoneRadius = data["zoneRadius"] as? Int,
              let gameState = data["gameState"] as? String,
              let hostId = data["hostId"] as? String else {
                  print("❌ Error: Missing or invalid required fields in Firestore data")
                  return nil
              }

        self.gameCode = gameCode
        self.createdAt = timestamp.dateValue() // Convert Firestore Timestamp to Date
        self.users = usersArray
        self.hostLocation = hostLocationArray
        self.zoneRadius = zoneRadius
        self.gameState = gameState
        self.hostId = hostId
//        self.lobbyId = data["lobbyId"] as? String ?? "unknown"

        // Handle `lobbyChat` safely
        if let lobbyChatData = data["lobbyChat"] as? [[String: Any]] {
            self.lobbyChat = lobbyChatData.compactMap { chatData in
                guard let message = chatData["message"] as? String,
                      let timestamp = chatData["timestamp"] as? Timestamp,
                      let user = chatData["user"] as? String else {
                          return nil
                      }
                return ChatMessage(message: message, timestamp: timestamp.dateValue(), user: user)
            }
        } else {
            self.lobbyChat = [] // Empty array if no messages
        }
    }

}
