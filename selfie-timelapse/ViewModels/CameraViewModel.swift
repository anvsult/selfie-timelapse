
// CameraViewModel.swift
import SwiftUI
import AVFoundation
import SwiftData
import Combine
import CoreLocation

// TODO : The camera seems to being accessed at all times while the app is open which should only really happen when the capture tab is opened
class CameraViewModel: NSObject, ObservableObject {
    @Published var isCameraAuthorized = false
    @Published var capturedImage: UIImage?
    @Published var note: String = ""
    @Published var tags: [String] = []
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init() {
        super.init()
        checkCameraAuthorization()
    }
    
    func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isCameraAuthorized = granted
                }
            }
        default:
            isCameraAuthorized = false
        }
    }
    
    func setupCamera() -> AVCaptureVideoPreviewLayer? {
        // If already configured, return existing preview layer
        if let existing = self.previewLayer, let _ = self.captureSession {
            return existing
        }

        let session = AVCaptureSession()
        session.sessionPreset = .photo

        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: frontCamera) else {
            return nil
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        self.captureSession = session
        self.photoOutput = output

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        // Ensure preview is not mirrored for front camera
        if let connection = preview.connection {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
            connection.videoOrientation = .portrait
        }

        self.previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }

        return preview
    }

    /// Returns the existing preview layer if available, otherwise attempts to set up the camera.
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        if let preview = self.previewLayer {
            return preview
        }
        return setupCamera()
    }
    
    func capturePhoto() {
        guard let photoOutput = photoOutput else { return }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func startCamera() {
        guard let session = captureSession else { return }
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }
    
    func stopCamera() {
        captureSession?.stopRunning()
    }
    
    func saveRecord(context: ModelContext, location: CLLocation?) {
        guard let image = capturedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        let record = SelfieRecord(
            imageData: imageData,
            captureDate: Date(),
            latitude: location?.coordinate.latitude ?? 0,
            longitude: location?.coordinate.longitude ?? 0,
            note: note.isEmpty ? nil : note,
            tags: tags
        )
        
        context.insert(record)
        try? context.save()
        
        // Reset
        capturedImage = nil
        note = ""
        tags = []
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }

        // The front camera preview often appears mirrored. Ensure saved selfie is not mirrored by flipping horizontally.
        let corrected = unmirrorImage(image)

        DispatchQueue.main.async {
            self.capturedImage = corrected
        }
    }

    /// Returns a horizontally flipped copy of the provided image.
    private func unmirrorImage(_ image: UIImage) -> UIImage {
        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            ctx.cgContext.translateBy(x: size.width, y: 0)
            ctx.cgContext.scaleBy(x: -1, y: 1)
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
