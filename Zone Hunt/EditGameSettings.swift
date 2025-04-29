//EditGameSettings.Swift
import SwiftUI
import MapKit
import CoreLocation
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
// Rename MapView to GameMapView
struct GameMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var userTrackingMode: MKUserTrackingMode
    @Binding var radius: Double
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = userTrackingMode
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)
        uiView.removeOverlays(uiView.overlays) // Remove existing overlays
        
        // Add circle overlay
        let circle = MKCircle(center: region.center, radius: radius)
        uiView.addOverlay(circle)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
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
    }
}
// Custom renderer to handle the purple tint outside the circle
class PurpleTintRenderer: MKOverlayRenderer {
    let circleOverlay: MKCircle
    init(circle: MKCircle, mapView: MKMapView) {
        self.circleOverlay = circle
        super.init(overlay: circle)
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let worldRect = self.rect(for: MKMapRect.world) // Entire world, not just visible screen
        
        // Fill the whole world with purple
        context.setFillColor(UIColor.purple.withAlphaComponent(0.3).cgColor)
        context.fill(worldRect)
        
        // Then cut out the circle (the clear game zone)
        let circleRect = self.rect(for: circleOverlay.boundingMapRect)
        context.setBlendMode(.clear)
        context.fillEllipse(in: circleRect)
        
        // Draw red border around the clear zone
        context.setBlendMode(.normal)
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(300.0) // Clean thin red outline
        context.strokeEllipse(in: circleRect)
    }
}

/* old function */
//func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//            if let circleOverlay = overlay as? MKCircle {
//                let renderer = MKCircleRenderer(circle: circleOverlay)
//                renderer.strokeColor = .red
//                renderer.lineWidth = 3
//                return renderer
//            }
//            return MKOverlayRenderer()
//             }
struct EditGameSettings: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0), // default until updated
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var userTrackingMode: MKUserTrackingMode = .follow
    @State private var zoneRadius: Double = 500
    @State private var userLocation: CLLocationCoordinate2D? = nil

    var body: some View {
        VStack {
            Text("Edit Game Settings")
                .font(.title)
                .padding(.top, 20)

            ZStack {
                GameMapView(region: $region, userTrackingMode: $userTrackingMode, radius: $zoneRadius)
                    .frame(height: 300)
                    .cornerRadius(15)
                    .padding()
                    .onAppear {
                        if let userLoc = locationManager.location {
                            userLocation = userLoc
                            region.center = userLoc
                        }
                    }
                    .onChange(of: locationManager.location) { newLocation in
                        if let newLoc = newLocation {
                            userLocation = newLoc
                            region.center = newLoc
                        }
                    }

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
                    .padding(.top,10)
                    .padding(.bottom, 65)
            }
        }
    }

    private var gameView: CreateGameView
    init(gameView: CreateGameView) {
        self.gameView = gameView;
    }
}

struct EditGameSettings_Previews: PreviewProvider {
    static var previews: some View {
        EditGameSettings(gameView: CreateGameView())
    }
}
