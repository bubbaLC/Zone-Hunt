//
//  MapView.swift
//  Zone Hunt
//
//  Created by Liam Colton on 9/10/24.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var radius: Double
    @Binding var userLocation: CLLocationCoordinate2D? // Binding for user's coordinates
    let locationManager = CLLocationManager()
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.showsUserLocation = true  // Default blue dot for user's location
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
        // If user location is updated, update the red dot on the map
        if let userLocation = userLocation {
            let coordinate = userLocation
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            uiView.addAnnotation(annotation)
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
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
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
            var view: MKAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                view = dequeuedView
            } else {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = false
            }
            
            // Set custom red dot for user location
            view.image = UIImage(systemName: "circle.fill")
            view.tintColor = .red
            view.frame.size = CGSize(width: 30, height: 30)
            addBlinkingAnimation(to: view)
            
            return view
        }
        
        func addBlinkingAnimation(to view: MKAnnotationView) {
            let blinkAnimation = CABasicAnimation(keyPath: "opacity")
            blinkAnimation.fromValue = 1.0
            blinkAnimation.toValue = 0.0
            blinkAnimation.duration = 0.5
            blinkAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            blinkAnimation.autoreverses = true
            blinkAnimation.repeatCount = .infinity
            view.layer.add(blinkAnimation, forKey: "blink")
        }
    }
}
