import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    let flights: [Flight]
    let flightService: FlightService
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.0, longitude: -100.0),
        span: MKCoordinateSpan(latitudeDelta: 50.0, longitudeDelta: 50.0)
    )
    @State private var selectedFlight: Flight?
    @State private var showingFlightDetail = false
    @State private var mapStyle: MapStyle = .standard
    @State private var showTraffic = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(coordinateRegion: $region, annotationItems: flights) { flight in
                MapAnnotation(coordinate: flight.coordinate ?? CLLocationCoordinate2D()) {
                    FlightAnnotationView(flight: flight)
                        .onTapGesture {
                            selectedFlight = flight
                            showingFlightDetail = true
                        }
                }
            }
            .mapStyle(mapStyle)
            .onAppear {
                updateRegionToShowAllFlights()
            }
            .onChange(of: flights) { _ in
                updateRegionToShowAllFlights()
            }
            
            // Map Controls
            VStack(spacing: 12) {
                MapControlsView(
                    mapStyle: $mapStyle,
                    showTraffic: $showTraffic,
                    onZoomToFlights: updateRegionToShowAllFlights
                )
                
                // Flight count badge
                FlightCountBadge(count: flights.count)
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showingFlightDetail) {
            if let flight = selectedFlight {
                FlightDetailView(flight: flight, flightService: flightService)
            }
        }
    }
    
    private func updateRegionToShowAllFlights() {
        guard !flights.isEmpty else { return }
        
        let coordinates = flights.compactMap { $0.coordinate }
        guard !coordinates.isEmpty else { return }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.2, 0.1),
            longitudeDelta: max((maxLon - minLon) * 1.2, 0.1)
        )
        
        withAnimation(.easeInOut(duration: 1.0)) {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
}

// MARK: - Flight Annotation View

struct FlightAnnotationView: View {
    let flight: Flight
    
    var rotationAngle: Double {
        return flight.trueTrack ?? 0
    }
    
    var annotationColor: Color {
        if flight.onGround {
            return .gray
        } else if let altitude = flight.altitudeInFeet {
            if altitude > 30000 {
                return .blue
            } else if altitude > 15000 {
                return .green
            } else {
                return .orange
            }
        }
        return .red
    }
    
    var body: some View {
        ZStack {
            // Airplane icon
            Image(systemName: "airplane")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(rotationAngle))
            
            // Background circle
            Circle()
                .fill(annotationColor)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
        }
        .scaleEffect(flight.onGround ? 0.8 : 1.0)
        .opacity(flight.onGround ? 0.7 : 1.0)
    }
}

// MARK: - Map Controls

struct MapControlsView: View {
    @Binding var mapStyle: MapStyle
    @Binding var showTraffic: Bool
    let onZoomToFlights: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Map style selector
            Menu {
                Button("Standard") { mapStyle = .standard }
                Button("Satellite") { mapStyle = .imagery }
                Button("Hybrid") { mapStyle = .hybrid }
            } label: {
                Image(systemName: "map")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            
            // Zoom to all flights
            Button(action: onZoomToFlights) {
                Image(systemName: "scope")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
        }
    }
}

// MARK: - Flight Count Badge

struct FlightCountBadge: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "airplane")
                .font(.caption)
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Map Style Extension

extension MapStyle {
    static let standard = MapStyle.standard(elevation: .flat, emphasis: .automatic, pointsOfInterest: .including([.airport]))
    static let imagery = MapStyle.imagery(elevation: .flat)
    static let hybrid = MapStyle.hybrid(elevation: .flat, pointsOfInterest: .including([.airport]))
}

#Preview {
    MapView(flights: [], flightService: FlightService())
}