# PlaneTracker iOS App

A real-time flight tracking iOS application built with SwiftUI that displays live aircraft positions, detailed flight information, and comprehensive airline data from multiple aviation APIs.

## Features

### 🗺️ Interactive Map View
- Real-time flight positions displayed on an interactive map
- Color-coded aircraft markers based on altitude
- Aircraft rotation based on true heading
- Multiple map styles (Standard, Satellite, Hybrid)
- Tap aircraft for detailed information
- Auto-zoom to show all visible flights

### ✈️ Flight List
- Comprehensive list of all tracked flights
- Search and filter capabilities
- Real-time status updates
- Detailed flight information including:
  - Flight callsign and ICAO24 identifier
  - Aircraft position (latitude/longitude)
  - Altitude in feet
  - Ground speed in knots
  - Origin country
  - On-ground status

### 📊 Statistics Dashboard
- Total number of tracked flights
- Airborne vs. grounded aircraft count
- Flights breakdown by country
- Real-time data updates

### 🔍 Flight Details
- Comprehensive flight information view
- Interactive mini-map showing aircraft position
- Technical data including:
  - Aircraft model and registration
  - Operator information
  - Route details (departure/arrival airports)
  - Altitude, speed, and heading
  - Vertical rate (climbing/descending)
  - Squawk code and last contact time

### ⚙️ Settings & Configuration
- API key configuration for premium services
- Flight filtering options:
  - Country filter
  - Altitude range filter
  - Ground/airborne only filters
- Data source information

## Data Sources

### Primary Data Source
- **OpenSky Network**: Free, real-time aircraft position data
  - No API key required
  - Global coverage
  - Updates every 30 seconds
  - Provides position, altitude, speed, and heading data

### Optional Premium APIs
- **FlightAware AeroAPI**: Enhanced flight details and aircraft information
- **Aviation Edge**: Comprehensive airline and aircraft database

## Technical Details

### Architecture
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for data flow
- **MapKit**: Interactive maps and location services
- **MVVM Pattern**: Clean separation of concerns
- **Real-time Updates**: Automatic data refresh every 30 seconds

### Key Components
1. **FlightService**: Handles all API communication and data processing
2. **Flight Models**: Comprehensive data structures for flights, aircraft, and airlines
3. **MapView**: Interactive map with real-time aircraft positions
4. **FlightDetailView**: Detailed flight information display
5. **ContentView**: Main tab-based navigation

### Data Models
- **Flight**: Real-time flight position and status
- **Aircraft**: Aircraft details (model, registration, operator)
- **Airline**: Airline information (codes, name, country)
- **Airport**: Airport data (codes, location, name)
- **FlightRoute**: Route information (departure/arrival airports)

## Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Internet connection for real-time data

### Installation
1. Clone the repository
2. Open `PlaneTracker.xcodeproj` in Xcode
3. Build and run the project on your iOS device or simulator

### API Configuration (Optional)
For enhanced features, you can configure API keys in the Settings tab:

1. **FlightAware AeroAPI**:
   - Sign up at [FlightAware](https://flightaware.com/commercial/aeroapi/)
   - Get your API key
   - Enter it in the app settings

2. **Aviation Edge**:
   - Sign up at [Aviation Edge](https://aviation-edge.com/)
   - Get your API key
   - Enter it in the app settings

## Usage

### Getting Started
1. Launch the app
2. Grant location permissions if prompted
3. The app will automatically start loading flight data
4. Use the map or list view to explore flights

### Navigation
- **Map Tab**: Interactive map with live flight positions
- **Flights Tab**: Searchable list of all flights
- **Stats Tab**: Overview statistics and data breakdown

### Interacting with Flights
- **Tap on aircraft**: View detailed flight information
- **Use search**: Find specific flights by callsign or country
- **Apply filters**: Filter flights by altitude, status, or country
- **Refresh data**: Pull down to refresh or use the refresh button

## Features in Detail

### Real-time Tracking
- Aircraft positions update every 30 seconds
- Automatic map region adjustment
- Live status indicators (airborne/ground)
- Color-coded altitude visualization

### Search and Filtering
- Search by flight callsign, ICAO24, or country
- Filter by altitude range
- Show only airborne or grounded aircraft
- Country-specific filtering

### Data Visualization
- Interactive maps with aircraft markers
- Statistical breakdown by country
- Real-time flight counts
- Historical data preservation

## Troubleshooting

### Common Issues
1. **No flights showing**: Check internet connection and try refreshing
2. **Map not loading**: Ensure location services are enabled
3. **Search not working**: Clear search text and try again
4. **API errors**: Verify API keys in settings

### Data Accuracy
- Flight data is sourced from ADS-B transponders
- Position accuracy depends on aircraft equipment
- Some military or private aircraft may not appear
- Data updates may have slight delays

## Technical Requirements

### Minimum Requirements
- iOS 17.0+
- iPhone or iPad
- Internet connection
- Location services (optional, for centering map)

### Recommended
- iPhone 12 or newer for optimal performance
- Wi-Fi or cellular data connection
- iOS 17.1+ for latest features

## Privacy

- The app only uses publicly available flight data
- No personal data is collected or stored
- Location services are only used for map centering
- API keys are stored locally on device

## License

This project is created for educational and demonstration purposes. Flight data is provided by OpenSky Network and other aviation APIs under their respective terms of service.

## Contributing

This is a demonstration project showcasing iOS development with real-time data integration. Feel free to use it as a reference for your own projects.

## Support

For technical issues or questions about the implementation, please refer to the code comments and documentation within the source files.
