//  PlayersLocationViewModel.swift
//  Created by Liam Colton on 4/4/25.
import Foundation
import FirebaseFirestore
import CoreLocation

class PlayersLocationViewModel: ObservableObject {
    @Published var playersLocations: [String: CLLocationCoordinate2D] = [:]
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    /// Starts listening for location updates for players in the lobby.
    func listenForPlayers(userIds: [String]) {
        // Check if array is empty. Firestore "in" queries require a non-empty array.
        guard !userIds.isEmpty else {
            // If the array is empty, reset the locations and remove any previous listener.
            self.playersLocations = [:]
            listener?.remove()
            listener = nil
            return
        }

        // Remove any existing listener before starting a new one.
        listener?.remove()
        
        // Use Firestore "in" query for the given user IDs.
        listener = db.collection("users")
            .whereField(FieldPath.documentID(), in: userIds)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot, error == nil else {
                    print("Error listening for players' locations: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                var updatedLocations: [String: CLLocationCoordinate2D] = [:]
                for document in snapshot.documents {
                    let data = document.data()
                    if let lat = data["latitude"] as? Double,
                       let lon = data["longitude"] as? Double {
                        updatedLocations[document.documentID] = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }
                }
                DispatchQueue.main.async {
                    self.playersLocations = updatedLocations
                }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
}
