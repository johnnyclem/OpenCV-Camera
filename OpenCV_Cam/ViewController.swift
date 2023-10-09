//
//  ViewController.swift
//  OpenCV_Cam
//
//  Created by Jonathan Clem on 10/9/23.
//

import UIKit

class ViewController: UIViewController, CameraControllerDelegate {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var processSelection: UISegmentedControl!
    @IBOutlet var blurryLabel: UILabel!
    
    private let imageProcessingQueue = DispatchQueue(label: "ImageProcessingQueue")
    private var cameraController: CameraController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.cameraController = CameraController()
        self.cameraController.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.imageView.frame = self.view.bounds
    }

    @IBAction func switchCamera() {
        self.cameraController.switchCameraPosition()
    }
    
    //MARK: CameraControllerDelegate
    func didCapture(image: UIImage) {

        DispatchQueue.main.async {
            self.blurryLabel.isHidden = true

            switch self.processSelection.selectedSegmentIndex {
            case 0:
                self.imageView.image = OpenCVDetector.detectFeatures(in: image, forSpecies: "human")
            case 1:
                self.imageView.image = OpenCVDetector.detectFeatures(in: image, forSpecies: "cat")
            default:
                let status = OpenCVDetector.check(forBurryImage: image)
                if status == true {
                    self.blurryLabel.isHidden = false
                }
                self.imageView.image = image
            }
        }
    }
}

