import SwiftUI
import MapKit
import CoreLocation

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var radius: Double
    @Binding var userLocation: CLLocationCoordinate2D? // Binding for user's coordinates
    let locationManager = CLLocationManager()
    var onExit: () -> Void // Callback for leaving the lobby
    let mapView = MKMapView() // Keep reference to the mapView
    let userAnnotation = MKPointAnnotation() // Store annotation reference

    func makeUIView(context: Context) -> MKMapView {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.showsUserLocation = false  // Hide default blue dot since we add a custom one
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.delegate = context.coordinator
        
        locationManager.delegate = context.coordinator
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)
        
        // Update user's annotation dynamically
        if let userLocation = userLocation {
            userAnnotation.coordinate = userLocation
            if !uiView.annotations.contains(where: { $0 === userAnnotation }) {
                uiView.addAnnotation(userAnnotation) // Add only if not already present
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if let location = locations.first {
                DispatchQueue.main.async {
                    self.parent.userLocation = location.coordinate
                    self.parent.region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Skip the default user location annotation
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "UserLocationMarker"
            var view: MKAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if view == nil {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.canShowCallout = false
                view?.image = UIImage(systemName: "circle.fill")
                view?.tintColor = .red
                view?.frame.size = CGSize(width: 30, height: 30)
                addBlinkingAnimation(to: view!)
            } else {
                view?.annotation = annotation
            }
            
            return view
        }
        
        func addBlinkingAnimation(to view: MKAnnotationView) {
            let blinkAnimation = CABasicAnimation(keyPath: "opacity")
            blinkAnimation.fromValue = 1.0
            blinkAnimation.toValue = 0.3
            blinkAnimation.duration = 0.8
            blinkAnimation.autoreverses = true
            blinkAnimation.repeatCount = .infinity
            view.layer.add(blinkAnimation, forKey: "blink")
        }
    }
}
