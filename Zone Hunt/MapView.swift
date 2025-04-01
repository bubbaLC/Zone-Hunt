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
        
        // Remove previous user location annotation to prevent duplicates
        uiView.removeAnnotations(uiView.annotations)
        
        // Update user's annotation dynamically
        if let userLocation = userLocation {
            userAnnotation.coordinate = userLocation
            uiView.addAnnotation(userAnnotation)
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
            // Skip default user location annotation
            if annotation is MKUserLocation {
                return nil
            }

            let identifier = "UserLocationMarker"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if view == nil {
                let size: CGFloat = 20
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.frame.size = CGSize(width: size, height: size)
                view?.canShowCallout = false

                // Create a solid blue circle
                let circleView = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
                circleView.backgroundColor = UIColor.blue
                circleView.layer.cornerRadius = size / 2  // Make it a circle
                circleView.layer.borderColor = UIColor.white.cgColor
                circleView.layer.borderWidth = 2  // Optional: Adds a clean white outline

                view?.addSubview(circleView)
            } else {
                view?.annotation = annotation
            }

            return view
        }

        
//        func addBlinkingAnimation(to view: MKAnnotationView) {
//            let blinkAnimation = CABasicAnimation(keyPath: "opacity")
//            blinkAnimation.fromValue = 1.0
//            blinkAnimation.toValue = 0.3
//            blinkAnimation.duration = 0.8
//            blinkAnimation.autoreverses = true
//            blinkAnimation.repeatCount = .infinity
//            view.layer.add(blinkAnimation, forKey: "blink")
//        }
//        func addPulsingAnimation(to view: MKAnnotationView) {
//            let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
//            pulseAnimation.fromValue = 1.0
//            pulseAnimation.toValue = 1.4
//            pulseAnimation.duration = 1.2  // Slower pulse for smooth effect
//            pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//            pulseAnimation.autoreverses = true
//            pulseAnimation.repeatCount = .infinity
//
//            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
//            fadeAnimation.fromValue = 1.0
//            fadeAnimation.toValue = 0.5
//            fadeAnimation.duration = 1.2
//            fadeAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//            fadeAnimation.autoreverses = true
//            fadeAnimation.repeatCount = .infinity
//
//            let animationGroup = CAAnimationGroup()
//            animationGroup.animations = [pulseAnimation, fadeAnimation]
//            animationGroup.duration = 1.2
//            animationGroup.repeatCount = .infinity
//
//            view.layer.add(animationGroup, forKey: "pulse")
//        }
    }
}
