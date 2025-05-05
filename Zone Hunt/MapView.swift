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
        mapView.showsUserLocation = false
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.delegate = context.coordinator

        context.coordinator.locationManager.requestWhenInUseAuthorization()
        context.coordinator.locationManager.startUpdatingLocation()

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)

        // Remove previous annotations and overlays
        uiView.removeAnnotations(uiView.annotations)
        uiView.removeOverlays(uiView.overlays)

        // Add user annotation
        if let userLoc = userLocation {
            userAnnotation.coordinate = userLoc
            userAnnotation.title = "You"
            uiView.addAnnotation(userAnnotation)
        } else {
            print("userLocation is nil")
        }

        // Add other players' annotations
        for (playerId, coordinate) in playersLocations {
            if let currentUserId = Auth.auth().currentUser?.uid, currentUserId == playerId {
                continue
            }
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Player \(playerId)"
            uiView.addAnnotation(annotation)
        }

        // Add game zone overlay
        let zoneCircle = MKCircle(center: region.center, radius: radius)
        uiView.addOverlay(zoneCircle)
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

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if let location = locations.first {
                DispatchQueue.main.async {
                    self.parent.userLocation = location.coordinate
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

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            let identifier = "UserLocationMarker"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if view == nil {
                let size: CGFloat = 25
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.frame = CGRect(x: 0, y: 0, width: size, height: size)
                view?.canShowCallout = true

                let circleView = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
                if annotation.title ?? "" == "You" {
                    circleView.backgroundColor = UIColor.systemBlue
                } else {
                    circleView.backgroundColor = UIColor.red
                }
                circleView.layer.cornerRadius = size / 2
                circleView.layer.borderWidth = 2
                circleView.layer.borderColor = UIColor.white.cgColor

                view?.subviews.forEach { $0.removeFromSuperview() }
                view?.addSubview(circleView)
            } else {
                view?.annotation = annotation
            }

            return view
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let circle = overlay as? MKCircle else {
                return MKOverlayRenderer(overlay: overlay)
            }
            return PurpleTintRenderer(circle: circle, mapView: mapView)
        }
    }
}

// Custom circle renderer with purple tint and clear cut-out
class PurpleTintRenderer: MKOverlayRenderer {
    private let circleOverlay: MKCircle

    init(circle: MKCircle, mapView: MKMapView) {
        self.circleOverlay = circle
        super.init(overlay: circle)
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        // 1) Fill the visible area (mapRect) in semi-transparent purple
        let fillRect = rect(for: mapRect)
        context.setFillColor(UIColor.purple.withAlphaComponent(0.3).cgColor)
        context.fill(fillRect)

        // 2) “Cut out” the safe zone
        let circleRect = rect(for: circleOverlay.boundingMapRect)
        context.setBlendMode(.clear)
        context.fillEllipse(in: circleRect)

        // 3) Draw red border around the clear zone
        context.setBlendMode(.normal)
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(3 / zoomScale) // keep width consistent across zooms
        context.strokeEllipse(in: circleRect)
    }
}
