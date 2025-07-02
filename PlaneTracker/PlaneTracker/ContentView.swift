import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var flightService = FlightService()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var searchText = ""
    @State private var flightFilter = FlightFilter()
    
    var filteredFlights: [Flight] {
        if searchText.isEmpty && flightFilter.searchText.isEmpty {
            return flightService.flights
        }
        
        var filter = flightFilter
        if !searchText.isEmpty {
            filter.searchText = searchText
        }
        
        return flightService.flights.filter { filter.matches(flight: $0) }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Map View Tab
            NavigationView {
                MapView(flights: filteredFlights, flightService: flightService)
                    .navigationTitle("Live Flight Map")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gear")
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { flightService.refreshFlights() }) {
                                Image(systemName: "arrow.clockwise")
                            }
                            .disabled(flightService.isLoading)
                        }
                    }
            }
            .tabItem {
                Image(systemName: "map")
                Text("Map")
            }
            .tag(0)
            
            // Flight List Tab
            NavigationView {
                FlightListView(flights: filteredFlights, flightService: flightService)
                    .navigationTitle("Flights")
                    .searchable(text: $searchText, prompt: "Search flights...")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gear")
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { flightService.refreshFlights() }) {
                                Image(systemName: "arrow.clockwise")
                            }
                            .disabled(flightService.isLoading)
                        }
                    }
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Flights")
            }
            .tag(1)
            
            // Statistics Tab
            NavigationView {
                StatisticsView(flights: flightService.flights)
                    .navigationTitle("Statistics")
            }
            .tabItem {
                Image(systemName: "chart.bar")
                Text("Stats")
            }
            .tag(2)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(flightService: flightService, flightFilter: $flightFilter)
        }
        .overlay(
            Group {
                if flightService.isLoading && flightService.flights.isEmpty {
                    LoadingView()
                }
            }
        )
        .alert("Error", isPresented: .constant(flightService.errorMessage != nil)) {
            Button("OK") {
                flightService.errorMessage = nil
            }
        } message: {
            Text(flightService.errorMessage ?? "")
        }
    }
}

// MARK: - Flight List View

struct FlightListView: View {
    let flights: [Flight]
    let flightService: FlightService
    @State private var selectedFlight: Flight?
    
    var body: some View {
        List(flights) { flight in
            FlightRowView(flight: flight)
                .onTapGesture {
                    selectedFlight = flight
                }
        }
        .refreshable {
            flightService.refreshFlights()
        }
        .overlay(
            Group {
                if flights.isEmpty && !flightService.isLoading {
                    EmptyStateView()
                }
            }
        )
        .sheet(item: $selectedFlight) { flight in
            FlightDetailView(flight: flight, flightService: flightService)
        }
    }
}

// MARK: - Flight Row View

struct FlightRowView: View {
    let flight: Flight
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(flight.formattedCallsign)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    StatusBadge(isActive: !flight.onGround)
                }
                
                Text(flight.originCountry)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    if let altitude = flight.altitudeInFeet {
                        Label("\(Int(altitude)) ft", systemImage: "arrow.up")
                            .font(.caption)
                    }
                    
                    if let speed = flight.speedInKnots {
                        Label("\(Int(speed)) kts", systemImage: "speedometer")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let coordinate = flight.coordinate {
                    Text("\(coordinate.latitude, specifier: "%.2f")°")
                        .font(.caption)
                        .monospaced()
                    Text("\(coordinate.longitude, specifier: "%.2f")°")
                        .font(.caption)
                        .monospaced()
                }
                
                Text(flight.icao24.uppercased())
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Statistics View

struct StatisticsView: View {
    let flights: [Flight]
    
    private var totalFlights: Int { flights.count }
    private var airborneFlights: Int { flights.filter { !$0.onGround }.count }
    private var groundedFlights: Int { flights.filter { $0.onGround }.count }
    private var flightsByCountry: [(String, Int)] {
        Dictionary(grouping: flights, by: { $0.originCountry })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { ($0.key, $0.value) }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Overview Stats
                StatsCardView(title: "Total Flights", value: "\(totalFlights)", icon: "airplane")
                StatsCardView(title: "Airborne", value: "\(airborneFlights)", icon: "airplane.departure")
                StatsCardView(title: "On Ground", value: "\(groundedFlights)", icon: "airplane.arrival")
                
                // Flights by Country
                VStack(alignment: .leading, spacing: 12) {
                    Text("Flights by Country")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(flightsByCountry, id: \.0) { country, count in
                        HStack {
                            Text(country)
                                .font(.subheadline)
                            Spacer()
                            Text("\(count)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    let flightService: FlightService
    @Binding var flightFilter: FlightFilter
    @Environment(\.dismiss) private var dismiss
    
    @State private var flightAwareAPIKey = ""
    @State private var aviationEdgeAPIKey = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("API Configuration") {
                    SecureField("FlightAware API Key", text: $flightAwareAPIKey)
                    SecureField("Aviation Edge API Key", text: $aviationEdgeAPIKey)
                    
                    Button("Save API Keys") {
                        flightService.setAPIKeys(
                            flightAware: flightAwareAPIKey.isEmpty ? nil : flightAwareAPIKey,
                            aviationEdge: aviationEdgeAPIKey.isEmpty ? nil : aviationEdgeAPIKey
                        )
                    }
                }
                
                Section("Flight Filters") {
                    TextField("Country", text: $flightFilter.country)
                    
                    VStack(alignment: .leading) {
                        Text("Altitude Range (feet)")
                        HStack {
                            TextField("Min", value: $flightFilter.minAltitude, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text("to")
                            TextField("Max", value: $flightFilter.maxAltitude, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    Toggle("On Ground Only", isOn: $flightFilter.onGroundOnly)
                        .onChange(of: flightFilter.onGroundOnly) { newValue in
                            if newValue { flightFilter.airborneOnly = false }
                        }
                    
                    Toggle("Airborne Only", isOn: $flightFilter.airborneOnly)
                        .onChange(of: flightFilter.airborneOnly) { newValue in
                            if newValue { flightFilter.onGroundOnly = false }
                        }
                }
                
                Section("About") {
                    Label("PlaneTracker v1.0", systemImage: "airplane")
                    Label("Real-time flight tracking", systemImage: "info.circle")
                    Label("Data from OpenSky Network", systemImage: "globe")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views

struct StatusBadge: View {
    let isActive: Bool
    
    var body: some View {
        Text(isActive ? "AIRBORNE" : "GROUND")
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? Color.green : Color.gray)
            .cornerRadius(12)
    }
}

struct StatsCardView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.blue)
                .frame(width: 50)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Loading flights...")
                    .font(.headline)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No flights found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}