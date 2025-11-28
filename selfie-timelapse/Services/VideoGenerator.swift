
// VideoGenerator.swift
import AVFoundation
import UIKit

class VideoGenerator {
    static func createTimelapse(from records: [SelfieRecord], fps: Int = 10, completion: @escaping (URL?) -> Void) {
        guard !records.isEmpty else {
            completion(nil)
            return
        }
        
        let sortedRecords = records.sorted { $0.captureDate < $1.captureDate }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("timelapse_\(UUID().uuidString).mov")
        
        guard let firstImage = UIImage(data: sortedRecords[0].imageData) else {
            completion(nil)
            return
        }
        
        let size = CGSize(width: 3024, height: 4032)
        
        guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mov) else {
            completion(nil)
            return
        }
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height
        ]
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
        
        videoWriter.add(writerInput)
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)
        
        var frameCount = 0
        let frameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
        
        for record in sortedRecords {
            guard let image = UIImage(data: record.imageData),
                  let pixelBuffer = image.pixelBuffer(size: size) else {
                continue
            }
            
            while !writerInput.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameCount))
            adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
            frameCount += 1
        }
        
        writerInput.markAsFinished()
        videoWriter.finishWriting {
            DispatchQueue.main.async {
                completion(videoWriter.status == .completed ? outputURL : nil)
            }
        }
    }
}
