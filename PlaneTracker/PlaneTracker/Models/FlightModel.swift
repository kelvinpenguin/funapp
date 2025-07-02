import Foundation
import CoreLocation

// MARK: - Flight Data Models

struct FlightResponse: Codable {
    let states: [[String?]]?
    let time: Int?
}

struct Flight: Identifiable, Codable {
    let id = UUID()
    let icao24: String
    let callsign: String?
    let originCountry: String
    let timePosition: Int?
    let lastContact: Int
    let longitude: Double?
    let latitude: Double?
    let baroAltitude: Double?
    let onGround: Bool
    let velocity: Double?
    let trueTrack: Double?
    let verticalRate: Double?
    let geoAltitude: Double?
    let squawk: String?
    let spi: Bool?
    let positionSource: Int?
    
    // Computed properties
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var speedInKnots: Double? {
        guard let velocity = velocity else { return nil }
        return velocity * 1.94384 // Convert m/s to knots
    }
    
    var altitudeInFeet: Double? {
        guard let altitude = baroAltitude else { return nil }
        return altitude * 3.28084 // Convert meters to feet
    }
    
    var formattedCallsign: String {
        return callsign?.trimmingCharacters(in: .whitespaces) ?? "Unknown"
    }
    
    init(from stateVector: [String?]) {
        self.icao24 = stateVector[0] ?? ""
        self.callsign = stateVector[1]
        self.originCountry = stateVector[2] ?? ""
        self.timePosition = Int(stateVector[3] ?? "")
        self.lastContact = Int(stateVector[4] ?? "") ?? 0
        self.longitude = Double(stateVector[5] ?? "")
        self.latitude = Double(stateVector[6] ?? "")
        self.baroAltitude = Double(stateVector[7] ?? "")
        self.onGround = Bool(stateVector[8] ?? "") ?? false
        self.velocity = Double(stateVector[9] ?? "")
        self.trueTrack = Double(stateVector[10] ?? "")
        self.verticalRate = Double(stateVector[11] ?? "")
        self.geoAltitude = Double(stateVector[13] ?? "")
        self.squawk = stateVector[14]
        self.spi = Bool(stateVector[15] ?? "") ?? false
        self.positionSource = Int(stateVector[16] ?? "")
    }
}

// MARK: - Aircraft Information

struct Aircraft: Identifiable, Codable {
    let id = UUID()
    let icao24: String
    let registration: String?
    let manufacturerIcao: String?
    let manufacturerName: String?
    let model: String?
    let typecode: String?
    let serialNumber: String?
    let lineNumber: String?
    let icaoAircraftType: String?
    let operator: String?
    let operatorCallsign: String?
    let operatorIcao: String?
    let operatorIata: String?
    let owner: String?
    let categoryDescription: String?
    
    private enum CodingKeys: String, CodingKey {
        case icao24, registration, manufacturerIcao, manufacturerName
        case model, typecode, serialNumber, lineNumber, icaoAircraftType
        case operator, operatorCallsign, operatorIcao, operatorIata
        case owner, categoryDescription
    }
}

// MARK: - Airline Information

struct Airline: Identifiable, Codable {
    let id = UUID()
    let icaoCode: String
    let iataCode: String?
    let name: String
    let callsign: String?
    let country: String?
    let active: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case icaoCode, iataCode, name, callsign, country, active
    }
}

// MARK: - Airport Information

struct Airport: Identifiable, Codable {
    let id = UUID()
    let icao: String
    let iata: String?
    let name: String
    let city: String?
    let country: String?
    let latitude: Double?
    let longitude: Double?
    let altitude: Double?
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// MARK: - Flight Route Information

struct FlightRoute: Identifiable, Codable {
    let id = UUID()
    let callsign: String
    let icao24: String
    let firstSeen: Int
    let estDepartureAirport: String?
    let lastSeen: Int
    let estArrivalAirport: String?
    let estDepartureAirportHorizDistance: Int?
    let estDepartureAirportVertDistance: Int?
    let estArrivalAirportHorizDistance: Int?
    let estArrivalAirportVertDistance: Int?
    let departureAirportCandidatesCount: Int?
    let arrivalAirportCandidatesCount: Int?
    
    var departureTime: Date {
        return Date(timeIntervalSince1970: TimeInterval(firstSeen))
    }
    
    var arrivalTime: Date {
        return Date(timeIntervalSince1970: TimeInterval(lastSeen))
    }
}

// MARK: - Flight Status Enum

enum FlightStatus: String, CaseIterable {
    case scheduled = "scheduled"
    case active = "active"
    case landed = "landed"
    case cancelled = "cancelled"
    case incident = "incident"
    case diverted = "diverted"
    
    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .active: return "In Flight"
        case .landed: return "Landed"
        case .cancelled: return "Cancelled"
        case .incident: return "Incident"
        case .diverted: return "Diverted"
        }
    }
    
    var color: String {
        switch self {
        case .scheduled: return "blue"
        case .active: return "green"
        case .landed: return "gray"
        case .cancelled: return "red"
        case .incident: return "orange"
        case .diverted: return "yellow"
        }
    }
}

// MARK: - Search Filters

struct FlightFilter {
    var searchText: String = ""
    var country: String = ""
    var minAltitude: Double = 0
    var maxAltitude: Double = 50000
    var onGroundOnly: Bool = false
    var airborneOnly: Bool = false
    
    func matches(flight: Flight) -> Bool {
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            if let callsign = flight.callsign?.lowercased(),
               !callsign.contains(searchLower) &&
               !flight.icao24.lowercased().contains(searchLower) &&
               !flight.originCountry.lowercased().contains(searchLower) {
                return false
            }
        }
        
        if !country.isEmpty && flight.originCountry != country {
            return false
        }
        
        if let altitude = flight.altitudeInFeet {
            if altitude < minAltitude || altitude > maxAltitude {
                return false
            }
        }
        
        if onGroundOnly && !flight.onGround {
            return false
        }
        
        if airborneOnly && flight.onGround {
            return false
        }
        
        return true
    }
}