
// CalendarView.swift
import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \SelfieRecord.captureDate) private var records: [SelfieRecord]
    @StateObject private var viewModel = CalendarViewModel()
    @StateObject private var weatherService = WeatherService()
    @State private var selectedRecord: SelfieRecord?
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button {
                        viewModel.currentMonth = Calendar.current.date(
                            byAdding: .month,
                            value: -1,
                            to: viewModel.currentMonth
                        ) ?? viewModel.currentMonth
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    
                    Spacer()
                    
                    Text(viewModel.currentMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        viewModel.currentMonth = Calendar.current.date(
                            byAdding: .month,
                            value: 1,
                            to: viewModel.currentMonth
                        ) ?? viewModel.currentMonth
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    ForEach(viewModel.daysInMonth(), id: \.self) { date in
                        DayCell(
                            date: date,
                            hasRecord: viewModel.hasRecord(for: date, in: records),
                            isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
                        )
                        .onTapGesture {
                            viewModel.selectedDate = date
                            selectedRecord = records.first { record in
                                Calendar.current.isDate(record.captureDate, inSameDayAs: date)
                            }
                        }
                    }
                }
                .padding()
                
                if let record = selectedRecord {
                    RecordDetailView(record: record, weatherService: weatherService)
                        .transition(.move(edge: .bottom))
                } else {
                    Spacer()
                }
            }
            .navigationTitle("Calendar")
            .animation(.default, value: selectedRecord)
        }
    }
}

struct DayCell: View {
    let date: Date
    let hasRecord: Bool
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Text(date.formatted(.dateTime.day()))
                .font(.body)
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(width: 40, height: 40)
                .background(isSelected ? Color.blue : Color.clear)
                .clipShape(Circle())
                .overlay {
                    if hasRecord && !isSelected {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                            .offset(y: 20)
                    }
                }
        }
    }
}

struct RecordDetailView: View {
    let record: SelfieRecord
    @ObservedObject var weatherService: WeatherService
    @State private var weather: WeatherData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let image = UIImage.downsample(data: record.imageData, to: CGSize(width: 400, height: 300)) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text(record.captureDate.formatted(date: .long, time: .shortened))
                        .font(.headline)
                    
                    // Weather display
                    if let weather = weather {
                        HStack(spacing: 8) {
                            Text(weather.weatherEmoji)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(weather.temperatureFahrenheit)°F")
                                    .font(.headline)
                                Text(weather.description.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
            
            if let note = record.note {
                Text(note)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            if !record.tags.isEmpty {
                HStack {
                    ForEach(record.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
        .task {
            // First check if weather data is already saved with the record
            if let savedWeather = record.weather {
                weather = savedWeather
                print("✅ Loaded saved weather: \(savedWeather.temperatureFahrenheit)°F, \(savedWeather.condition)")
            } else if record.latitude != 0 && record.longitude != 0 {
                // Fetch weather from API if not saved
                print("🌐 Fetching weather from API for coordinates: \(record.latitude), \(record.longitude)")
                weather = await weatherService.fetchWeather(
                    for: record.coordinate,
                    date: record.captureDate
                )
                if let weather = weather {
                    print("✅ Fetched weather: \(weather.temperatureFahrenheit)°F, \(weather.condition)")
                }
            } else {
                print("⚠️ No location data available for this record")
            }
        }
    }
}
