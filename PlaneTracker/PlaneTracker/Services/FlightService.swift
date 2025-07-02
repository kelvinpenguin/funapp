import Foundation
import Combine
import CoreLocation

class FlightService: ObservableObject {
    @Published var flights: [Flight] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    
    // API Configuration
    private let openSkyBaseURL = "https://opensky-network.org/api"
    private let flightAwareBaseURL = "https://aeroapi.flightaware.com/aeroapi"
    private let aviationEdgeBaseURL = "https://aviation-edge.com/v2/public"
    
    // API Keys - These should be set by the user in settings
    private var flightAwareAPIKey: String?
    private var aviationEdgeAPIKey: String?
    
    init() {
        startRealTimeUpdates()
    }
    
    deinit {
        stopRealTimeUpdates()
    }
    
    // MARK: - Public Methods
    
    func startRealTimeUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.fetchAllFlights()
        }
        fetchAllFlights() // Initial fetch
    }
    
    func stopRealTimeUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func refreshFlights() {
        fetchAllFlights()
    }
    
    func setAPIKeys(flightAware: String?, aviationEdge: String?) {
        self.flightAwareAPIKey = flightAware
        self.aviationEdgeAPIKey = aviationEdge
    }
    
    // MARK: - API Calls
    
    private func fetchAllFlights() {
        isLoading = true
        errorMessage = nil
        
        // Primary source: OpenSky Network (free, no API key required)
        fetchFromOpenSky()
    }
    
    private func fetchFromOpenSky() {
        guard let url = URL(string: "\(openSkyBaseURL)/states/all") else {
            handleError(message: "Invalid URL")
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: FlightResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.handleError(message: "Failed to fetch flights: \(error.localizedDescription)")
                    }
                },
                receiveValue: { response in
                    self.processOpenSkyResponse(response)
                }
            )
            .store(in: &cancellables)
    }
    
    private func processOpenSkyResponse(_ response: FlightResponse) {
        guard let states = response.states else {
            handleError(message: "No flight data received")
            return
        }
        
        let newFlights = states.compactMap { stateVector -> Flight? in
            // Filter out flights without position data
            guard stateVector.count >= 17,
                  let lat = stateVector[6], !lat.isEmpty,
                  let lon = stateVector[5], !lon.isEmpty else {
                return nil
            }
            return Flight(from: stateVector)
        }
        
        DispatchQueue.main.async {
            self.flights = newFlights
            self.lastUpdateTime = Date()
            self.isLoading = false
        }
    }
    
    // MARK: - Flight Details
    
    func fetchFlightDetails(for icao24: String) -> AnyPublisher<Aircraft?, Error> {
        // This would use a more detailed API like FlightAware or Aviation Edge
        // For now, return a placeholder
        return Just(nil)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchFlightRoute(for icao24: String, callsign: String) -> AnyPublisher<FlightRoute?, Error> {
        guard let url = URL(string: "\(openSkyBaseURL)/flights/aircraft") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "icao24", value: icao24),
            URLQueryItem(name: "begin", value: String(Int(Date().timeIntervalSince1970) - 86400)), // Last 24 hours
            URLQueryItem(name: "end", value: String(Int(Date().timeIntervalSince1970)))
        ]
        
        guard let finalURL = components?.url else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: finalURL)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: [FlightRoute].self, decoder: JSONDecoder())
            .map { routes in routes.first }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Location-based Search
    
    func fetchFlightsInBoundingBox(
        north: Double,
        south: Double,
        east: Double,
        west: Double
    ) -> AnyPublisher<[Flight], Error> {
        var components = URLComponents(string: "\(openSkyBaseURL)/states/all")
        components?.queryItems = [
            URLQueryItem(name: "lamin", value: String(south)),
            URLQueryItem(name: "lamax", value: String(north)),
            URLQueryItem(name: "lomin", value: String(west)),
            URLQueryItem(name: "lomax", value: String(east))
        ]
        
        guard let url = components?.url else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: FlightResponse.self, decoder: JSONDecoder())
            .map { response in
                guard let states = response.states else { return [] }
                return states.compactMap { stateVector -> Flight? in
                    guard stateVector.count >= 17,
                          let lat = stateVector[6], !lat.isEmpty,
                          let lon = stateVector[5], !lon.isEmpty else {
                        return nil
                    }
                    return Flight(from: stateVector)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Flight Search
    
    func searchFlights(by callsign: String) -> AnyPublisher<[Flight], Error> {
        return Just(flights.filter { flight in
            guard let flightCallsign = flight.callsign else { return false }
            return flightCallsign.lowercased().contains(callsign.lowercased())
        })
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    private func handleError(message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.isLoading = false
        }
    }
    
    // MARK: - Mock Data for Testing
    
    #if DEBUG
    func loadMockData() {
        let mockFlights = [
            createMockFlight(
                icao24: "abc123",
                callsign: "UAL123",
                country: "United States",
                lat: 37.7749,
                lon: -122.4194,
                altitude: 35000,
                velocity: 450
            ),
            createMockFlight(
                icao24: "def456",
                callsign: "DAL456",
                country: "United States",
                lat: 40.7128,
                lon: -74.0060,
                altitude: 28000,
                velocity: 420
            ),
            createMockFlight(
                icao24: "ghi789",
                callsign: "AAL789",
                country: "United States",
                lat: 34.0522,
                lon: -118.2437,
                altitude: 32000,
                velocity: 480
            )
        ]
        
        DispatchQueue.main.async {
            self.flights = mockFlights
            self.lastUpdateTime = Date()
            self.isLoading = false
        }
    }
    
    private func createMockFlight(
        icao24: String,
        callsign: String,
        country: String,
        lat: Double,
        lon: Double,
        altitude: Double,
        velocity: Double
    ) -> Flight {
        let stateVector: [String?] = [
            icao24,
            callsign,
            country,
            String(Int(Date().timeIntervalSince1970)),
            String(Int(Date().timeIntervalSince1970)),
            String(lon),
            String(lat),
            String(altitude),
            "false",
            String(velocity),
            "90",
            "0",
            nil,
            String(altitude),
            nil,
            "false",
            "0"
        ]
        return Flight(from: stateVector)
    }
    #endif
}

// MARK: - Network Utilities

extension FlightService {
    private func makeRequest(url: URL, apiKey: String? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
}