import SwiftUI
import Vision
import AVFoundation
import Combine

class FaceEmotionAnalyzer: NSObject, ObservableObject {

    @Published var currentEmotion: EmotionState = .focused
    @Published var smileScore: Double = 0.0
    @Published var attentionScore: Double = 1.0
    @Published var faceDetected: Bool = false

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "camera.queue")
    private var noFaceFrameCount = 0
    private let noFaceThreshold = 3
    private var emotionHistory: [EmotionState] = []
    private let historySize = 4

    override init() {
        super.init()
        setupCamera()
    }

    private func setupCamera() {
        captureSession.sessionPreset = .medium
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        if captureSession.canAddInput(input) { captureSession.addInput(input) }
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if captureSession.canAddOutput(videoOutput) { captureSession.addOutput(videoOutput) }
    }

    func start() {
        if !captureSession.isRunning {
            queue.async { self.captureSession.startRunning() }
        }
    }

    func stop() {
        if captureSession.isRunning {
            queue.async { self.captureSession.stopRunning() }
        }
    }

    private func smoothedEmotion(_ new: EmotionState) -> EmotionState {
        emotionHistory.append(new)
        if emotionHistory.count > historySize { emotionHistory.removeFirst() }
        let counts = Dictionary(grouping: emotionHistory, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? new
    }
}

extension FaceEmotionAnalyzer: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceLandmarksRequest { [weak self] req, _ in
            guard let self = self else { return }

            guard let results = req.results as? [VNFaceObservation], !results.isEmpty else {
                self.noFaceFrameCount += 1
                if self.noFaceFrameCount >= self.noFaceThreshold {
                    DispatchQueue.main.async {
                        self.faceDetected = false
                        self.currentEmotion = .away
                    }
                }
                return
            }

            self.noFaceFrameCount = 0
            let face = results[0]
            let eyeOpenness = self.getEyeOpenness(face)
            let yaw = abs(face.yaw?.doubleValue ?? 0)
            let raw = self.classify(eyeOpenness: eyeOpenness, yaw: yaw)
            let smoothed = self.smoothedEmotion(raw)

            DispatchQueue.main.async {
                self.faceDetected = true
                self.attentionScore = eyeOpenness
                self.currentEmotion = smoothed
            }
        }

        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored)
            .perform([request])
    }

    private func getEyeOpenness(_ obs: VNFaceObservation) -> Double {
        guard let lm = obs.landmarks,
              let le = lm.leftEye,
              let re = lm.rightEye else { return 0.5 }

        func ratio(_ pts: [CGPoint]) -> CGFloat {
            let ys = pts.map { $0.y }
            let xs = pts.map { $0.x }
            let h = (ys.max() ?? 0) - (ys.min() ?? 0)
            let w = (xs.max() ?? 0) - (xs.min() ?? 0)
            return w > 0 ? h / w : 0
        }

        let l = ratio(le.normalizedPoints)
        let r = ratio(re.normalizedPoints)
        // raw ratio: open eye ~0.25-0.35, half closed ~0.10-0.18, closed ~0.02-0.08
        let avg = Double((l + r) / 2)
        return avg // return RAW value, no normalization
    }

    private func classify(eyeOpenness: Double, yaw: Double) -> EmotionState {
        // Face turned away
        if yaw > 0.25 {
            return .away
        }
        // Use raw ratio directly — open eye ~0.25+, drowsy < 0.20
        if eyeOpenness < 0.20 {
            return .drowsy
        }
        return .focused
    }
}
