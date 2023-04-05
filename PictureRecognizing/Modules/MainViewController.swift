//
//  MainViewController.swift
//  PictureRecognizing
//
//  Created by Viacheslav Markov on 04.04.2023.
//

import UIKit

import UIKit
import SwiftUI
import AVFoundation
import Vision

final class MainViewController: UIViewController {
    
    private var permissionGranted = false // Flag for permission
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private var previewLayer = AVCaptureVideoPreviewLayer()
    
    private var screenRect: CGRect = UIScreen.main.bounds 
    private var videoOutput = AVCaptureVideoDataOutput()
    private var requests = [VNRequest]()
    
    public lazy var cameraView: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = true
        v.backgroundColor = .clear
        return v
    }()
    
    public lazy var frameView: FrameView = {
        let v = FrameView()
        v.isUserInteractionEnabled = true
        v.isHidden = true
        return v
    }()
    
    private lazy var topView: HeaderView = {
        let v = HeaderView(viewHeight: 100)
        v.isUserInteractionEnabled = true
        return v
    }()
    
    private lazy var bottomView: FooterView = {
        let v = FooterView(viewHeight: 80)
        v.isUserInteractionEnabled = true
        return v
    }()
    
    override func viewDidLoad() {
        checkPermission()
        
        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            self.setupCaptureSession()
            self.setupDetector()
            self.captureSession.startRunning()
        }
        
        setupViews()
        setupDelegates()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

//MARK: - MainViewController
private extension MainViewController {
    func setupDetector() {
        guard let visionModel = try? VNCoreMLModel(for: Test21().model) else {
            fatalError("Failed to load model")
        }
        
        let recognitions = VNCoreMLRequest(model: visionModel, completionHandler: detectionDidComplete)
        requests = [recognitions]
    }
    
    func detectionDidComplete(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: {
            if let results = request.results {
                self.bottomView.updateTitle(with: "Image has recognized with \(Int((results.first?.confidence ?? 0) * 100))% confidence")
                self.extractDetections(results)
            }
        })
    }
    
    func extractDetections(_ results: [VNObservation]) {
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
            
            updateFrameView(transformedBounds)
        }
    }
}

//MARK: - MainViewController
private extension MainViewController {
    func setupViews() {
        view.add([
            cameraView,
            topView,
            frameView,
            bottomView
        ])
        
        cameraView.autoPinEdgesToSuperView()
        view.bringSubviewToFront(frameView)
        
        NSLayoutConstraint.activate([
            topView.top.constraint(equalTo: view.top),
            topView.leading.constraint(equalTo: view.leading),
            topView.trailing.constraint(equalTo: view.trailing),
            
            bottomView.bottom.constraint(equalTo: view.bottom),
            bottomView.leading.constraint(equalTo: view.leading),
            bottomView.trailing.constraint(equalTo: view.trailing),
        ])
        
        view.backgroundColor = .clear
        frameView.isHidden = true
    }
    
    func setupDelegates() {
        topView.delegate = self
        bottomView.delegate = self
    }
    
    func showGallery() {
        let vc = PictureViewController()
        present(vc, animated: true)
    }
    
    private func updateFrameView(_ bounds: CGRect) {
        UIView.animate(withDuration: 0.1) {
            self.frameView.bounds.size = bounds.size
            self.frameView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        }
    }
}

//MARK: - HeaderViewDelegating
extension MainViewController: HeaderViewDelegating {
    func didTapGalleryButton(_ sender: HeaderView) {
        showGallery()
    }
}

//MARK: - FooterViewDelegating
extension MainViewController: FooterViewDelegating {
    func didTapTitle(_ sender: FooterView) {
        
    }
}

//MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension MainViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    private func checkPermission() {
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
    
    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] (granted) in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    private func setupCaptureSession() {
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
            guard let self = self else { return }
            self.cameraView.layer.addSublayer(self.previewLayer)
        }
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
