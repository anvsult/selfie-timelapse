

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
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(imageData: Data, captureDate: Date = Date(), latitude: Double = 0, longitude: Double = 0, note: String? = nil, tags: [String] = []) {
        self.imageData = imageData
        self.captureDate = captureDate
        self.latitude = latitude
        self.longitude = longitude
        self.note = note
        self.tags = tags
    }
}
