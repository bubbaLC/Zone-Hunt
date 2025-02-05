//
//  LobbyData.swift
//  Zone Hunt
//
//  Created by Liam Colton on 2/4/25.
//

import Foundation
import FirebaseFirestore

struct LobbyData {
    let gameCode: String
    let createdAt: Date
    let users: [String]
    let hostLocation: [Double]
    let zoneRadius: Double
    let gameState: String
    let hostId: String
    let lobbyChat: [String]
    let lobbyId: String
    
    // Initialize from Firestore data.
    init?(from data: [String: Any]) {
        // Adjust these keys and types as per your Firestore structure.
        guard let gameCodeInt = data["gameCode"] as? Int,
              let timestamp = data["createdAt"] as? Timestamp,
              let users = data["users"] as? [String],
              let hostLocation = data["hostLocation"] as? [Double],
              let zoneRadius = data["zoneRadius"] as? Double,
              let gameState = data["gameState"] as? String,
              let hostId = data["hostId"] as? String,
              let lobbyChat = data["lobbyChat"] as? [String],
              let lobbyId = data["lobbyId"] as? String else {
                  return nil
              }
        self.gameCode = String(gameCodeInt)
        self.createdAt = timestamp.dateValue()
        self.users = users
        self.hostLocation = hostLocation
        self.zoneRadius = zoneRadius
        self.gameState = gameState
        self.hostId = hostId
        self.lobbyChat = lobbyChat
        self.lobbyId = lobbyId
    }
}

