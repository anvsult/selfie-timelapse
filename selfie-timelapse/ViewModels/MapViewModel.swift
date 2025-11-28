
// MapViewModel.swift
import SwiftUI
import MapKit
import CoreLocation
import Combine

class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
    )
    @Published var selectedRecord: SelfieRecord?
    
    func centerOnRecords(_ records: [SelfieRecord]) {
        guard !records.isEmpty else { return }
        
        let coordinates = records.map { $0.coordinate }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.5) * 1.5,
            longitudeDelta: max(maxLon - minLon, 0.5) * 1.5
        )
        
        region = MKCoordinateRegion(center: center, span: span)
    }
}
