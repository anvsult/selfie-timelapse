// SearchGalleryView.swift
import SwiftUI
import SwiftData

struct SearchGalleryView: View {
    let records: [SelfieRecord]
    let temperatureUnit: TemperatureUnit
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @FocusState private var searchFieldFocused: Bool
    @State private var selectedRecord: SelfieRecord?
    
    private var filteredRecords: [SelfieRecord] {
        if searchText.isEmpty {
            return []
        }
        
        let lowercasedSearch = searchText.lowercased()
        return records.filter { record in
            // Search in tags
            let matchesTag = record.tags.contains { tag in
                tag.lowercased().contains(lowercasedSearch)
            }
            
            // Search in notes
            let matchesNote = record.note?.lowercased().contains(lowercasedSearch) ?? false
            
            return matchesTag || matchesNote
        }
        .sorted { $0.captureDate > $1.captureDate } // Most recent first
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField("Search tags or notes...", text: $searchText)
                            .focused($searchFieldFocused)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Results
                if searchText.isEmpty {
                    // Empty State - Before Search
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 8) {
                            Text("Search Your Selfies")
                                .font(.title2)
                                .bold()
                            
                            Text("Search by tags or notes to find specific memories")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                    }
                    .padding()
                } else if filteredRecords.isEmpty {
                    // Empty State - No Results
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 8) {
                            Text("No Results")
                                .font(.title2)
                                .bold()
                            
                            Text("No selfies found matching \"\(searchText)\"")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    // Results Header
                    HStack {
                        Text("\(filteredRecords.count) result\(filteredRecords.count == 1 ? "" : "s")")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    // Gallery Grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(filteredRecords, id: \.captureDate) { record in
                                SearchResultCard(
                                    record: record,
                                    searchText: searchText,
                                    temperatureUnit: temperatureUnit
                                )
                                .onTapGesture {
                                    selectedRecord = record
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                searchFieldFocused = true
            }
            .sheet(item: $selectedRecord) { record in
                SearchResultDetailView(record: record, temperatureUnit: temperatureUnit)
            }
        }
    }
}

struct SearchResultCard: View {
    let record: SelfieRecord
    let searchText: String
    let temperatureUnit: TemperatureUnit
    
    private var matchedTags: [String] {
        let lowercasedSearch = searchText.lowercased()
        return record.tags.filter { $0.lowercased().contains(lowercasedSearch) }
    }
    
    private var matchedInNote: Bool {
        record.note?.lowercased().contains(searchText.lowercased()) ?? false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            if let image = UIImage.downsample(data: record.imageData, to: CGSize(width: 200, height: 200)) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Date
            Text(record.captureDate.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Matched Tags
            if !matchedTags.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(matchedTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            
            // Matched Note Preview
            if matchedInNote, let note = record.note {
                HStack(spacing: 4) {
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct SearchResultDetailView: View {
    let record: SelfieRecord
    let temperatureUnit: TemperatureUnit
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var weatherService = WeatherService()
    @State private var weather: WeatherData?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Image
                    if let image = UIImage.downsample(data: record.imageData, to: CGSize(width: 400, height: 400)) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Date and Time
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.captureDate.formatted(date: .long, time: .omitted))
                            .font(.headline)
                        Text(record.captureDate.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Weather
                    if let weather = weather {
                        HStack(spacing: 12) {
                            Text(weather.weatherEmoji)
                                .font(.title)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(weather.formattedTemperature(unit: temperatureUnit))
                                    .font(.title3)
                                    .bold()
                                Text(weather.description.capitalized)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Location
                    if record.latitude != 0 && record.longitude != 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                            Text("Location: \(record.latitude, specifier: "%.4f"), \(record.longitude, specifier: "%.4f")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Tags
                    if !record.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.headline)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(record.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    
                    // Note
                    if let note = record.note, !note.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
                                .font(.headline)
                            
                            Text(note)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Selfie Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                // Load weather if available
                if let savedWeather = record.weather {
                    weather = savedWeather
                } else if record.latitude != 0 && record.longitude != 0 {
                    weather = await weatherService.fetchWeather(
                        for: record.coordinate,
                        date: record.captureDate
                    )
                }
            }
        }
    }
}

// Simple FlowLayout for wrapping tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
