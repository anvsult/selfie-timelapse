
// CalendarView.swift
import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \SelfieRecord.captureDate) private var records: [SelfieRecord]
    @StateObject private var viewModel = CalendarViewModel()
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
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
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
                    RecordDetailView(record: record)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let image = UIImage(data: record.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Text(record.captureDate.formatted(date: .long, time: .shortened))
                .font(.headline)
            
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
    }
}
