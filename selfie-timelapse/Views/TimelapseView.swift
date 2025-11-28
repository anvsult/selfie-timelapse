

// TimelapseView.swift
import SwiftUI
import SwiftData
import AVKit

struct TimelapseView: View {
    @Query(sort: \SelfieRecord.captureDate) private var records: [SelfieRecord]
    @StateObject private var viewModel = TimelapseViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                if records.isEmpty {
                    ContentUnavailableView(
                        "No Selfies Yet",
                        systemImage: "photo.stack",
                        description: Text("Capture at least 2 selfies to create a timelapse")
                    )
                } else if viewModel.isGenerating {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Generating timelapse...")
                            .font(.headline)
                        Text("This may take a moment")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if let videoURL = viewModel.videoURL {
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .frame(maxHeight: 500)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                    
                    ShareLink(
                        item: videoURL,
                        message: Text("Check out my selfie timelapse!")
                    ) {
                        Label("Share Video", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        Text("\(records.count) selfies ready")
                            .font(.title2)
                            .bold()
                        
                        VStack(alignment: .leading) {
                            Text("Playback Speed")
                                .font(.headline)
                            
                            Picker("Speed", selection: $viewModel.playbackSpeed) {
                                Text("5 FPS").tag(5)
                                Text("10 FPS").tag(10)
                                Text("15 FPS").tag(15)
                                Text("30 FPS").tag(30)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Button {
                            viewModel.generateVideo(from: records)
                        } label: {
                            Label("Generate Timelapse", systemImage: "play.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(records.count < 2)
                    }
                    .padding()
                }
            }
            .navigationTitle("Timelapse")
            .toolbar {
                if viewModel.videoURL != nil {
                    Button("Create New") {
                        viewModel.videoURL = nil
                    }
                }
            }
        }
    }
}
