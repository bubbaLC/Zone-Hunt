//
//  EditGameSettings.swift
//  Zone Hunt
//
//  Created by Liam Colton on 10/7/24.
//

import SwiftUI
import MapKit
import CoreLocation

struct GameMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var userTrackingMode: MKUserTrackingMode
    @Binding var radius: Double
    @Binding var playerLocation: CLLocationCoordinate2D? // Player's current location
    
    let locationManager = CLLocationManager()
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = userTrackingMode
        mapView.delegate = context.coordinator
        locationManager.delegate = context.coordinator
        locationManager.requestWhenInUseAuthorization()

        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)
        uiView.removeOverlays(uiView.overlays) // Remove existing overlays
        
        // Add circle overlay
        let circle = MKCircle(center: region.center, radius: radius)
        uiView.addOverlay(circle)
        if let playerLocation = playerLocation {
                   // Remove existing annotations
                   uiView.removeAnnotations(uiView.annotations)

                   // Create and add a new annotation for the player
                   let playerAnnotation = MKPointAnnotation()
                   playerAnnotation.coordinate = playerLocation
                   uiView.addAnnotation(playerAnnotation)
               }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        var parent: GameMapView
        
        init(_ parent: GameMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circleOverlay = overlay as? MKCircle {
                return PurpleTintRenderer(circle: circleOverlay, mapView: mapView)
            }
            return MKOverlayRenderer()
        }
        
        // Implement CLLocationManagerDelegate methods as needed
    }
}

class PurpleTintRenderer: MKOverlayRenderer {
    let circleOverlay: MKCircle
    let mapView: MKMapView

    init(circle: MKCircle, mapView: MKMapView) {
        self.circleOverlay = circle
        self.mapView = mapView
        super.init(overlay: circle)
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let fullMapRect = self.rect(for: mapRect)

        context.setFillColor(UIColor.purple.withAlphaComponent(0.3).cgColor)
        context.fill(fullMapRect)

        let circleRect = self.rect(for: circleOverlay.boundingMapRect)

        context.setBlendMode(.clear)
        context.fillEllipse(in: circleRect)

        context.setBlendMode(.normal)
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(300.0)
        context.strokeEllipse(in: circleRect)
    }
}

struct EditGameSettings: View {
    @Environment(\.dismiss) var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var userTrackingMode: MKUserTrackingMode = .follow
    @State private var zoneRadius: Double = 500
    @State private var playerLocation: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    var body: some View {
        VStack {
            Text("Edit Game Settings")
                .font(.title)
                .padding(.top, 20)
            
            ZStack {
                GameMapView(region: $region, userTrackingMode: $userTrackingMode, radius: $zoneRadius, playerLocation: $playerLocation)
                    .frame(height: 300)
                    .cornerRadius(15)
                    .padding()
                
                VStack {
                    Spacer()
                    Text("Radius of Zone Border: \(Int(zoneRadius)) meters")
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                }
            }
            
            Slider(value: $zoneRadius, in: 100...2000, step: 50)
                .accentColor(.red)
                .padding()
            Button(action: {
                dismiss()
            }) {
                Text("Save Settings")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                    .padding(.horizontal, 25)
                    .padding(.top, 10)
                    .padding(.bottom, 65)
            }
        }
    }
}

struct EditGameSettings_Previews: PreviewProvider {
    static var previews: some View {
        EditGameSettings()
    }
}
