//
//  NextViewController.swift
//  PictureRecognizing
//
//  Created by Viacheslav Markov on 03.04.2023.
//

import UIKit
import SwiftUI
import AVFoundation
import Vision


class NextViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private var permissionGranted = false // Flag for permission
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private var previewLayer = AVCaptureVideoPreviewLayer()
    
    var screenRect: CGRect = UIScreen.main.bounds // For view dimensions
    
    // Detector
    private var videoOutput = AVCaptureVideoDataOutput()
    var requests = [VNRequest]()
    var detectionLayer: CALayer! = nil
    
    public lazy var frameView: FrameView = {
        let v = FrameView()
        v.isUserInteractionEnabled = true
//        v.isHidden = true
//        v.backgroundColor = .red
        return v
    }()
      
    override func viewDidLoad() {
        checkPermission()
        
        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            self.setupCaptureSession()
            
            self.setupLayers()
            
            self.setupDetector()
            
            self.captureSession.startRunning()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        setupViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        frameView.isHidden = true
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        screenRect = UIScreen.main.bounds
        self.previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)

        switch UIDevice.current.orientation {
            // Home button on top
            case UIDeviceOrientation.portraitUpsideDown:
                self.previewLayer.connection?.videoOrientation = .portraitUpsideDown
             
            // Home button on right
            case UIDeviceOrientation.landscapeLeft:
                self.previewLayer.connection?.videoOrientation = .landscapeRight
            
            // Home button on left
            case UIDeviceOrientation.landscapeRight:
                self.previewLayer.connection?.videoOrientation = .landscapeLeft
             
            // Home button at bottom
            case UIDeviceOrientation.portrait:
                self.previewLayer.connection?.videoOrientation = .portrait
                
            default:
                break
            }
        
        // Detector
        updateLayers()
    }
    
    private func setupViews() {
        view.add([frameView])
        view.bringSubviewToFront(frameView)
//        frameView.isHidden = true
    }
    
    private func updateFrameView(_ bounds: CGRect) {
        UIView.animate(withDuration: 0.1) {
            self.frameView.bounds.size = bounds.size
            self.frameView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        }
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            // Permission has been granted before
            case .authorized:
                permissionGranted = true
                
            // Permission has not been requested yet
            case .notDetermined:
                requestPermission()
                    
            default:
                permissionGranted = false
            }
    }
    
    func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    func setupCaptureSession() {
        // Camera input
        guard
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        else { return }
        
        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice)
        else { return }
           
        guard
            captureSession.canAddInput(videoDeviceInput)
        else { return }
        
        captureSession.addInput(videoDeviceInput)
                         
        // Preview layer
        screenRect = UIScreen.main.bounds
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill // Fill screen
        previewLayer.connection?.videoOrientation = .portrait
        
        // Detector
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        captureSession.addOutput(videoOutput)
        
        videoOutput.connection(with: .video)?.videoOrientation = .portrait
        
        // Updates to UI must be on main queue
        DispatchQueue.main.async { [weak self] in
            self!.view.layer.addSublayer(self!.previewLayer)
        }
    }
}

extension NextViewController {
    func setupDetector() {
        
        guard let visionModel = try? VNCoreMLModel(for: Test21().model) else {
            fatalError("Failed to load model")
        }
        
        let recognitions = VNCoreMLRequest(model: visionModel, completionHandler: detectionDidComplete)
        self.requests = [recognitions]
        
//        let modelURL = Bundle.main.url(forResource: "YOLOv3TinyInt8LUT", withExtension: "mlmodelc")
//
//        do {
//            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL!))
//            let recognitions = VNCoreMLRequest(model: visionModel, completionHandler: detectionDidComplete)
//            self.requests = [recognitions]
//        } catch let error {
//            print(error)
//        }
    }
    
    func detectionDidComplete(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: {
            if let results = request.results {
                self.extractDetections(results)
            }
        })
    }
    
    func extractDetections(_ results: [VNObservation]) {
        detectionLayer.sublayers = nil
        
        frameView.isHidden = results.isEmpty
        
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else { continue }
            
            // Transformations
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(screenRect.size.width ), Int(screenRect.size.height))
            let transformedBounds = CGRect(
                x: objectBounds.minX,
                y: screenRect.size.height - objectBounds.maxY,
                width: objectBounds.maxX - objectBounds.minX,
                height: objectBounds.maxY - objectBounds.minY
            )
            
//            let v = drawView(transformedBounds)
//            view.addSubview(v)
//            view.bringSubviewToFront(v)
            
            updateFrameView(transformedBounds)
        }
    }
    
    func drawView(_ bounds: CGRect) -> UIView {
        let v = UIView()
        v.frame = bounds
        v.layer.borderWidth = 3.0
        v.layer.borderColor = UIColor.red.cgColor
        v.layer.cornerRadius = 4
        v.backgroundColor = .clear
        return v
    }
    
    func drawBoxes(_ objectBounds: CGRect, label: String) -> CAShapeLayer {
        let boxLayer = CAShapeLayer()
        boxLayer.bounds = objectBounds
        boxLayer.position = CGPoint(x: objectBounds.midX, y: objectBounds.midY)
        boxLayer.borderColor = UIColor.red.cgColor
        return boxLayer
    }
    
    func setupLayers() {
        detectionLayer = CALayer()
        detectionLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
//        view.layer.addSublayer(detectionLayer)
        view.layer.insertSublayer(detectionLayer, below: view.layer)
    }
    
    func updateLayers() {
        detectionLayer?.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:]) // Create handler to perform request on the buffer
        do {
            try imageRequestHandler.perform(self.requests) // Schedules vision requests to be performed
        } catch {
            print(error)
        }
    }
}
