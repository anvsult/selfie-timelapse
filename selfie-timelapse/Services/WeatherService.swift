// WeatherService.swift
import Foundation
import CoreLocation
import Combine

@MainActor
class WeatherService: ObservableObject {
    @Published var weatherCache: [String: WeatherData] = [:]
    @Published var isLoading = false
    @Published var error: String?
    
    // OpenWeatherMap API key - REQUIRED: Get your free key from: https://openweathermap.org/api
    // Sign up at: https://home.openweathermap.org/users/sign_up
    // After signup, find your API key at: https://home.openweathermap.org/api_keys
    // Replace "YOUR_API_KEY_HERE" with your actual API key
    private let apiKey = "e3d7f4c1b5bd43555cb60ac187b3cbd6"
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    
    /// Tests if the API key is valid by making a simple request
    func testAPIKey() async -> Bool {
        // Test with a known location (New York City)
        let testCoordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        
        if apiKey.isEmpty || apiKey == "YOUR_API_KEY_HERE" {
            print("❌ Weather API: No API key configured")
            return false
        }
        
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: "\(testCoordinate.latitude)"),
            URLQueryItem(name: "lon", value: "\(testCoordinate.longitude)"),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "imperial")
        ]
        
        guard let url = components?.url else {
            print("❌ Weather API: Invalid URL")
            return false
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Weather API: API key is valid and working")
                    return true
                } else {
                    print("❌ Weather API: Request failed with status code \(httpResponse.statusCode)")
                    return false
                }
            }
            return false
        } catch {
            print("❌ Weather API: Connection error - \(error.localizedDescription)")
            return false
        }
    }
    
    func fetchWeather(for coordinate: CLLocationCoordinate2D, date: Date) async -> WeatherData? {
        let cacheKey = "\(coordinate.latitude),\(coordinate.longitude),\(date.formatted(.dateTime.year().month().day()))"
        
        print("🌤️ Weather fetch requested for: \(coordinate.latitude), \(coordinate.longitude) on \(date.formatted(.dateTime.year().month().day()))")
        
        // Return cached weather if available
        if let cached = weatherCache[cacheKey] {
            print("💾 Using cached weather data")
            return cached
        }
        
        // For demo purposes, if no valid API key is set, return mock data
        if apiKey.isEmpty || apiKey == "YOUR_API_KEY_HERE" {
            print("⚠️ Weather API: Using mock data - no valid API key configured")
            return createMockWeather(for: date)
        }
        
        isLoading = true
        error = nil
        
        do {
            var components = URLComponents(string: baseURL)
            components?.queryItems = [
                URLQueryItem(name: "lat", value: "\(coordinate.latitude)"),
                URLQueryItem(name: "lon", value: "\(coordinate.longitude)"),
                URLQueryItem(name: "appid", value: apiKey),
                URLQueryItem(name: "units", value: "imperial")
            ]
            
            guard let url = components?.url else {
                throw WeatherError.invalidURL
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherError.invalidResponse
            }
            
            // Check for specific error codes
            if httpResponse.statusCode == 401 {
                print("⚠️ Weather API: Invalid API key (401)")
                throw WeatherError.invalidAPIKey
            }
            
            if httpResponse.statusCode != 200 {
                print("⚠️ Weather API: Server returned status code \(httpResponse.statusCode)")
                throw WeatherError.invalidResponse
            }
            
            let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
            
            let weatherData = WeatherData(
                temperature: weatherResponse.main.temp,
                condition: weatherResponse.weather.first?.main ?? "Unknown",
                description: weatherResponse.weather.first?.description ?? "",
                icon: weatherResponse.weather.first?.icon ?? "01d",
                humidity: weatherResponse.main.humidity,
                timestamp: date
            )
            
            print("✅ Successfully fetched weather: \(weatherData.temperatureFahrenheit)°F, \(weatherData.condition)")
            
            // Cache the result
            weatherCache[cacheKey] = weatherData
            isLoading = false
            
            return weatherData
            
        } catch {
            let errorMessage = error.localizedDescription
            self.error = errorMessage
            print("⚠️ Weather API Error: \(errorMessage)")
            isLoading = false
            // Return mock data on error for better user experience
            return createMockWeather(for: date)
        }
    }
    
    private func createMockWeather(for date: Date) -> WeatherData {
        // Generate somewhat realistic mock weather based on date
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let temp = 45.0 + Double((dayOfYear % 40)) // Temperature between 45-85°F
        
        let conditions = ["Clear", "Clouds", "Rain", "Sunny"]
        let icons = ["01d", "02d", "10d", "01d"]
        let index = dayOfYear % conditions.count
        
        return WeatherData(
            temperature: temp,
            condition: conditions[index],
            description: conditions[index].lowercased(),
            icon: icons[index],
            humidity: 50 + (dayOfYear % 40),
            timestamp: date
        )
    }
}

enum WeatherError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidAPIKey
    case noDataFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid server response"
        case .invalidAPIKey:
            return "Invalid API key. Please check your OpenWeatherMap API key."
        case .noDataFound:
            return "No weather data found"
        }
    }
}
