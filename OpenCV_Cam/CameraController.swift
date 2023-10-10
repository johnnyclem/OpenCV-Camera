//
//  CameraController.swift
//  OpenCV_Cam
//
//  Created by Jonathan Clem on 10/9/23.
//

import UIKit
import AVFoundation

protocol CameraControllerDelegate: AnyObject {
    func didCapture(image: UIImage)
}

class CameraController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    private let context = CIContext()
    private let sessionQueue = DispatchQueue(label: "AVCaptureSessionQueue")
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    var cameraPosition = AVCaptureDevice.Position.front
    private var hasCameraPermissions = false {
        didSet {
            if hasCameraPermissions == true {
                // configure capture session on background queue
                self.sessionQueue.async { [unowned self] in
                    self.configureCaptureSession()
                    self.captureSession.startRunning()
                }
            }
        }
    }

    weak var delegate: CameraControllerDelegate?
    
    override init() {
        super.init()
        // acquire camera usage permissions
        self.checkCameraPermissions()
    }
    
    public func switchCameraPosition() {
        self.sessionQueue.async { [unowned self] in
            // lock session for configuration
            self.captureSession.beginConfiguration()
            // remove existing input
            if let currentInput = self.captureSession.inputs.first {
                self.captureSession.removeInput(currentInput)
            }
            if let currentOutput = self.captureSession.outputs.first {
                self.captureSession.removeOutput(currentOutput)
            }
            self.cameraPosition = self.cameraPosition == .front ? .back : .front
            // unlock the session
            self.captureSession.commitConfiguration()
            self.configureCaptureSession()
        }
    }
    
    func configureCaptureSession() {
        guard hasCameraPermissions == true else {
            print("unable to acquire camera permissions")
            return
        }
        guard let captureDevice = captureDeviceForFrontCamera() else {
            print("unable to get front face camera")
            return
        }
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("failed to create capture device input from capture device")
            return
        }
        // lock session for configuration
        captureSession.beginConfiguration()
        // add video input
        if captureSession.canAddInput(captureDeviceInput) {
            captureSession.addInput(captureDeviceInput)
        }
        // add video output and declare self as output delegate
        videoDataOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        // set video preset
        captureSession.sessionPreset = AVCaptureSession.Preset.vga640x480
        // set orientation
        if let connection = videoDataOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
            // set mirroring
            if self.cameraPosition == .front && connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            } else {
                connection.isVideoMirrored = false
            }
        }
        // unlock session
        captureSession.commitConfiguration()
    }
    
    func captureDeviceForFrontCamera() -> AVCaptureDevice? {
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: self.cameraPosition
        )
        return deviceDiscoverySession.devices.first
    }
    
    func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            self.hasCameraPermissions = true
        case .notDetermined:
            self.requestCameraPermissions()
        default:
            self.hasCameraPermissions = false
        }
    }
    
    func requestCameraPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] status in
            self.hasCameraPermissions = status
        }
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // get image buffer from sample buffer
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("unable to convert sample buffer to image buffer")
            return
        }
        // convert image buffer to CI image
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        // convert to CGImage
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("unable to convert CIImage into CGImage")
            return
        }
        // return uiimage to delegate
        self.delegate?.didCapture(image: UIImage(cgImage: cgImage))
    }
}
