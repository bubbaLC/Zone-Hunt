//EditGameSettings.Swift
import SwiftUI
import MapKit
import FirebaseFirestore
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
    let mapView: MKMapView
    init(circle: MKCircle, mapView: MKMapView) {
        self.circleOverlay = circle
        self.mapView = mapView
        super.init(overlay: circle)
    }
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        // Get the rect for the entire world map projection
        let fullMapRect = self.rect(for: MKMapRect.world)
        // Fill the entire map with a semi-transparent purple color
        context.setFillColor(UIColor.purple.withAlphaComponent(0.3).cgColor)
        context.fill(fullMapRect)
        // Get the rect for the circle overlay
        let circleRect = self.rect(for: circleOverlay.boundingMapRect)
        // Clear the circle area to make it transparent
        context.setBlendMode(.clear)
        context.fillEllipse(in: circleRect)
        // Restore normal drawing mode and draw the red border
        context.setBlendMode(.normal)
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(300.0) // Adjust as needed for a visible border
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
    @State private var region: MKCoordinateRegion
    @State private var userTrackingMode: MKUserTrackingMode = .follow
    @State private var zoneRadius: Double
    
    private let lobbyId: String
    private let hostLocation: CLLocationCoordinate2D
    private let initialRadius: Double

    var body: some View {
        VStack {
            Text("Edit Game Settings")
                .font(.title)
                .padding(.top, 20)
            
            ZStack {
                // Use renamed GameMapView here
                GameMapView(region: $region, userTrackingMode: $userTrackingMode, radius: $zoneRadius)
                    .frame(height: 300)
                    .cornerRadius(15)
                    .padding()
                
                // Text Overlay for zone radius
                VStack {
                    Spacer()
                    Text("Radius of Zone Border: \(Int(zoneRadius)) meters")
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                }
            }
            
            // Adjustable Slider for Zone Radius
            Slider(value: $zoneRadius, in: 100...2000, step: 50) // Slider range from 100m to 2000m
                .accentColor(.red)
                .padding()
            Button(action: {
                            // Call saveSettings and then dismiss
                            saveSettings()
                        }){
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
        // .navigationBarHidden(true)
    }
    
    init(lobbyId: String, hostLocation: CLLocationCoordinate2D, initialRadius: Double) {
        self.lobbyId = lobbyId
        self.hostLocation = hostLocation
        self.initialRadius = initialRadius
        
        // Initialize state variables using the passed values
        _region = State(initialValue: MKCoordinateRegion(
            center: hostLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // Keep span or adjust as needed
        ))
        _zoneRadius = State(initialValue: initialRadius)
    }
    
    func saveSettings() {
        let db = Firestore.firestore()
        db.collection("lobbies").document(lobbyId).updateData([
            "zoneRadius": zoneRadius
        ]) { error in
            if let error = error {
                print("Error updating zone radius: \(error.localizedDescription)")
                // Optionally show an error message to the user
            } else {
                print("Zone radius successfully updated in Firestore for lobby \(lobbyId)")
                dismiss() // Dismiss the view on successful save
            }
        }
    }
}

// Update PreviewProvider if necessary, or comment it out if it causes issues
//struct EditGameSettings_Previews: PreviewProvider {
//    static var previews: some View {
//        // Provide sample data for preview
//        EditGameSettings(
//            lobbyId: "previewLobby",
//            hostLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
//            initialRadius: 500.0
//        )
//    }
//}
