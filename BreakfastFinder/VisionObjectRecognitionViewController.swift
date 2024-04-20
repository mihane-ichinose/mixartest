/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains the object recognition view controller for the Breakfast Finder.
*/

import UIKit
import AVFoundation
import Vision

class VisionObjectRecognitionViewController: ViewController {
    
    var sentences = [""]
    var currentSentenceIndex = 0
    let sentenceLayer = CATextLayer()
    
    private var detectionOverlay: CALayer! = nil
    
    // Vision parts
    private var requests = [VNRequest]()
    
    @discardableResult
    func setupVision(mode: String) -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        if (mode == "measure") {
            print("measure")
            guard let modelURL = Bundle.main.url(forResource: "measure_vol", withExtension: "mlmodelc") else {
                return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
            }
            do {
                let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
                let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                    DispatchQueue.main.async(execute: {
                        // perform all the UI updates on the main queue
                        if let results = request.results {
                            self.drawVisionRequestResults(results)
                        }
                    })
                })
                self.requests = [objectRecognition]
            } catch let error as NSError {
                print("Model loading went wrong: \(error)")
            }
        } else{
            print("Recipe")
            self.drawRecipe(recipe: mode)
        }
        
        return error
    }
    
    func drawVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        for observation in results where observation is VNCoreMLFeatureValueObservation{
            guard let objectObservation = observation as? VNCoreMLFeatureValueObservation else {
                continue
            }
            var value = ""
            //print(objectObservation.featureValue)
            let featureValue = objectObservation.featureValue
                if let multiArray = featureValue.multiArrayValue {
                        for row in 0..<multiArray.shape[0].intValue {
                            for col in 0..<multiArray.shape[1].intValue {
                                value = String(Int(multiArray[row * multiArray.strides[0].intValue + col * multiArray.strides[1].intValue].intValue))
                                print(value+"ml", terminator: " ") // Print each element separated by a space
                            }
                            print() // Move to the next line after printing each row
                        }
                    } else {
                        print("Feature value is not a multi-array")
                    }
            let textLayer = CATextLayer()
            textLayer.name = "Object Label"
            textLayer.string = value + " ml"
            textLayer.foregroundColor = UIColor.black.cgColor
            textLayer.fontSize = 40
            textLayer.frame = CGRect(x: 0, y: 100, width: 100, height: 50)
            textLayer.contentsScale = 2.0 // retina rendering
            textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
            
            // Create a background layer
            let backgroundLayer = CALayer()
            backgroundLayer.backgroundColor = UIColor.yellow.withAlphaComponent(0.5).cgColor // Set background color
            backgroundLayer.frame = CGRect(x: 650, y: 200, width: 100, height: 350)
            
            // 创建一个矩形层作为按钮
           let buttonLayer = CALayer()
           buttonLayer.backgroundColor = UIColor.blue.cgColor
           buttonLayer.frame = CGRect(x: 20, y: 50, width: 100, height: 50)
           buttonLayer.cornerRadius = 5 // 可选：为按钮添加圆角

           // 添加点击手势
           let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
           self.view.addGestureRecognizer(tapGesture)

           // 将矩形层添加到视图的层级结构中
           self.view.layer.addSublayer(buttonLayer)

            detectionOverlay.addSublayer(backgroundLayer)
            backgroundLayer.addSublayer(textLayer)
        }
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0]
//            if topLabelObservation.identifier != "bottle" {
//                continue
//            }
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            
            let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                            identifier: topLabelObservation.identifier,
                                                            confidence: topLabelObservation.confidence)
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
            print(objectObservation.boundingBox.origin.x * bufferSize.width, objectObservation.boundingBox.origin.y * bufferSize.height, objectObservation.boundingBox.width * bufferSize.width,
                  objectObservation.boundingBox.height * bufferSize.height)
        }
        self.updateLayerGeometry()
        CATransaction.commit()
    }
    
    func drawRecipe(recipe: String) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        if (recipe == "Amaro Caldo") {
            sentences = ["Add 3 oz of water", "Add 1.5 oz of amaro", "Stir well", "Add 1 slice of lemon"]
        } else if (recipe == "Americano") {
            sentences = ["Add 1.5 oz of campari", "Add 1.5 oz of sweet vermouth", "Add 3 oz of club soda", "Add ice and stir", "Add 1 slice of lemon"]
        } else if (recipe == "1870's Sour") {
            sentences = ["Add 2 oz of whiskey", "Add 1 oz of lemon juice", "Add 0.75 oz of maple syrup", "Add 0.25 oz of blueberry jam", "Add 0.5 oz of egg white", "Shake ingredients until foamy", "Shake with ice", "Strain into glass over ice", "Add 0.5 oz of red wine"]
        }
        
        sentenceLayer.string = sentences[currentSentenceIndex]
        sentenceLayer.foregroundColor = UIColor.black.cgColor
        sentenceLayer.alignmentMode = .center
        sentenceLayer.isWrapped = true
        sentenceLayer.fontSize = 30
        sentenceLayer.frame = CGRect(x: 20, y: 100, width: self.view.bounds.width - 40, height: 80)
        
        
        let backgroundLayer = CALayer()
        backgroundLayer.backgroundColor = UIColor.white.withAlphaComponent(0.5).cgColor // 白色背景，50% 透明度
        backgroundLayer.frame = sentenceLayer.frame.insetBy(dx: -10, dy: -10) // 背景比文本层稍大一些
        backgroundLayer.cornerRadius = 5 // 可选：为背景添加圆角

        self.view.layer.addSublayer(backgroundLayer)
        view.layer.addSublayer(sentenceLayer)

        let prevButton = UIButton(type: .system)
        prevButton.setTitle("Prev", for: .normal)
        prevButton.frame = CGRect(x: 20, y: self.view.bounds.height - 100, width: 100, height: 50)
        prevButton.addTarget(self, action: #selector(goToPreviousSentence), for: .touchUpInside)
        view.addSubview(prevButton)

        let nextButton = UIButton(type: .system)
        nextButton.setTitle("Next", for: .normal)
        nextButton.frame = CGRect(x: self.view.bounds.width - 120, y: self.view.bounds.height - 100, width: 100, height: 50)
        nextButton.addTarget(self, action: #selector(goToNextSentence), for: .touchUpInside)
        view.addSubview(nextButton)
        
        
        self.updateLayerGeometry()
        CATransaction.commit()
    }
    
    @objc func goToPreviousSentence() {
        if currentSentenceIndex > 0 {
            currentSentenceIndex -= 1
            sentenceLayer.string = sentences[currentSentenceIndex]
        }
    }

    @objc func goToNextSentence() {
        if currentSentenceIndex < sentences.count - 1 {
            currentSentenceIndex += 1
            sentenceLayer.string = sentences[currentSentenceIndex]
        }
    }
    
    @objc func handleTap(gesture: UITapGestureRecognizer) {
        // 检查点击位置是否在按钮层的范围内
        let point = gesture.location(in: self.view)
        if self.view.layer.sublayers?.first(where: { $0.frame.contains(point) }) != nil {
            // 如果是按钮层被点击，返回上一个页面
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let exifOrientation = exifOrientationFromDeviceOrientation()
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    override func setupAVCapture(mode: String) {
        super.setupAVCapture(mode: mode)
        
        // setup Vision parts
        setupLayers()
        updateLayerGeometry()
        setupVision(mode: mode)
        
        // start the capture
        startCaptureSession()
    }
    
    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: bufferSize.width,
                                         height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
        
    }
    
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence:  %.2f", confidence))
        let largeFont = UIFont(name: "Helvetica", size: 24.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
    
}
