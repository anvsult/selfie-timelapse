
// NotificationManager.swift
import Foundation
import UserNotifications
import Combine
class NotificationManager: NSObject, ObservableObject {
    @Published var permissionGranted = false
    
    override init() {
        super.init()
        checkPermission()
    }
    
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.permissionGranted = granted
            }
        }
    }
    
    func scheduleDailyReminder(at time: Date) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Selfie"
        content.body = "Don't forget your daily selfie! Keep your streak going."
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: "dailySelfie", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
