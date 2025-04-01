//  LocationManager.swift
// Created by Liam Colton on 3/10/24
import Foundation
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocationCoordinate2D?
    
    private let locationManager = CLLocationManager()
    private var completionHandler: ((CLLocationCoordinate2D?) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone // Get updates as fast as possible
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    
    /// Requests a one-time location update.
    func requestLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        completionHandler = completion
        locationManager.requestLocation()
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
        print("Requested location permission")
    }
    
    /// Starts continuous location updates.
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    /// Stops continuous location updates.
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last?.coordinate else {
            completionHandler?(nil)
            return
        }
        
        DispatchQueue.main.async {
            self.location = newLocation
            self.updateUserLocationInFirestore(latitude: newLocation.latitude, longitude: newLocation.longitude)
            self.completionHandler?(newLocation)
            self.completionHandler = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.completionHandler?(nil)
            self.completionHandler = nil
        }
    }
    
    /// Updates the user's latitude and longitude in Firestore.
    private func updateUserLocationInFirestore(latitude: Double, longitude: Double) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("users").document(userId).updateData([
            "latitude": latitude,
            "longitude": longitude
        ]) { error in
            if let error = error {
                print("Error updating location in Firestore: \(error.localizedDescription)")
            }
        }
    }
}
