
// TimelapseViewModel.swift
import SwiftUI
import SwiftData
import Combine
class TimelapseViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var videoURL: URL?
    @Published var playbackSpeed = 10
    
    func generateVideo(from records: [SelfieRecord]) {
        isGenerating = true
        
        VideoGenerator.createTimelapse(from: records, fps: playbackSpeed) { url in
            DispatchQueue.main.async {
                self.isGenerating = false
                self.videoURL = url
            }
        }
    }
}
