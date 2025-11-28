import AVFoundation
// CameraView.swift
import SwiftUI

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = CameraViewModel()
    @EnvironmentObject var locationManager: LocationManager
    @State private var showPreview = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isCameraAuthorized {
                    if let capturedImage = viewModel.capturedImage {
                        PreviewView(
                            image: capturedImage,
                            note: $viewModel.note,
                            tags: $viewModel.tags,
                            onSave: {
                                viewModel.saveRecord(
                                    context: modelContext,
                                    location: locationManager.location
                                )
                                showPreview = false
                            },
                            onRetake: {
                                viewModel.capturedImage = nil
                            }
                        )
                    } else {
                        CameraPreviewView(viewModel: viewModel)
                            .overlay(alignment: .top) {
                                FaceGuideOverlay()
                                    .padding(.top, 100)
                            }
                            .overlay(alignment: .bottom) {
                                Button {
                                    locationManager.requestLocation()
                                    viewModel.capturePhoto()
                                } label: {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 70, height: 70)
                                        .overlay {
                                            Circle()
                                                .stroke(.white, lineWidth: 3)
                                                .frame(width: 80, height: 80)
                                        }
                                }
                                .padding(.bottom, 40)
                            }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)

                        Text("Camera Access Required")
                            .font(.title3)
                            .bold()

                        Text(
                            "Please enable camera access in Settings to capture selfies"
                        )
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                        Button("Open Settings") {
                            if let url = URL(
                                string: UIApplication.openSettingsURLString
                            ) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle("Capture Selfie")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let viewModel: CameraViewModel

    func makeUIView(context: Context) -> UIView {
        let container = PreviewContainerUIView()
        container.backgroundColor = .black

        if let previewLayer = viewModel.getPreviewLayer() {
            container.setPreviewLayer(previewLayer)
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let container = uiView as? PreviewContainerUIView,
            let previewLayer = container.previewLayer
        {
            previewLayer.frame = container.bounds
        }
    }
}

/// A small container view that correctly hosts and resizes an `AVCaptureVideoPreviewLayer`.
final class PreviewContainerUIView: UIView {
    private(set) var previewLayer: AVCaptureVideoPreviewLayer?

    override class var layerClass: AnyClass {
        return CALayer.self
    }

    func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        // Remove previous preview layer if present
        if let existing = previewLayer {
            existing.removeFromSuperlayer()
        }

        previewLayer = layer
        layer.frame = bounds
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

struct FaceGuideOverlay: View {
    var body: some View {
        Circle()
            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
            .foregroundStyle(.white.opacity(0.5))
            .frame(width: 250, height: 250)
            .overlay {
                Text("Align your face")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.black.opacity(0.6))
                    .clipShape(Capsule())
                    .offset(y: 140)
            }
    }
}

struct PreviewView: View {
    let image: UIImage
    @Binding var note: String
    @Binding var tags: [String]
    let onSave: () -> Void
    let onRetake: () -> Void

    @State private var newTag = ""

    var body: some View {
        ScrollView {

            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Add Details (Optional)")
                        .font(.headline)

                    TextField(
                        "Write a short note…",
                        text: $note,
                        axis: .vertical
                    )
                    .padding(12)
                    .background(Color(.systemGray6).opacity(0.9))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .lineLimit(3)

                    HStack(spacing: 12) {
                        TextField("Add tag", text: $newTag)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )

                        Button(action: {
                            if !newTag.isEmpty {
                                tags.append(
                                    newTag.trimmingCharacters(
                                        in: .whitespacesAndNewlines
                                    )
                                )
                                newTag = ""
                            }
                        }) {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.accentColor)
                                .cornerRadius(8)
                        }
                        .disabled(
                            newTag.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ).isEmpty
                        )
                        .opacity(
                            newTag.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ).isEmpty ? 0.6 : 1
                        )
                    }

                    if !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    HStack(spacing: 8) {
                                        Text(tag)
                                            .font(.caption)
                                            .foregroundColor(.primary)

                                        Button(action: {
                                            tags.removeAll { $0 == tag }
                                        }) {
                                            Image(
                                                systemName: "xmark.circle.fill"
                                            )
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray5))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding()

                HStack(spacing: 16) {
                    Button(action: {
                        onRetake()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.headline)
                            Text("Retake")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.35))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.85), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .shadow(
                        color: Color.black.opacity(0.4),
                        radius: 4,
                        x: 0,
                        y: 2
                    )

                    Button(action: {
                        onSave()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark")
                                .font(.headline)
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .shadow(
                        color: Color.accentColor.opacity(0.35),
                        radius: 6,
                        x: 0,
                        y: 3
                    )
                }
                .padding()
            }
        }
    }
}
