// HomeView.swift
import SwiftUI
import SwiftData
import CoreLocation
import MapKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SelfieRecord.captureDate, order: .reverse) private var records: [SelfieRecord]
    @EnvironmentObject var notificationManager: NotificationManager
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
    }
}

struct DashboardView: View {
    let records: [SelfieRecord]
    @Binding var selectedTab: Int
    @StateObject private var calendarVM = CalendarViewModel()
    @State private var todayRecords: [SelfieRecord] = []
    @State private var selectedDayRecords: [SelfieRecord] = []
    @State private var locationName: String = ""
    
    var streakCount: Int {
        calendarVM.streakCount(in: records)
    }
    
    var totalSelfies: Int {
        records.count
    }
    
    var completionRate: Int {
        guard !records.isEmpty else { return 0 }
        let calendar = Calendar.current
        let startDate = records.map { $0.captureDate }.min() ?? Date()
        let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 1
        let daysWithSelfies = Set(records.map { calendar.startOfDay(for: $0.captureDate) }).count
        return Int((Double(daysWithSelfies) / Double(max(daysSinceStart, 1))) * 100)
    }
    
    var uniqueLocations: Int {
        let locations = Set(records.filter { $0.latitude != 0 && $0.longitude != 0 }
            .map { "\(Int($0.latitude * 100)),\(Int($0.longitude * 100))" })
        return locations.count
    }
    
    var journeyDuration: Int {
        guard let firstDate = records.map({ $0.captureDate }).min() else { return 0 }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: firstDate, to: Date()).day ?? 0
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
                            TodayCarouselView(records: todayRecords, locationName: locationName, selectedTab: $selectedTab)
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
                        }
                        .padding(.horizontal)
                    }
                    
                    // Calendar Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Calendar")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HomeCalendarView(records: records, calendarVM: calendarVM, selectedRecords: $selectedDayRecords)
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
            }
        }
        .navigationTitle("Selfi")
    }
    
    private func loadTodayRecords() {
        let calendar = Calendar.current
        todayRecords = records.filter { record in
            calendar.isDateInToday(record.captureDate)
        }

        // Use the first record with location to show a location name (reverse geocode)
        if let firstWithLocation = todayRecords.first(where: { $0.latitude != 0 && $0.longitude != 0 }) {
            getLocationName(latitude: firstWithLocation.latitude, longitude: firstWithLocation.longitude)
        }
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
    let image: UIImage
    let date: Date
    let location: String
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 400)
                .clipShape(RoundedRectangle(cornerRadius: 16))
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

    var body: some View {
        TabView {
            ForEach(records, id: \ .captureDate) { record in
                if let image = UIImage(data: record.imageData) {
                    TodaySelfieCard(
                        image: image,
                        date: record.captureDate,
                        location: locationName.isEmpty ? "Unknown Location" : locationName,
                        selectedTab: $selectedTab
                    )
                }
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
    @Binding var selectedRecords: [SelfieRecord]
    
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
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
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
                        }
                    }
                }
            }
            
            // Selected Records Detail — show all photos for the selected day
            if !selectedRecords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(selectedRecords, id: \.captureDate) { record in
                            VStack(alignment: .leading, spacing: 8) {
                                if let image = UIImage(data: record.imageData) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }

                                if let note = record.note, !note.isEmpty {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .animation(.default, value: selectedRecords)
        .animation(.default, value: calendarVM.currentMonth)
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
                    if hasRecord && !isSelected {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                            .offset(y: 18)
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
            
            if let image = UIImage(data: record.imageData) {
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
