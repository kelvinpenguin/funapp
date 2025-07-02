import SwiftUI
import MapKit
import CoreLocation

struct FlightDetailView: View {
    let flight: Flight
    let flightService: FlightService
    @Environment(\.dismiss) private var dismiss
    
    @State private var aircraft: Aircraft?
    @State private var flightRoute: FlightRoute?
    @State private var isLoadingDetails = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Flight Header
                    FlightHeaderView(flight: flight)
                    
                    // Flight Map
                    FlightMapView(flight: flight)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    
                    // Flight Details
                    FlightDetailsSection(flight: flight)
                    
                    // Aircraft Information
                    if let aircraft = aircraft {
                        AircraftInfoSection(aircraft: aircraft)
                    }
                    
                    // Route Information
                    if let route = flightRoute {
                        RouteInfoSection(route: route)
                    }
                    
                    // Technical Data
                    TechnicalDataSection(flight: flight)
                }
                .padding(.vertical)
            }
            .navigationTitle("Flight Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadFlightDetails()
            }
        }
    }
    
    private func loadFlightDetails() {
        isLoadingDetails = true
        
        // Load aircraft details
        flightService.fetchFlightDetails(for: flight.icao24)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { aircraft in
                    self.aircraft = aircraft
                }
            )
            .store(in: &cancellables)
        
        // Load flight route
        flightService.fetchFlightRoute(for: flight.icao24, callsign: flight.formattedCallsign)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in
                    self.isLoadingDetails = false
                },
                receiveValue: { route in
                    self.flightRoute = route
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

// MARK: - Flight Header View

struct FlightHeaderView: View {
    let flight: Flight
    
    var body: some View {
        VStack(spacing: 12) {
            // Callsign and Status
            HStack {
                Text(flight.formattedCallsign)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                StatusBadge(isActive: !flight.onGround)
            }
            
            // Origin Country
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.blue)
                Text(flight.originCountry)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // ICAO24
            HStack {
                Text("Aircraft ID:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(flight.icao24.uppercased())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospaced()
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Flight Map View

struct FlightMapView: View {
    let flight: Flight
    
    private var region: MKCoordinateRegion {
        guard let coordinate = flight.coordinate else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            )
        }
        
        return MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        )
    }
    
    var body: some View {
        Map(coordinateRegion: .constant(region), annotationItems: [flight]) { flight in
            MapAnnotation(coordinate: flight.coordinate ?? CLLocationCoordinate2D()) {
                FlightAnnotationView(flight: flight)
                    .scaleEffect(1.5)
            }
        }
        .disabled(true)
    }
}

// MARK: - Flight Details Section

struct FlightDetailsSection: View {
    let flight: Flight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Flight Information", icon: "airplane")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let coordinate = flight.coordinate {
                    DetailCardView(
                        title: "Position",
                        value: "\(coordinate.latitude, specifier: "%.4f")°, \(coordinate.longitude, specifier: "%.4f")°",
                        icon: "location"
                    )
                }
                
                if let altitude = flight.altitudeInFeet {
                    DetailCardView(
                        title: "Altitude",
                        value: "\(Int(altitude)) ft",
                        icon: "arrow.up"
                    )
                }
                
                if let speed = flight.speedInKnots {
                    DetailCardView(
                        title: "Ground Speed",
                        value: "\(Int(speed)) kts",
                        icon: "speedometer"
                    )
                }
                
                if let track = flight.trueTrack {
                    DetailCardView(
                        title: "Heading",
                        value: "\(Int(track))°",
                        icon: "compass"
                    )
                }
                
                if let verticalRate = flight.verticalRate {
                    let direction = verticalRate > 0 ? "Climbing" : verticalRate < 0 ? "Descending" : "Level"
                    DetailCardView(
                        title: "Vertical Rate",
                        value: "\(abs(Int(verticalRate))) ft/min \(direction)",
                        icon: verticalRate > 0 ? "arrow.up.right" : verticalRate < 0 ? "arrow.down.right" : "minus"
                    )
                }
                
                DetailCardView(
                    title: "On Ground",
                    value: flight.onGround ? "Yes" : "No",
                    icon: flight.onGround ? "airplane.arrival" : "airplane.departure"
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Aircraft Info Section

struct AircraftInfoSection: View {
    let aircraft: Aircraft
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Aircraft Information", icon: "wrench.and.screwdriver")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let model = aircraft.model {
                    DetailCardView(title: "Model", value: model, icon: "airplane")
                }
                
                if let registration = aircraft.registration {
                    DetailCardView(title: "Registration", value: registration, icon: "tag")
                }
                
                if let manufacturer = aircraft.manufacturerName {
                    DetailCardView(title: "Manufacturer", value: manufacturer, icon: "building.2")
                }
                
                if let operator = aircraft.operator {
                    DetailCardView(title: "Operator", value: operator, icon: "person.3")
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Route Info Section

struct RouteInfoSection: View {
    let route: FlightRoute
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Route Information", icon: "map")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let departure = route.estDepartureAirport {
                    DetailCardView(title: "Departure", value: departure, icon: "airplane.departure")
                }
                
                if let arrival = route.estArrivalAirport {
                    DetailCardView(title: "Arrival", value: arrival, icon: "airplane.arrival")
                }
                
                DetailCardView(
                    title: "Departure Time",
                    value: formatDate(route.departureTime),
                    icon: "clock"
                )
                
                DetailCardView(
                    title: "Arrival Time",
                    value: formatDate(route.arrivalTime),
                    icon: "clock.fill"
                )
            }
        }
        .padding(.horizontal)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Technical Data Section

struct TechnicalDataSection: View {
    let flight: Flight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Technical Data", icon: "gear")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DetailCardView(
                    title: "ICAO24",
                    value: flight.icao24.uppercased(),
                    icon: "tag"
                )
                
                if let squawk = flight.squawk {
                    DetailCardView(title: "Squawk", value: squawk, icon: "radio")
                }
                
                DetailCardView(
                    title: "Last Contact",
                    value: formatTimestamp(flight.lastContact),
                    icon: "antenna.radiowaves.left.and.right"
                )
                
                if let timePosition = flight.timePosition {
                    DetailCardView(
                        title: "Position Time",
                        value: formatTimestamp(timePosition),
                        icon: "clock"
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func formatTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Helper Views

struct SectionHeaderView: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

struct DetailCardView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    let mockFlight = Flight(from: [
        "abc123",
        "UAL123",
        "United States",
        String(Int(Date().timeIntervalSince1970)),
        String(Int(Date().timeIntervalSince1970)),
        "-122.4194",
        "37.7749",
        "35000",
        "false",
        "450",
        "90",
        "0",
        nil,
        "35000",
        nil,
        "false",
        "0"
    ])
    
    FlightDetailView(flight: mockFlight, flightService: FlightService())
}