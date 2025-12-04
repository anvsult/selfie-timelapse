// HomeView.swift
import SwiftUI
import SwiftData
import CoreLocation
import MapKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SelfieRecord.captureDate, order: .reverse) private var records: [SelfieRecord]
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(records: records, selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            CameraView()
                .tabItem {
                    Label("Capture", systemImage: "camera.fill")
                }
                .tag(1)
            
            TimelapseView()
                .tabItem {
                    Label("Timelapse", systemImage: "play.rectangle.fill")
                }
                .tag(3)
            
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(2)
                
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .onAppear {
            // Request location permission when app starts
            locationManager.requestPermission()
        }
    }
}

struct DashboardView: View {
    let records: [SelfieRecord]
    @Binding var selectedTab: Int
    @StateObject private var calendarVM = CalendarViewModel()
    @StateObject private var weatherService = WeatherService()
    @AppStorage("temperatureUnit") private var temperatureUnitString = "Fahrenheit"
    @State private var todayRecords: [SelfieRecord] = []
    @State private var selectedDayRecords: [SelfieRecord] = []
    @State private var todayIndex: Int = 0
    @State private var locationName: String = ""
    @State private var showSearchModal = false
    
    private var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitString) ?? .fahrenheit
    }
    
    var streakCount: Int {
        calendarVM.streakCount(in: records)
    }
    
    var totalSelfies: Int {
        records.count
    }
    
    // TODO The completionRate logic seems wrong because I took 1 selfie/day for 2 days and my completion rate is at 200% (it should never exceed 100%)
    // I this the issue is that it does not take into account the fact that multiple selfies can be taken in 1 day
    var completionRate: Int {
        guard !records.isEmpty else { return 0 }
        let calendar = Calendar.current
        let startDate = records.map { $0.captureDate }.min() ?? Date()
        // Inclusive day count (e.g., start today -> 1 day)
        let daysSinceStartInclusive = (calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0) + 1
        let daysWithSelfies = Set(records.map { calendar.startOfDay(for: $0.captureDate) }).count
        let rate = Int((Double(daysWithSelfies) / Double(max(daysSinceStartInclusive, 1))) * 100)
        return min(max(rate, 0), 100)
    }
    
    var uniqueLocations: Int {
        let locations = Set(records.filter { $0.latitude != 0 && $0.longitude != 0 }
            .map { "\(Int($0.latitude * 100)),\(Int($0.longitude * 100))" })
        return locations.count
    }
    
    var journeyDuration: Int {
        guard let firstDate = records.map({ $0.captureDate }).min() else { return 0 }
        let calendar = Calendar.current
        return (calendar.dateComponents([.day], from: firstDate, to: Date()).day ?? 0) + 1
    }
    
    var totalTags: Int {
        Set(records.flatMap { $0.tags }).count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    Text("Selfie Timelapse")
                        .font(.largeTitle)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // Search Button
                    Button {
                        showSearchModal = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            
                            Text("Search tags or notes...")
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Stats Cards
                    HStack(spacing: 16) {
                        StreakCard(streak: streakCount)
                        TotalSelfiesCard(count: totalSelfies)
                    }
                    .padding(.horizontal)
                    
                    // Today's Progress
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Progress")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if !todayRecords.isEmpty {
                            TodayCarouselView(records: todayRecords, locationName: locationName, selectedTab: $selectedTab, selection: $todayIndex)
                                .padding(.horizontal)
                        } else {
                            TodaySelfiePlaceholder()
                                .padding(.horizontal)
                        }
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            Button {
                                selectedTab = 1 // Camera tab
                            } label: {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("Take Today's Selfie")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Button {
                                selectedTab = 3 // Timelapse tab
                            } label: {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("View Timelapse")
                                }
                                .font(.headline)
                                .foregroundStyle(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Your Journey
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Journey")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            JourneyItem(
                                icon: "chart.line.uptrend.xyaxis",
                                iconColor: .green,
                                title: "Consistency",
                                subtitle: "\(completionRate)% completion rate"
                            )
                            
                            JourneyItem(
                                icon: "mappin.circle.fill",
                                iconColor: .blue,
                                title: "Locations Visited",
                                subtitle: "\(uniqueLocations) unique locations"
                            )
                            
                            JourneyItem(
                                icon: "calendar",
                                iconColor: .purple,
                                title: "Journey Duration",
                                subtitle: "\(journeyDuration) days and counting"
                            )
                            
                            if totalTags > 0 {
                                JourneyItem(
                                    icon: "tag.fill",
                                    iconColor: .orange,
                                    title: "Tags Created",
                                    subtitle: "\(totalTags) unique tags"
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Calendar Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Calendar")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HomeCalendarView(
                            records: records,
                            calendarVM: calendarVM,
                            weatherService: weatherService,
                            temperatureUnit: temperatureUnit,
                            selectedRecords: $selectedDayRecords
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .onAppear {
                loadTodayRecords()
                // initialize calendar selection to today so calendar shows today's photos
                calendarVM.selectedDate = Date()
                selectedDayRecords = records.filter { Calendar.current.isDateInToday($0.captureDate) }
                    .sorted { $0.captureDate < $1.captureDate }
            }
            .onChange(of: records.count) { _ in
                // refresh when records are added/removed
                refreshDerivedRecords()
            }
            .sheet(isPresented: $showSearchModal) {
                SearchGalleryView(records: records, temperatureUnit: temperatureUnit)
            }
        }
        .navigationTitle("Selfi")
    }
    
    private func loadTodayRecords() {
        let calendar = Calendar.current
        todayRecords = records.filter { record in
            calendar.isDateInToday(record.captureDate)
        }
        .sorted { $0.captureDate < $1.captureDate } // old -> new

        // open carousel on newest (right-most)
        todayIndex = max(0, todayRecords.count - 1)

        // Use the first record with location to show a location name (reverse geocode)
        if let firstWithLocation = todayRecords.first(where: { $0.latitude != 0 && $0.longitude != 0 }) {
            getLocationName(latitude: firstWithLocation.latitude, longitude: firstWithLocation.longitude)
        }
    }

    // Keep today's records and selected-day records in sync when the dataset changes
    // (e.g., when deleting a photo).
    private func refreshDerivedRecords() {
        loadTodayRecords()
        selectedDayRecords = records.filter { Calendar.current.isDate($0.captureDate, inSameDayAs: calendarVM.selectedDate) }
            .sorted { $0.captureDate < $1.captureDate }
    }
    
    private func getLocationName(latitude: Double, longitude: Double) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                var components: [String] = []
                if let city = placemark.locality {
                    components.append(city)
                }
                if let state = placemark.administrativeArea {
                    components.append(state)
                }
                locationName = components.joined(separator: ", ")
            }
        }
    }
}

struct StreakCard: View {
    let streak: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text("Current Streak")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            
            Text("\(streak) days")
                .font(.title)
                .bold()
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct TotalSelfiesCard: View {
    let count: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "camera.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text("Total Selfies")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            
            Text("\(count) photos")
                .font(.title)
                .bold()
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct TodaySelfieCard: View {
    let imageData: Data
    let date: Date
    let location: String
    let latitude: Double
    let longitude: Double
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let image = UIImage.downsample(data: imageData, to: CGSize(width: 400, height: 400)) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(height: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .overlay(
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            )
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(formatDate(date))
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Button {
                        // Post a notification so the Map view can focus on this coordinate,
                        // then switch to the Map tab.
                        NotificationCenter.default.post(name: .focusMapOnCoordinate, object: nil, userInfo: [
                            "latitude": latitude,
                            "longitude": longitude
                        ])
                        selectedTab = 2 // Map tab
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption)
                            Text("View on map")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                    }
                }
                .padding()
                
                Spacer()
                
                Text(location)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    .padding()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today, \(date.formatted(date: .omitted, time: .shortened))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, \(date.formatted(date: .omitted, time: .shortened))"
        } else {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
    }
}


struct TodayCarouselView: View {
    let records: [SelfieRecord]
    let locationName: String
    @Binding var selectedTab: Int
    @Binding var selection: Int

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(records.enumerated()), id: \.1.captureDate) { idx, record in
                TodaySelfieCard(
                    imageData: record.imageData,
                    date: record.captureDate,
                    location: locationName.isEmpty ? "Unknown Location" : locationName,
                    latitude: record.latitude,
                    longitude: record.longitude,
                    selectedTab: $selectedTab
                )
                .tag(idx)
            }
        }
        .frame(height: 400)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
    }
}

struct TodaySelfiePlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray5))
                .frame(height: 400)
            
            VStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
                Text("No selfie today")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// Reusable small card used for Journey stats
struct JourneyItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct HomeCalendarView: View {
    let records: [SelfieRecord]
    @ObservedObject var calendarVM: CalendarViewModel
    @ObservedObject var weatherService: WeatherService
    let temperatureUnit: TemperatureUnit
    @Binding var selectedRecords: [SelfieRecord]
    @Environment(\.modelContext) private var modelContext
    @State private var pendingDelete: SelfieRecord?
    @State private var showDeleteConfirmation: Bool = false
    @State private var weatherDataForRecords: [Date: WeatherData] = [:]
    
    var body: some View {
        VStack(spacing: 16) {
            // Month Navigation
            HStack {
                Button {
                    calendarVM.currentMonth = Calendar.current.date(
                        byAdding: .month,
                        value: -1,
                        to: calendarVM.currentMonth
                    ) ?? calendarVM.currentMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Text(calendarVM.currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                
                Spacer()
                
                Button {
                    calendarVM.currentMonth = Calendar.current.date(
                        byAdding: .month,
                        value: 1,
                        to: calendarVM.currentMonth
                    ) ?? calendarVM.currentMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 4)
            
            // Calendar Grid
            VStack(spacing: 8) {
                // Day Headers
                HStack(spacing: 0) {
                    ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Calendar Days
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(calendarVM.daysInMonth(), id: \.self) { date in
                        HomeDayCell(
                            date: date,
                            hasRecord: calendarVM.hasRecord(for: date, in: records),
                            isSelected: Calendar.current.isDate(date, inSameDayAs: calendarVM.selectedDate),
                            isToday: Calendar.current.isDateInToday(date)
                        )
                        .onTapGesture {
                            calendarVM.selectedDate = date
                            // collect all records for the tapped day
                            selectedRecords = records.filter { record in
                                Calendar.current.isDate(record.captureDate, inSameDayAs: date)
                            }
                            .sorted { $0.captureDate < $1.captureDate }
                        }
                    }
                }
            }
            
            // Selected Records Detail — show all photos for the selected day
            // TODO Redesign this whole section. it seems too complicated for nothing
            // TODO Redo the alignment logic because the selfies with a note are misaligned with the ones without a note
            if !selectedRecords.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(selectedRecords, id: \.captureDate) { record in
                                VStack(alignment: .leading, spacing: 8) {
                                    ZStack(alignment: .bottomTrailing) {
                                        if let image = UIImage.downsample(data: record.imageData, to: CGSize(width: 200, height: 200)) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 200, height: 200)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }

                                        // Delete button now requests confirmation
                                        Button {
                                            pendingDelete = record
                                            showDeleteConfirmation = true
                                        } label: {
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(Color.red.opacity(0.8))
                                                .clipShape(Circle())
                                                .shadow(radius: 2)
                                        }
                                        .padding(8)
                                    }
                                    
                                    // Weather display
                                    if let weather = weatherDataForRecords[record.captureDate] {
                                        HStack(spacing: 6) {
                                            Text(weather.weatherEmoji)
                                                .font(.title3)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(weather.formattedTemperature(unit: temperatureUnit))
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                Text(weather.description.capitalized)
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .frame(maxWidth: 200, alignment: .leading)
                                    }
                                    
                                    // Tags display
                                    if !record.tags.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 4) {
                                                ForEach(record.tags, id: \.self) { tag in
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
                                        .frame(maxWidth: 200)
                                    }

                                    // Note display - no fixed height needed
                                    if let note = record.note, !note.isEmpty {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(maxWidth: 200, alignment: .leading)
                                            .lineLimit(3)
                                    }
                                }
                                .frame(width: 200)
                                .id(record.captureDate)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .onAppear {
                        // scroll to newest (right-most)
                        if let last = selectedRecords.last {
                            proxy.scrollTo(last.captureDate, anchor: .trailing)
                        }
                    }
                        .onChange(of: selectedRecords.count) { _ in
                            if let last = selectedRecords.last {
                                withAnimation {
                                    proxy.scrollTo(last.captureDate, anchor: .trailing)
                                }
                            }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .alert(isPresented: $showDeleteConfirmation) {
                        Alert(
                            title: Text("Delete Selfie?"),
                            message: Text("This will permanently delete the selected selfie."),
                            primaryButton: .destructive(Text("Delete")) {
                                if let del = pendingDelete {
                                    // Store the date before deletion
                                    let deletedDate = del.captureDate
                                    
                                    // Delete from context
                                    modelContext.delete(del)
                                    try? modelContext.save()
                                    
                                    // Immediately update selectedRecords by filtering out the deleted one
                                    selectedRecords.removeAll { Calendar.current.isDate($0.captureDate, inSameDayAs: deletedDate) && $0.captureDate == del.captureDate }
                                    
                                    // Clear weather data for deleted record
                                    weatherDataForRecords.removeValue(forKey: deletedDate)
                                    
                                    pendingDelete = nil
                                }
                            },
                            secondaryButton: .cancel({ 
                                pendingDelete = nil 
                            })
                        )
                    }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .animation(.default, value: selectedRecords)
        .animation(.default, value: calendarVM.currentMonth)
        .onChange(of: records.count) { oldCount, newCount in
            // When records count changes (deletion), refresh selected records
            if newCount < oldCount {
                selectedRecords = records.filter { record in
                    Calendar.current.isDate(record.captureDate, inSameDayAs: calendarVM.selectedDate)
                }
                .sorted { $0.captureDate < $1.captureDate }
            }
        }
        .task(id: selectedRecords.count) {
            // Load weather for all selected records
            await loadWeatherForRecords()
        }
    }
    
    private func loadWeatherForRecords() async {
        for record in selectedRecords {
            // First check if weather is saved with the record
            if let savedWeather = record.weather {
                weatherDataForRecords[record.captureDate] = savedWeather
                print("✅ Loaded saved weather for \(record.captureDate): \(savedWeather.temperatureFahrenheit)°F")
            } else if record.latitude != 0 && record.longitude != 0 {
                // Fetch from API if not saved
                print("🌐 Fetching weather for \(record.captureDate)")
                if let weather = await weatherService.fetchWeather(
                    for: record.coordinate,
                    date: record.captureDate
                ) {
                    weatherDataForRecords[record.captureDate] = weather
                    print("✅ Fetched weather: \(weather.temperatureFahrenheit)°F")
                }
            }
        }
    }
}

struct HomeDayCell: View {
    let date: Date
    let hasRecord: Bool
    let isSelected: Bool
    let isToday: Bool
    
    var body: some View {
        VStack {
            Text(date.formatted(.dateTime.day()))
                .font(.body)
                .foregroundStyle(isSelected ? .white : (isToday ? .blue : .primary))
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.1) : Color.clear))
                .clipShape(Circle())
                .overlay {
                    if hasRecord {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                            .offset(y: 22)
                    }
                }
        }
    }
}

struct HomeRecordDetailView: View {
    let record: SelfieRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(record.captureDate.formatted(date: .long, time: .shortened))
                    .font(.headline)
                Spacer()
            }
            
            if let image = UIImage.downsample(data: record.imageData, to: CGSize(width: 400, height: 200)) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if let note = record.note, !note.isEmpty {
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
    }
}
