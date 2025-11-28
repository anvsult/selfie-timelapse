
// SettingsView.swift
import SwiftUI
import SwiftData
import CoreLocation

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SelfieRecord.captureDate) private var records: [SelfieRecord]
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var calendarVM = CalendarViewModel()
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("colorScheme") private var colorSchemeString = "system"
    
    
    @State private var reminderTime = Date()
    @State private var notificationsEnabled = true
    @State private var locationEnabled = true
    @State private var showDeleteAlert = false
    @State private var showReminderTimePicker = false
    
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var showExportAlert = false
    @State private var exportMessage = ""
    @State private var showShareSheet = false
    @State private var exportZipURL: URL?
    
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App Title
                    Text("Settings")
                        .font(.largeTitle)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // Notifications Section
                    SettingsSection(title: "NOTIFICATIONS") {
                        SettingsRow(
                            icon: "bell.fill",
                            iconColor: .blue,
                            title: "Daily Reminders",
                            subtitle: "Get notified to take your selfie",
                            trailing: {
                                Toggle("", isOn: $notificationsEnabled)
                                    .labelsHidden()
                                    .tint(.blue)
                            }
                        )
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue && !notificationManager.permissionGranted {
                                notificationManager.requestPermission()
                            }
                            if newValue && notificationManager.permissionGranted {
                                notificationManager.scheduleDailyReminder(at: reminderTime)
                            }
                        }
                        
                        Button {
                            showReminderTimePicker = true
                        } label: {
                            SettingsRow(
                                icon: "clock.fill",
                                iconColor: .purple,
                                title: "Reminder Time",
                                subtitle: "Daily at \(reminderTime.formatted(date: .omitted, time: .shortened))",
                                trailing: {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    
                    // Privacy Section
                    SettingsSection(title: "PRIVACY") {
                        SettingsRow(
                            icon: "location.fill",
                            iconColor: .green,
                            title: "Location Services",
                            subtitle: "Geotag your selfies",
                            trailing: {
                                Toggle("", isOn: $locationEnabled)
                                    .labelsHidden()
                                    .tint(.green)
                            }
                        )
                        .onChange(of: locationEnabled) { _, _ in
                            if locationEnabled && locationManager.authorizationStatus == .denied {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                        
                        // Video quality option removed — feature deprecated
                    }
                    .padding(.horizontal)
                    
                    // App Settings Section
                    SettingsSection(title: "APP SETTINGS") {
                        Menu {
                            Button("System") {
                                colorSchemeString = "system"
                                applyColorScheme()
                            }
                            Button("Light") {
                                colorSchemeString = "light"
                                applyColorScheme()
                            }
                            Button("Dark") {
                                colorSchemeString = "dark"
                                applyColorScheme()
                            }
                        } label: {
                            SettingsRow(
                                icon: "moon.fill",
                                iconColor: .gray,
                                title: "Appearance",
                                subtitle: colorSchemeString.capitalized,
                                trailing: {
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            )
                        }
                        
                        Button {
                            exportAllPhotos()
                        } label: {
                            SettingsRow(
                                icon: "square.and.arrow.up.fill",
                                iconColor: .blue,
                                title: "Export Data",
                                subtitle: isExporting ? "Exporting..." : "Download all your selfies",
                                trailing: {
                                    if isExporting {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isExporting)
                    }
                    .padding(.horizontal)
                    
                    // Delete All Data Button
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete All Data")
                        }
                        .font(.headline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Version
                    Text("Selfie Timelapse v1.0.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .onAppear {
                updateLocationStatus()
            }
            .onChange(of: locationManager.authorizationStatus) { _, _ in
                updateLocationStatus()
            }
            .sheet(isPresented: $showReminderTimePicker) {
                NavigationStack {
                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .navigationTitle("Reminder Time")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    showReminderTimePicker = false
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    if notificationManager.permissionGranted {
                                        notificationManager.scheduleDailyReminder(at: reminderTime)
                                    }
                                    showReminderTimePicker = false
                                }
                            }
                        }
                }
                .presentationDetents([.medium])
            }
            .alert("Delete All Selfies?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllRecords()
                }
            } message: {
                Text("This action cannot be undone. All your selfies will be permanently deleted.")
            }
            .alert("Export Complete", isPresented: $showExportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(exportMessage)
            }
            .sheet(isPresented: $showShareSheet) {
                if let zipURL = exportZipURL {
                    ShareSheet(activityItems: [zipURL])
                }
            }
        }
    }
    
    // Profile model removed — account/profile UI and persistence are no longer used.
    
    private func deleteAllRecords() {
        let descriptor = FetchDescriptor<SelfieRecord>()
        if let allRecords = try? modelContext.fetch(descriptor) {
            for record in allRecords {
                modelContext.delete(record)
            }
            try? modelContext.save()
        }
    }
    
    private func updateLocationStatus() {
        locationEnabled = locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways
    }
    
    private func applyColorScheme() {
        // The color scheme is applied via .preferredColorScheme modifier
        // This function can be used for any additional setup if needed
    }
    
    private func createZipFile(from folderURL: URL, to zipURL: URL) -> Bool {
        let fileManager = FileManager.default
        
        // Get all files in the folder
        guard let fileURLs = try? fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: []) else {
            return false
        }
        
        // Create zip file using a simple approach
        // Note: This is a basic implementation. For production, consider using a library like SSZipArchive
        guard let zipData = NSMutableData() as Data? else { return false }
        
        // For now, we'll use a workaround: create a zip using command-line tool if available
        // or use a simple file archiving approach
        // Since Process() doesn't work well in iOS sandbox, we'll use a different approach
        
        // Create zip using Foundation's built-in capabilities
        // Actually, Foundation doesn't have built-in zip support, so we'll use a workaround
        // Share all files from the folder - they'll be grouped in the share sheet
        // But the user wants a zip file, so let's try using a simple zip creation
        
        // Use a basic zip file format implementation
        return createBasicZipFile(from: folderURL, to: zipURL, fileManager: fileManager)
    }
    
    private func createBasicZipFile(from folderURL: URL, to zipURL: URL, fileManager: FileManager) -> Bool {
        // Create a proper zip file with central directory
        guard let fileURLs = try? fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: []) else {
            return false
        }
        
        var localFileHeaders: [(offset: Int, fileName: String, fileData: Data)] = []
        var zipData = Data()
        
        // Calculate CRC32
        func crc32(data: Data) -> UInt32 {
            var crc: UInt32 = 0xFFFFFFFF
            for byte in data {
                crc ^= UInt32(byte)
                for _ in 0..<8 {
                    crc = (crc >> 1) ^ (0xEDB88320 & ((crc & 1) != 0 ? 0xFFFFFFFF : 0))
                }
            }
            return crc ^ 0xFFFFFFFF
        }
        
        // Create local file headers and file data
        for fileURL in fileURLs {
            guard let fileData = try? Data(contentsOf: fileURL) else {
                continue
            }
            
            let fileName = fileURL.lastPathComponent
            guard let fileNameData = fileName.data(using: .utf8) else {
                continue
            }
            
            let crc = crc32(data: fileData)
            let fileSize = UInt32(fileData.count)
            let fileNameLength = UInt16(fileNameData.count)
            
            let offset = zipData.count
            
            // Local file header
            var localHeader = Data()
            localHeader.append(Data([0x50, 0x4B, 0x03, 0x04])) // Signature
            localHeader.append(Data([0x14, 0x00])) // Version
            localHeader.append(Data([0x00, 0x00])) // Flags
            localHeader.append(Data([0x00, 0x00])) // Compression (stored)
            localHeader.append(Data([0x00, 0x00, 0x00, 0x00])) // Time/date
            localHeader.append(contentsOf: withUnsafeBytes(of: crc.littleEndian) { Data($0) }) // CRC-32
            localHeader.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Data($0) }) // Compressed size
            localHeader.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Data($0) }) // Uncompressed size
            localHeader.append(contentsOf: withUnsafeBytes(of: fileNameLength.littleEndian) { Data($0) }) // File name length
            localHeader.append(Data([0x00, 0x00])) // Extra field length
            localHeader.append(fileNameData) // File name
            localHeader.append(fileData) // File data
            
            zipData.append(localHeader)
            localFileHeaders.append((offset: offset, fileName: fileName, fileData: fileData))
        }
        
        // Create central directory
        let centralDirectoryOffset = zipData.count
        for header in localFileHeaders {
            let fileNameData = header.fileName.data(using: .utf8) ?? Data()
            let fileNameLength = UInt16(fileNameData.count)
            let fileSize = UInt32(header.fileData.count)
            let crc = crc32(data: header.fileData)
            
            var centralHeader = Data()
            centralHeader.append(Data([0x50, 0x4B, 0x01, 0x02])) // Signature
            centralHeader.append(Data([0x14, 0x00])) // Version made by
            centralHeader.append(Data([0x14, 0x00])) // Version needed
            centralHeader.append(Data([0x00, 0x00])) // Flags
            centralHeader.append(Data([0x00, 0x00])) // Compression
            centralHeader.append(Data([0x00, 0x00, 0x00, 0x00])) // Time/date
            centralHeader.append(contentsOf: withUnsafeBytes(of: crc.littleEndian) { Data($0) }) // CRC-32
            centralHeader.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Data($0) }) // Compressed size
            centralHeader.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Data($0) }) // Uncompressed size
            centralHeader.append(contentsOf: withUnsafeBytes(of: fileNameLength.littleEndian) { Data($0) }) // File name length
            centralHeader.append(Data([0x00, 0x00])) // Extra field length
            centralHeader.append(Data([0x00, 0x00])) // Comment length
            centralHeader.append(Data([0x00, 0x00])) // Disk number
            centralHeader.append(Data([0x00, 0x00])) // Internal attributes
            centralHeader.append(Data([0x00, 0x00, 0x00, 0x00])) // External attributes
            centralHeader.append(contentsOf: withUnsafeBytes(of: UInt32(header.offset).littleEndian) { Data($0) }) // Local header offset
            centralHeader.append(fileNameData) // File name
            
            zipData.append(centralHeader)
        }
        
        // End of central directory record
        let centralDirectorySize = zipData.count - centralDirectoryOffset
        var endRecord = Data()
        endRecord.append(Data([0x50, 0x4B, 0x05, 0x06])) // Signature
        endRecord.append(Data([0x00, 0x00])) // Disk number
        endRecord.append(Data([0x00, 0x00])) // Central directory disk
        endRecord.append(contentsOf: withUnsafeBytes(of: UInt16(localFileHeaders.count).littleEndian) { Data($0) }) // Entries on disk
        endRecord.append(contentsOf: withUnsafeBytes(of: UInt16(localFileHeaders.count).littleEndian) { Data($0) }) // Total entries
        endRecord.append(contentsOf: withUnsafeBytes(of: UInt32(centralDirectorySize).littleEndian) { Data($0) }) // Central directory size
        endRecord.append(contentsOf: withUnsafeBytes(of: UInt32(centralDirectoryOffset).littleEndian) { Data($0) }) // Central directory offset
        endRecord.append(Data([0x00, 0x00])) // Comment length
        
        zipData.append(endRecord)
        
        // Write zip file
        do {
            try zipData.write(to: zipURL)
            return fileManager.fileExists(atPath: zipURL.path)
        } catch {
            print("Failed to write zip file: \(error)")
            return false
        }
    }
    
    private func exportAllPhotos() {
        guard !records.isEmpty else {
            exportMessage = "No photos to export."
            showExportAlert = true
            return
        }
        
        isExporting = true
        exportProgress = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            let sortedRecords = self.records.sorted { $0.captureDate < $1.captureDate }
            let tempDirectory = FileManager.default.temporaryDirectory
            
            // Create folder with timestamp
            let folderFormatter = DateFormatter()
            folderFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let folderName = "SelfieTimelapse_\(folderFormatter.string(from: Date()))"
            let folderURL = tempDirectory.appendingPathComponent(folderName)
            
            let fileManager = FileManager.default
            
            // Create the folder
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create folder: \(error)")
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.exportMessage = "Failed to create export folder."
                    self.showExportAlert = true
                }
                return
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            var savedCount = 0
            
            for (index, record) in sortedRecords.enumerated() {
                guard let image = UIImage(data: record.imageData),
                      let imageData = image.jpegData(compressionQuality: 0.9) else {
                    continue
                }
                
                // Create filename from date
                let filename = "Selfie_\(formatter.string(from: record.captureDate)).jpg"
                let fileURL = folderURL.appendingPathComponent(filename)
                
                do {
                    try imageData.write(to: fileURL)
                    savedCount += 1
                } catch {
                    print("Failed to save image: \(error)")
                }
                
                DispatchQueue.main.async {
                    self.exportProgress = Double(index + 1) / Double(sortedRecords.count)
                }
            }
            
            // Create zip file from folder
            let zipURL = tempDirectory.appendingPathComponent("\(folderName).zip")
            var zipSuccess = false
            
            if savedCount > 0 {
                zipSuccess = self.createZipFile(from: folderURL, to: zipURL)
                // Clean up the original folder after zipping
                try? fileManager.removeItem(at: folderURL)
            } else {
                // Clean up empty folder
                try? fileManager.removeItem(at: folderURL)
            }
            
            DispatchQueue.main.async {
                self.isExporting = false
                if !zipSuccess || savedCount == 0 {
                    self.exportMessage = savedCount == 0 ? "Failed to export photos." : "Failed to create zip file."
                    self.showExportAlert = true
                } else {
                    self.exportZipURL = zipURL
                    self.exportMessage = "Successfully exported \(savedCount) photos to folder."
                    self.showShareSheet = true
                }
            }
        }
    }
}

// StatItem removed — stats are available on Home screen

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @ViewBuilder let trailing: Trailing
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            trailing
        }
        .padding()
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        // For iPad support
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIApplication.shared.windows.first
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
