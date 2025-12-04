// Weather.swift
import Foundation

struct WeatherResponse: Codable {
    let weather: [WeatherCondition]
    let main: MainWeather
    let name: String
    
    struct WeatherCondition: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
    
    struct MainWeather: Codable {
        let temp: Double
        let feelsLike: Double
        let humidity: Int
        
        enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case humidity
        }
    }
}

struct WeatherData: Codable, Identifiable {
    let id = UUID()
    let temperature: Double
    let condition: String
    let description: String
    let icon: String
    let humidity: Int
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case temperature, condition, description, icon, humidity, timestamp
    }
    
    var temperatureFahrenheit: Int {
        Int(temperature)
    }
    
    var temperatureCelsius: Int {
        Int((temperature - 32) * 5 / 9)
    }
    
    func formattedTemperature(unit: TemperatureUnit) -> String {
        switch unit {
        case .fahrenheit:
            return "\(temperatureFahrenheit)°F"
        case .celsius:
            return "\(temperatureCelsius)°C"
        }
    }
    
    var weatherEmoji: String {
        switch icon {
        case "01d": return "☀️"
        case "01n": return "🌙"
        case "02d", "02n": return "⛅️"
        case "03d", "03n": return "☁️"
        case "04d", "04n": return "☁️"
        case "09d", "09n": return "🌧️"
        case "10d", "10n": return "🌦️"
        case "11d", "11n": return "⛈️"
        case "13d", "13n": return "❄️"
        case "50d", "50n": return "🌫️"
        default: return "🌤️"
        }
    }
}

enum TemperatureUnit: String, CaseIterable {
    case fahrenheit = "Fahrenheit"
    case celsius = "Celsius"
    
    var symbol: String {
        switch self {
        case .fahrenheit: return "°F"
        case .celsius: return "°C"
        }
    }
}
