/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains the view controller for the Breakfast Finder.
*/

import UIKit
import AVFoundation
import Vision
import RealityKit
import SwiftUI

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var bufferSize: CGSize = .zero
    var rootLayer: CALayer! = nil
    
    @IBOutlet weak private var previewView: UIView!
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // to be implemented in the subclass
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Create a button
        let button = UIButton(type: .system)
        button.setTitle("Start Measure", for: .normal)
        button.addTarget(self, action: #selector(handleMeasureAVCapture(_:)), for: .touchUpInside)
        //Create recipe button
        let button_recipe = UIButton(type: .system)
        button_recipe.setTitle("Recipe", for: .normal)
        button_recipe.addTarget(self, action: #selector(setRecipeMenu), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 40)
        button_recipe.titleLabel?.font = UIFont.systemFont(ofSize: 40)
        
        // Add the button to the view
        view.addSubview(button)
        view.addSubview(button_recipe)
        
        // Set button's constraints (optional, you can adjust this based on your UI layout)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.bottomAnchor, constant: -280)
        ])
        
        // Set button's constraints (optional, you can adjust this based on your UI layout)
        button_recipe.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button_recipe.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button_recipe.centerYAnchor.constraint(equalTo: view.bottomAnchor, constant: -220)
        ])
        
        // Add logo image view
        let logoImageView = UIImageView(image: UIImage(named: "logo.png"))
        logoImageView.contentMode = .scaleAspectFit
        view.addSubview(logoImageView)
        
        // Set logo image view's constraints
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100), // Adjust the constant as needed
            logoImageView.widthAnchor.constraint(equalToConstant: 200), // Set width of logo image view
            logoImageView.heightAnchor.constraint(equalToConstant: 200) // Set height of logo image view
        ])
        
        if let navigationController = self.navigationController {
            navigationController.interactivePopGestureRecognizer?.delegate = nil
            navigationController.interactivePopGestureRecognizer?.isEnabled = true
        }
        
        // check number of pages and show back button
        if self.navigationController?.viewControllers.count ?? 0 > 1 {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))
        }
        //        setupAVCapture()
    }
    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func handleMeasureAVCapture(_ sender: UIButton) {
        setupAVCapture(mode: "measure")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func setRecipeMenu() {
        let alertController = UIAlertController(title: "Recipe Menu", message: nil, preferredStyle: .actionSheet)
        
        // Add recipe options
        let recipes = ["Amaro Caldo", "Americano", "1870's Sour"]
        for recipe in recipes {
            let action = UIAlertAction(title: recipe, style: .default) { action in
                // Handle selection of the recipe
                print("Selected Recipe: \(recipe)")
                // You can perform any action here, like navigating to a new page
                // Navigate to RecipeDetailViewController
                self.setupAVCapture(mode: recipe)
                //                recipeDetailVC.recipeName = recipe
                //self?.navigationController?.pushViewController(recipeDetailVC, animated: true)
            }
            alertController.addAction(action)
        }
        
        // Add cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Present the alert controller
        if let popoverController = alertController.popoverPresentationController {
            // For iPad
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func setupAVCapture(mode: String) {
        //        let inputFolderUrl = URL(fileURLWithPath: "/Users/zhuang52/Downloads/RecognizingObjectsInLiveCapture/images", isDirectory: true)
        //        let url = URL(fileURLWithPath: "./MyObject.usdz")
        //        var maybeSession: PhotogrammetrySession? = nil
        //        do {
        //            maybeSession = try PhotogrammetrySession(input: inputFolderUrl)
        //        } catch {
        //            print("Error info: \(error)")
        //            print("An error has occured")
        //        }
        //
        //        guard let dsession = maybeSession else {
        //            print("2 erorr has occured")
        //            return
        //        }
        //
        //        do {
        //            var request = PhotogrammetrySession.Request.modelFile(url: url)
        //            try dsession.process(requests: [ request ])
        //            // Enter the infinite loop dispatcher used to process asynchronous
        //            // blocks on the main queue. You explicitly exit above to stop the loop.
        //            RunLoop.main.run()
        //        } catch {
        //            print("Error info: \(error)")
        //            print("Something happened running session")
        //            return
        //        }
        
        var deviceInput: AVCaptureDeviceInput!
        // Select a video device, make an input
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = .iFrame960x540 // Model image size is smaller.
        
        // Add a video input
        guard session.canAddInput(deviceInput) else {
            print("Could not add video device input to the session")
            session.commitConfiguration()
            return
        }
        session.addInput(deviceInput)
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            // Add a video data output
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
            session.commitConfiguration()
            return
        }
        let captureConnection = videoDataOutput.connection(with: .video)
        // Always process the frames
        captureConnection?.isEnabled = true
        do {
            try  videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        session.commitConfiguration()
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        rootLayer = previewView.layer
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
    }
    
    func startCaptureSession() {
        DispatchQueue.global(qos: .background).async {
            // Start AVCaptureSession
            self.session.startRunning()
        }
    }
    
    func stopCaptureSession() {
        DispatchQueue.global(qos: .background).async {
            self.clearSessionConfiguration()
            self.teardownAVCapture()
            self.session.stopRunning()
        }
    }
    
    func clearSessionConfiguration() {
        session.beginConfiguration()

        // Remove all existing inputs
        for input in session.inputs {
            session.removeInput(input)
        }

        // Remove all existing outputs
        for output in session.outputs {
            session.removeOutput(output)
        }

        session.commitConfiguration()
    }

    
    // Clean up capture setup
    func teardownAVCapture() {
        DispatchQueue.global(qos: .background).async {
            self.previewLayer.removeFromSuperlayer()
            self.previewLayer = nil
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // print("frame dropped")
    }
    
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}

