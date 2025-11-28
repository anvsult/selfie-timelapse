

// CalendarViewModel.swift
import SwiftUI
import Combine
class CalendarViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var currentMonth = Date()
    
    func daysInMonth() -> [Date] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: currentMonth)!
        let days = calendar.dateComponents([.day], from: interval.start, to: interval.end).day!
        
        return (0..<days).compactMap {
            calendar.date(byAdding: .day, value: $0, to: interval.start)
        }
    }
    
    func hasRecord(for date: Date, in records: [SelfieRecord]) -> Bool {
        let calendar = Calendar.current
        return records.contains { record in
            calendar.isDate(record.captureDate, inSameDayAs: date)
        }
    }
    
    func streakCount(in records: [SelfieRecord]) -> Int {
        guard !records.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedDates = records.map { calendar.startOfDay(for: $0.captureDate) }
            .sorted()
            .reversed()
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for date in sortedDates {
            if calendar.isDate(date, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if date < currentDate {
                break
            }
        }
        
        return streak
    }
}
