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
    // Track if the map has already been centered on the user's location
    @State private var isInitialRegionSet: Bool = false
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.delegate = context.coordinator
        
        locationManager.delegate = context.coordinator
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        return mapView
    }
    func updateUIView(_ uiView: MKMapView, context: Context) {
        if !isInitialRegionSet {
            // Center the map on the user's location initially
            uiView.setRegion(region, animated: true)
            isInitialRegionSet = true
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
        // Update the region based on the user's location, but only once at the start
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if let location = locations.first, !parent.isInitialRegionSet {
                // Center on user's location initially
                parent.region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
        // Customize the appearance of the user's location (the blinking dot)
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            if let annotationView = mapView.view(for: userLocation) {
                annotationView.image = UIImage(systemName: "circle.fill")
                annotationView.tintColor = UIColor.red
                annotationView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
                addBlinkingAnimation(to: annotationView)
            }
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


