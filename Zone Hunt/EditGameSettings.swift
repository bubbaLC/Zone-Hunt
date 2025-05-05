// EditGameSettings.swift
import SwiftUI
import MapKit
import CoreLocation

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

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
        uiView.removeOverlays(uiView.overlays)

        // Add the editor preview circle overlay
        let circle = MKCircle(center: region.center, radius: radius)
        uiView.addOverlay(circle)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: GameMapView
        init(_ parent: GameMapView) { self.parent = parent }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let circle = overlay as? MKCircle else {
                return MKOverlayRenderer(overlay: overlay)
            }
            // Use the editor-specific tint renderer
            return EditorTintRenderer(circle: circle)
        }
    }
}

// Editor-only renderer (purple outside, clear inside, red border)
class EditorTintRenderer: MKOverlayRenderer {
    private let circleOverlay: MKCircle

    init(circle: MKCircle) {
        self.circleOverlay = circle
        super.init(overlay: circle)
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        // 1) Fill whole world in semi-transparent purple
        let worldRect = rect(for: MKMapRect.world)
        context.setFillColor(UIColor.purple.withAlphaComponent(0.3).cgColor)
        context.fill(worldRect)

        // 2) Clear out the safe zone
        let circleRect = rect(for: circleOverlay.boundingMapRect)
        context.setBlendMode(.clear)
        context.fillEllipse(in: circleRect)

        // 3) Draw the red border
        context.setBlendMode(.normal)
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(3 / zoomScale)
        context.strokeEllipse(in: circleRect)
    }
}

struct EditGameSettings: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationManager()
    @Binding var zoneRadius: Double

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var userTrackingMode: MKUserTrackingMode = .follow
    @State private var userLocation: CLLocationCoordinate2D? = nil

    var body: some View {
        VStack {
            Text("Edit Game Settings")
                .font(.title)
                .padding(.top, 20)

            ZStack {
                GameMapView(
                    region: $region,
                    userTrackingMode: $userTrackingMode,
                    radius: $zoneRadius
                )
                .frame(height: 300)
                .cornerRadius(15)
                .padding()
                .onAppear {
                    if let loc = locationManager.location {
                        userLocation = loc
                        region.center = loc
                    }
                }
                .onChange(of: locationManager.location) { newLoc in
                    if let loc = newLoc {
                        userLocation = loc
                        region.center = loc
                    }
                }

                VStack {
                    Spacer()
                    Text("Radius: \(Int(zoneRadius)) m")
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                }
            }

            Slider(value: $zoneRadius, in: 100...2000, step: 50)
                .accentColor(.red)
                .padding()

            Button("Save Settings") {
                dismiss()
            }
            .font(.title2).fontWeight(.bold)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .cornerRadius(10)
            .padding(.horizontal, 25)
            .padding(.vertical, 20)
        }
    }
}

struct EditGameSettings_Previews: PreviewProvider {
    static var previews: some View {
        EditGameSettings(zoneRadius: .constant(500))
    }
}
