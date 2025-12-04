

// SelfieRecord.swift
import Foundation
import SwiftData
import CoreLocation

@Model
final class SelfieRecord {
    var imageData: Data
    var captureDate: Date
    var latitude: Double
    var longitude: Double
    var note: String?
    var tags: [String]
    var weatherData: Data? // Store encoded WeatherData
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var weather: WeatherData? {
        get {
            guard let weatherData = weatherData else { return nil }
            return try? JSONDecoder().decode(WeatherData.self, from: weatherData)
        }
        set {
            weatherData = try? JSONEncoder().encode(newValue)
        }
    }
    
    init(imageData: Data, captureDate: Date = Date(), latitude: Double = 0, longitude: Double = 0, note: String? = nil, tags: [String] = [], weatherData: Data? = nil) {
        self.imageData = imageData
        self.captureDate = captureDate
        self.latitude = latitude
        self.longitude = longitude
        self.note = note
        self.tags = tags
        self.weatherData = weatherData
    }
}
