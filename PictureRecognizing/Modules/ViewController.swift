//
//  ViewController.swift
//  PictureRecognizing
//
//  Created by Viacheslav Markov on 30.03.2023.
//

import UIKit
import CoreML
import Vision
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var classifier: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupLayers()
    }
    
    @IBAction func cameraButtonTapped(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let image = UIImagePickerController()
            image.delegate = self
            image.sourceType = UIImagePickerController.SourceType.camera
            image.allowsEditing = false
            self.present(image,animated: true)
        }
    }
    
    @IBAction func libraryButtonTapped(_ sender: UIButton) {
//        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
//            let picker = UIImagePickerController()
//            picker.allowsEditing = false
//            picker.delegate = self
//            picker.sourceType = .photoLibrary
//            present(picker, animated: true)
//        }
    }
    
    func detectImageContent() {
        guard let model = try? VNCoreMLModel(for: Test21().model) else {
            fatalError("Failed to load model")
        }
        //        VanGoghFieldModel
        let request = VNCoreMLRequest(model: model) { [weak self] (request, error) in
            guard let results = request.results as? [VNRecognizedObjectObservation],
                  let topResult = results.first
            else {
                print("Unexpected results")
                return
            }
            
            self?.extractDetections(results)
            
            DispatchQueue.main.async { [weak self] in
                self?.classifier.text = "\(topResult.uuid) with \(Int(topResult.confidence * 100))% confidence"
            }
        }
        let imageIt = imageView.image!
        guard
            let ciImage = CIImage(image: imageIt )
        else {
            fatalError("Cant create CIImage from UIImage")
            
        }
        let handler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global().async {
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        }
    }
    
    var screenRect: CGRect = UIScreen.main.bounds // For view dimensions
    var detectionLayer: CALayer! = nil
    
    func extractDetections(_ results: [VNObservation]) {
        detectionLayer.sublayers = nil
        
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
            
            let boxLayer = drawBoundingBox(transformedBounds)
            detectionLayer.addSublayer(boxLayer)
            
            let v = drawView(transformedBounds)
            view.addSubview(v)
        }
    }
    
    func drawBoundingBox(_ bounds: CGRect) -> CALayer {
        let boxLayer = CALayer()
        boxLayer.frame = bounds
        boxLayer.borderWidth = 3.0
        boxLayer.borderColor = CGColor.init(red: 100.0, green: 100.0, blue: 100.0, alpha: 1.0)
        boxLayer.cornerRadius = 4
        return boxLayer
    }
    
    func drawView(_ bounds: CGRect) -> UIView {
        let v = UIView()
        v.frame = bounds
        v.layer.borderWidth = 3.0
        v.layer.borderColor = UIColor.red.cgColor
        v.layer.cornerRadius = 4
        v.backgroundColor = .green
        return v
    }
    
    func setupLayers() {
        detectionLayer = CALayer()
        detectionLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        view.layer.addSublayer(detectionLayer)
    }
}

//MARK: - ViewController
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        guard let image = info[.originalImage] as? UIImage else {return}
        imageView.image = image
        classifier.text = "Analyzing Image..."
        dismiss(animated: true, completion: nil)
        
        detectImageContent()
    }
}
