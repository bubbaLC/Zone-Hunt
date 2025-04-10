// MapView.swift
import SwiftUI
import MapKit
import CoreLocation
import FirebaseAuth

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var radius: Double
    @Binding var userLocation: CLLocationCoordinate2D?
    var playersLocations: [String: CLLocationCoordinate2D] // Provided from PlayersLocationViewModel
    let onExit: () -> Void
    let mapView = MKMapView()
    let userAnnotation = MKPointAnnotation()
    
    func makeUIView(context: Context) -> MKMapView {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        // We disable the default blue dot since we’re using a custom annotation.
        mapView.showsUserLocation = false
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.delegate = context.coordinator
        
        // Configure location manager via coordinator.
        context.coordinator.locationManager.requestWhenInUseAuthorization()
        context.coordinator.locationManager.startUpdatingLocation()

        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update the region to re-center the map.
        uiView.setRegion(region, animated: true)
        
        // Remove all annotations so we can add updated ones.
        uiView.removeAnnotations(uiView.annotations)
        
        // Add custom user location annotation.
        if let userLoc = userLocation {
            userAnnotation.coordinate = userLoc
            userAnnotation.title = "You"
            uiView.addAnnotation(userAnnotation)
        } else {
            print("userLocation is nil")
        }
        
        // Add annotations for players.
        for (playerId, coordinate) in playersLocations {
            // Optionally exclude the current user.
            if let currentUserId = Auth.auth().currentUser?.uid, currentUserId == playerId {
                continue
            }
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Player \(playerId)" // Alternatively use a username if available.
            uiView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        var parent: MapView
        let locationManager = CLLocationManager()
        
        init(_ parent: MapView) {
            self.parent = parent
            super.init()
            locationManager.delegate = self
        }
        
        // MARK: - CLLocationManagerDelegate Methods
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if let location = locations.first {
                DispatchQueue.main.async {
                    self.parent.userLocation = location.coordinate
                    // Update the region to center on the new location.
                    self.parent.region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                    print("Updated location: \(location.coordinate)")
                }
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
        
        // MARK: - MKMapViewDelegate Method for Custom Annotation Views
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Skip the default user location annotation.
            if annotation is MKUserLocation { return nil }
            
            let identifier = "UserLocationMarker"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if view == nil {
                // Increase the size for better visibility.
                let size: CGFloat = 25
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.frame = CGRect(x: 0, y: 0, width: size, height: size)
                view?.canShowCallout = true
                
                // Create a circular view.
                let circleView = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
                // Use a distinctive color for "You" vs. other players.
                if annotation.title ?? "" == "You" {
                    circleView.backgroundColor = UIColor.systemBlue
                } else {
                    circleView.backgroundColor = UIColor.red
                }
                circleView.layer.cornerRadius = size / 2
                circleView.layer.borderWidth = 2
                circleView.layer.borderColor = UIColor.white.cgColor
                
                // Ensure we remove any previous subviews.
                view?.subviews.forEach { $0.removeFromSuperview() }
                view?.addSubview(circleView)
            } else {
                view?.annotation = annotation
            }
            
            return view
        }
    }
}
