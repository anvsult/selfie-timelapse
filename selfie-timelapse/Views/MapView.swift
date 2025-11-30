// MapView.swift
import SwiftUI
import SwiftData
import MapKit
import Combine

struct MapView: View {
    @Query(sort: \SelfieRecord.captureDate) private var records: [SelfieRecord]
    @StateObject private var viewModel = MapViewModel()
    
    var recordsWithLocation: [SelfieRecord] {
        records.filter { $0.latitude != 0 && $0.longitude != 0 }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if recordsWithLocation.isEmpty {
                    ContentUnavailableView(
                        "No Locations Yet",
                        systemImage: "map",
                        description: Text("Selfies with location data will appear here")
                    )
                } else {
                    Map(coordinateRegion: $viewModel.region, annotationItems: recordsWithLocation) { record in
                        MapAnnotation(coordinate: record.coordinate) {
                            Button {
                                viewModel.selectedRecord = record
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(.blue)
                                        .frame(width: 30, height: 30)
                                    
                                    if let image = UIImage(data: record.imageData) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 24, height: 24)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "camera.fill")
                                            .foregroundStyle(.white)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                    
                    if let selected = viewModel.selectedRecord {
                        VStack {
                            Spacer()
                            
                            MapRecordCard(record: selected) {
                                viewModel.selectedRecord = nil
                            }
                            .padding()
                            .transition(.move(edge: .bottom))
                        }
                    }
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button {
                    viewModel.centerOnRecords(recordsWithLocation)
                } label: {
                    Image(systemName: "location.circle")
                }
            }
            .onAppear {
                viewModel.centerOnRecords(recordsWithLocation)
            }
            // Listen for requests to focus the map on a particular coordinate
            .onReceive(NotificationCenter.default.publisher(for: .focusMapOnCoordinate)) { note in
                guard let info = note.userInfo,
                      let lat = info["latitude"] as? Double,
                      let lon = info["longitude"] as? Double else { return }

                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)

                // narrow region and center on the requested coordinate
                let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                viewModel.region = MKCoordinateRegion(center: coord, span: span)

                // try to find the matching record (closest by distance) and select it
                if let closest = recordsWithLocation.min(by: {
                    let a = CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                    let b = CLLocation(latitude: $1.latitude, longitude: $1.longitude)
                    let target = CLLocation(latitude: lat, longitude: lon)
                    return a.distance(from: target) < b.distance(from: target)
                }) {
                    viewModel.selectedRecord = closest
                }
            }
            .animation(.default, value: viewModel.selectedRecord)
        }
    }
}

struct MapRecordCard: View {
    let record: SelfieRecord
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if let image = UIImage(data: record.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.captureDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.headline)
                
                if let note = record.note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Text("📍 \(record.latitude, specifier: "%.4f"), \(record.longitude, specifier: "%.4f")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 5)
    }
}
