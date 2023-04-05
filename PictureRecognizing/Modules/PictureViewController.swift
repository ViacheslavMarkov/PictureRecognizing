//
//  PictureViewController.swift
//  PictureRecognizing
//
//  Created by Viacheslav Markov on 04.04.2023.
//

import UIKit
import CoreML
import Vision

final class PictureViewController: UIViewController {

    var screenRect: CGRect = UIScreen.main.bounds
    
    private lazy var imageView: UIImageView = {
        let i = UIImageView()
        i.isUserInteractionEnabled = true
        i.contentMode = .scaleAspectFit
        return i
    }()
    
    private lazy var classifierLabel: UILabel = {
        let l = UILabel()
        l.font = .customFont(type: .medium, size: 18)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.textColor = .black
        return l
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        showLibrary()
    }
}

//MARK: - PictureViewController
private extension PictureViewController {
    func setupViews() {
        view.add([
            imageView,
            classifierLabel,
        ])
        
        imageView.autoPinEdgesToSuperView()
        view.bringSubviewToFront(classifierLabel)
        
        NSLayoutConstraint.activate([
            classifierLabel.bottom.constraint(equalTo: view.bottom, constant: -24),
            classifierLabel.leading.constraint(equalTo: view.leading, constant: 16),
            classifierLabel.trailing.constraint(equalTo: view.trailing, constant: -16),
        ])
        
        view.backgroundColor = .white
    }
    
    func showLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picker = UIImagePickerController()
            picker.allowsEditing = false
            picker.delegate = self
            picker.sourceType = .photoLibrary
            present(picker, animated: true)
        }
    }
    
    func detectImageContent() {
        guard
            let model = try? VNCoreMLModel(for: Test21().model)
        else {
            fatalError("Failed to load model")
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] (request, error) in
            guard let results = request.results as? [VNRecognizedObjectObservation],
                  let topResult = results.first
            else {
                print("Unexpected results")
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.classifierLabel.text = "Image has recognized with \(Int(topResult.confidence * 100))% confidence"
            }
        }
        
        let imageIt = imageView.image!
        guard
            let ciImage = CIImage(image: imageIt)
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
}

//MARK: - PictureViewController
extension PictureViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        guard let image = info[.originalImage] as? UIImage else {return}
        imageView.image = image
        classifierLabel.text = "Analyzing Image..."
        dismiss(animated: true, completion: nil)
        
        detectImageContent()
    }
}
