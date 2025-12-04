// TagsView.swift
import SwiftUI
import SwiftData

struct TagsView: View {
    let records: [SelfieRecord]
    @Binding var selectedTag: String?
    @Environment(\.dismiss) private var dismiss
    @AppStorage("temperatureUnit") private var temperatureUnitString = "Fahrenheit"
    
    private var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitString) ?? .fahrenheit
    }
    
    private var tagStatistics: [(tag: String, count: Int, records: [SelfieRecord])] {
        let allTags = records.flatMap { $0.tags }
        let uniqueTags = Set(allTags)
        
        return uniqueTags.map { tag in
            let taggedRecords = records.filter { $0.tags.contains(tag) }
            return (tag: tag, count: taggedRecords.count, records: taggedRecords)
        }
        .sorted { $0.count > $1.count }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if tagStatistics.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "tag.slash")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            
                            Text("No Tags Yet")
                                .font(.title2)
                                .bold()
                            
                            Text("Start adding tags to your selfies to organize and categorize your memories!")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 100)
                    } else {
                        // Summary Card
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(tagStatistics.count)")
                                        .font(.system(size: 36, weight: .bold))
                                    Text("Unique Tags")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.blue.opacity(0.3))
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Tags List
                        VStack(spacing: 12) {
                            ForEach(tagStatistics, id: \.tag) { stat in
                                TagStatCard(
                                    tag: stat.tag,
                                    count: stat.count,
                                    records: stat.records,
                                    temperatureUnit: temperatureUnit,
                                    isSelected: selectedTag == stat.tag
                                ) {
                                    selectedTag = stat.tag
                                    dismiss()
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TagStatCard: View {
    let tag: String
    let count: Int
    let records: [SelfieRecord]
    let temperatureUnit: TemperatureUnit
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isExpanded = false
    
    private var latestRecord: SelfieRecord? {
        records.max(by: { $0.captureDate < $1.captureDate })
    }
    
    private var dateRange: String {
        guard let first = records.map({ $0.captureDate }).min(),
              let last = records.map({ $0.captureDate }).max() else {
            return ""
        }
        
        let calendar = Calendar.current
        if calendar.isDate(first, inSameDayAs: last) {
            return first.formatted(date: .abbreviated, time: .omitted)
        } else {
            return "\(first.formatted(date: .abbreviated, time: .omitted)) - \(last.formatted(date: .abbreviated, time: .omitted))"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 16) {
                    // Tag Icon
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "tag.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    
                    // Tag Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tag)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: 8) {
                            Label("\(count)", systemImage: "photo")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if !dateRange.isEmpty {
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text(dateRange)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Expand/Filter buttons
                    HStack(spacing: 12) {
                        Button {
                            onTap()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "line.3.horizontal.decrease.circle")
                                Text(isSelected ? "Filtered" : "Filter")
                            }
                            .font(.caption)
                            .foregroundStyle(isSelected ? .white : .blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal)
                    
                    // Preview of latest photos
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(records.prefix(5), id: \.captureDate) { record in
                                if let image = UIImage.downsample(data: record.imageData, to: CGSize(width: 100, height: 100)) {
                                    VStack(spacing: 4) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        
                                        Text(record.captureDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            
                            if records.count > 5 {
                                VStack {
                                    Text("+\(records.count - 5)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundStyle(.secondary)
                                    Text("more")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 80, height: 80)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
