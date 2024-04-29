/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains the object recognition view controller for the Breakfast Finder.
*/

import UIKit
import AVFoundation
import Vision

class VisionObjectRecognitionViewController: ViewController {
    var maxProbValue:String = ""
    var bestMaskIdx = 0
    let imageViewWidth = CGFloat(678/2)
    let imageViewHeight = CGFloat(452/2)
    var sentences = [""]
    var currentSentenceIndex = 0
    let sentenceLayer = CATextLayer()
    var begin_measure = false
    var window_index = 0
    var boundingBoxWindow = [CGRect](repeating: CGRect(x:0, y:0, width:0, height:0), count: 3)
    
    private var detectionOverlay: CALayer! = nil
    
    // Vision parts
    private var requests = [VNRequest]()
    private var requestsMeasure = [VNRequest]()
    
    @discardableResult
    func setupVision(mode: String) -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        
        if (mode == "measure") {
            print("measure")
            guard let modelURL = Bundle.main.url(forResource: "yolov8n-seg", withExtension: "mlmodelc") else {
                return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
            }
            guard let modelURLMeasure = Bundle.main.url(forResource: "measure_vol", withExtension: "mlmodelc") else {
                return NSError(domain: "VisionObjectRecognitionViewController1", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
            }
            do {
                let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
                let visionModelMeasure = try VNCoreMLModel(for: MLModel(contentsOf: modelURLMeasure))
                let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                    DispatchQueue.main.async(execute: {
                        // perform all the UI updates on the main queue
                        if let results = request.results {
                            self.drawVisionRequestResults(results)
                        }
                    })
                })
                let objectRecognitionMeasure = VNCoreMLRequest(model: visionModelMeasure, completionHandler: { (request, error) in
                    DispatchQueue.main.async(execute: {
                        // perform all the UI updates on the main queue
                        if let results = request.results {
                            self.drawVisionRequestResultsMeasure(results)
                            
                        }
                    })
                })
                self.requests = [objectRecognition]
                self.requestsMeasure = [objectRecognitionMeasure]
            } catch let error as NSError {
                print("Model loading went wrong: \(error)")
            }
        } else{
            self.drawRecipe(recipe: mode)
        }
        
        return error
    }
    
    func drawVisionRequestResultsMeasure(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        for observation in results where observation is VNCoreMLFeatureValueObservation{
            guard let objectObservation = observation as? VNCoreMLFeatureValueObservation else {
                continue
            }
            var int_val = 0
            var value = ""
            var oz_val = ""
            //print(objectObservation.featureValue)
            if(self.begin_measure == true) {
                let featureValue = objectObservation.featureValue
                if let multiArray = featureValue.multiArrayValue {
                    for row in 0..<multiArray.shape[0].intValue {
                        for col in 0..<multiArray.shape[1].intValue {
                            int_val = Int(multiArray[row * multiArray.strides[0].intValue + col * multiArray.strides[1].intValue].intValue)
                            value = String(int_val)
                            oz_val = String(round(Double(int_val)*10 / 29.574)/10)
                            //print(value+"ml/"+oz_val+"oz", terminator: " ") // Print each element separated by a space
                        }
                        //print() // Move to the next line after printing each row
                    }
                } else {
                    print("Feature value is not a multi-array")
                }
            } else {
                value = "0"
                oz_val = "0"
            }
            self.begin_measure = false
            let textLayer = CATextLayer()
            textLayer.name = "Object Label"
            textLayer.string = value + " ml\n" + oz_val + " oz"
            textLayer.foregroundColor = UIColor.black.cgColor
            textLayer.fontSize = 30
            textLayer.frame = CGRect(x: 0, y: 100, width: 100, height: 80)
            textLayer.contentsScale = 2.0 // retina rendering
            textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
            
            // Create a background layer
            let backgroundLayer = CALayer()
            backgroundLayer.backgroundColor = UIColor.cyan.withAlphaComponent(0.5).cgColor // Set background color
            backgroundLayer.frame = CGRect(x: 650, y: 150, width: 100, height: 250)
            
            // 创建一个矩形层作为按钮
            let buttonLayer = CALayer()
            buttonLayer.backgroundColor = UIColor.blue.cgColor
            buttonLayer.frame = CGRect(x: 50, y: 50, width: 50, height: 80)
            buttonLayer.cornerRadius = 5 // 可选：为按钮添加圆角
            
            let backTextLayer = CATextLayer()
            backTextLayer.name = "Back Text"
            backTextLayer.string = "Back"
            backTextLayer.foregroundColor = UIColor.white.cgColor
            backTextLayer.fontSize = 20
            backTextLayer.frame = CGRect(x: 30, y: 10, width: 50, height: 80)
            backTextLayer.contentsScale = 2.0 // retina rendering
            backTextLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
            
            // 添加点击手势
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            self.view.addGestureRecognizer(tapGesture)
            
            // add scale visual layer
            for x in 0..<320/5{
                let scaleLayer = CALayer()
                scaleLayer.frame = CGRect(x: 600 - x*5 , y: 50, width: 5, height: 50)
                if int_val < x*5 {
                    scaleLayer.backgroundColor = UIColor.cyan.withAlphaComponent(0.5).cgColor
                } else {
                    scaleLayer.backgroundColor = UIColor.blue.withAlphaComponent(0.6).cgColor
                }
                detectionOverlay.addSublayer(scaleLayer)
            }
            let scaleLayer = CALayer()
            scaleLayer.frame = CGRect(x: 600 , y: 50, width: 10, height: 50)
            scaleLayer.backgroundColor = UIColor.blue.withAlphaComponent(0.6).cgColor

            // 将矩形层添加到视图的层级结构中
            detectionOverlay.addSublayer(buttonLayer)
            buttonLayer.addSublayer(backTextLayer)
            
            detectionOverlay.addSublayer(backgroundLayer)
            backgroundLayer.addSublayer(textLayer)
            
//            detectionOverlay.addSublayer(scaleLayer)
            
        }
        
        self.updateLayerGeometry()
        CATransaction.commit()
    }
    
    
    func getBoundingBox(feature: MLMultiArray)->(CGRect,Float){
        var boundingBox = CGRect(x: 0,y: 0,width: 10,height: 10)
        
        var probMaxIdx = 0
        var maxProb : Float = 0
        var box_x : Float = 0
        var box_y : Float = 0
        var box_width : Float = 0
        var box_height : Float = 0
        //print(feature.shape[2].intValue-1)
        for j in 0..<feature.shape[2].intValue-1
        {
            //cup 41 + 4
            let key = [0,45,j] as [NSNumber]
            let nextKey = [0,45,j+1] as [NSNumber]
            if(feature[key].floatValue < feature[nextKey].floatValue){
                if(maxProb < feature[nextKey].floatValue){
                    probMaxIdx = j+1
                    let xKey = [0,0,probMaxIdx] as [NSNumber]
                    let yKey = [0,1,probMaxIdx] as [NSNumber]
                    let widthKey = [0,2,probMaxIdx] as [NSNumber]
                    let heightKey = [0,3,probMaxIdx] as [NSNumber]
                    maxProb = feature[nextKey].floatValue
                    box_width = feature[widthKey].floatValue
                    box_height = feature[heightKey].floatValue
                    
                    box_x = feature[xKey].floatValue - (box_width/2)
                    box_y = feature[yKey].floatValue - (box_height/2)
                }
            }
        }
    //        print(feature)
    //        for maskPrbIdx in 0..<feature.shape[1].intValue-1{
    //            let key = [0,maskPrbIdx,0] as [NSNumber]
    //            print(feature[key])
    //        }
        maxProbValue = "\(maxProb)"
        boundingBox = CGRect(x: CGFloat(box_x)/640
                             ,y: CGFloat(box_y)/640
                             ,width: CGFloat(box_width)/640
                             ,height: CGFloat(box_height)/640)//normalize
        //var maxMaskProb : Float = 0
        //var maxMaskIdx = 0
    //    for maskPrbIdx in 84..<feature.shape[1].intValue-1{
    //        let key = [0,maskPrbIdx,probMaxIdx] as [NSNumber]
    //        let nextKey = [0,maskPrbIdx+1,probMaxIdx] as [NSNumber]
    //        if(feature[key].floatValue < feature[nextKey].floatValue){
    //            if(maxMaskProb < feature[nextKey].floatValue){
    //                maxMaskIdx = maskPrbIdx+1
    //                maxMaskProb = feature[nextKey].floatValue
    //            }
    //        }
    //        bestMaskIdx = maxMaskIdx-84
    //        //print("bestId: %d", bestMaskIdx)
    //        //print("\(maskPrbIdx-5) Best mask probablity is \(maxMaskIdx-5) with value \(maxMaskProb)")
    //    }
        bestMaskIdx = probMaxIdx
        print("maxProb",maxProb)
        print("Bounding box from classifier \(boundingBox)")
        return (boundingBox, maxProb)
    }
    
    private func sigmoid(z:Float) -> Float{
        return 1.0/(1.0+exp(z))
    }
    
    func getMask(_ boundingBox: CGRect, masks: MLMultiArray, masks_weight:MLMultiArray) -> [[Float]]{
        //    let testImage = UIImage(contentsOfFile: Bundle.main.path(forResource: "tomcruise", ofType: "jpeg")!)!

        let scaledX : CGFloat = (boundingBox.minX)*bufferSize.width
        let scaledY : CGFloat = (boundingBox.minY)*bufferSize.height
        let scaledWidth : CGFloat = (boundingBox.width)*bufferSize.width
        let scaledHeight : CGFloat = (boundingBox.height)*bufferSize.height
        
        let rectangle = CGRect(x: scaledX, y: scaledY, width: scaledWidth, height: scaledHeight)
        print("scaled rectangle \(rectangle)")
        
        
        let maskProbThreshold : Float = 0.5
//        let maskFill : Float = 1.0
        //draw the mask
        var maskProbalities : [[Float]] = [] //this will contains 160x160 mask pixel probablities
        var maskProbYAxis : [Float] = []
        print("Actual Image bounds \(rectangle)")
        //get the bounds for mask to match the bounds
        let mask_x_min = (rectangle.minX/bufferSize.width)*160
        let mask_x_max = (rectangle.maxX/bufferSize.width)*160
        
        let mask_y_min = (rectangle.minY/bufferSize.height)*160
        let mask_y_max = (rectangle.maxY/bufferSize.height)*160
        
        var mask_point = Float(0.0)
        for y in 0..<masks.shape[2].intValue{
            maskProbYAxis.removeAll()
            for x in 0..<masks.shape[3].intValue{
                mask_point = Float(0.0)
                for z in 0..<masks.shape[1].intValue{
                    let pointKey = [0,z,y,x] as [NSNumber]
                    let weightKey = [0,z+84,bestMaskIdx] as [NSNumber]
                    mask_point = mask_point + masks[pointKey].floatValue * masks_weight[weightKey].floatValue
                }
                if(sigmoid(z: mask_point) < maskProbThreshold
                   && x >=  Int(mask_x_min) && x <= Int(mask_x_max)
                   && y >= Int(mask_y_min) && y <= Int(mask_y_max)){
                    maskProbYAxis.append(1.0)
                }
                else{
                    maskProbYAxis.append(0.0)
                }
            }
            maskProbalities.append(maskProbYAxis)
        }
        return maskProbalities
    }
    // Function to calculate the mean of CGRects
    func meanRect(of rects: [CGRect]) -> CGRect {
        guard !rects.isEmpty else { return .zero }
        
        // Initialize variables to accumulate the sum of properties
        var totalOriginX: CGFloat = 0
        var totalOriginY: CGFloat = 0
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        // Accumulate the sum of properties of each CGRect
        for rect in rects {
            totalOriginX += rect.origin.x
            totalOriginY += rect.origin.y
            totalWidth += rect.width
            totalHeight += rect.height
        }
        
        // Calculate the mean values
        let meanOriginX = totalOriginX / CGFloat(rects.count)
        let meanOriginY = totalOriginY / CGFloat(rects.count)
        let meanWidth = totalWidth / CGFloat(rects.count)
        let meanHeight = totalHeight / CGFloat(rects.count)
        
        // Create and return the mean CGRect
        return CGRect(x: meanOriginX, y: meanOriginY, width: meanWidth, height: meanHeight)
    }

    func drawVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
//        detectionOverlay.sublayers = nil // remove all the old recognized objects

        let result_0 = results[0] as! VNCoreMLFeatureValueObservation
        let result_1 = results[1] as! VNCoreMLFeatureValueObservation
        //print(result_0.featureName)
        //print(result_1.featureName)
        
        let boundingBox_result = getBoundingBox(feature:result_1.featureValue.multiArrayValue!)
        var boundingBox = boundingBox_result.0
//        if boundingBox_result.0.width != 0 &&  boundingBox_result.0.height != 0 {
            boundingBoxWindow[window_index] = boundingBox
            window_index = (window_index+1)%boundingBoxWindow.count
            print(window_index)
//        }
        //print("assf", boundingBoxWindow)
        boundingBox = meanRect(of: boundingBoxWindow)
        let confidence = boundingBox_result.1
        //print(confidence)
        if confidence > 0.03 {
//            let objectBounds = VNImageRectForNormalizedRect(boundingBox, Int(bufferSize.width), Int(bufferSize.height))
//
//            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
//            
//            //                let textLayer = self.createTextSubLayerInBounds(objectBounds,
//            //                                                                identifier: topLabelObservation.identifier,
//            //                                                                confidence: topLabelObservation.confidence)
//            //                shapeLayer.addSublayer(textLayer)
//            detectionOverlay.addSublayer(shapeLayer)
            let boundingBoxLayer = CALayer()
            boundingBoxLayer.frame = CGRect(x: boundingBox.minX*CGFloat(bufferSize.width), y: boundingBox.minY*CGFloat(bufferSize.height), width: boundingBox.width*CGFloat(bufferSize.width), height: boundingBox.height*CGFloat(bufferSize.height)) // Example bounding box
            //boundingBoxLayer.frame = CGRect(x: 100, y: 400, width: 100, height: 400) // Example bounding box
            boundingBoxLayer.borderColor = UIColor.red.cgColor
            boundingBoxLayer.borderWidth = 2.0
            print(bufferSize.width)
            boundingBoxLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(0)).scaledBy(x: 0.6, y: -1))
            
            
            let target_volume = 100.0 + 50//bottom error
            let target_height = target_volume/320
            let boundingBoxLayer2 = CALayer()
            boundingBoxLayer2.frame = CGRect(x: (boundingBox.minX+boundingBox.width*CGFloat(1-target_height))*CGFloat(bufferSize.width), y: boundingBox.minY*CGFloat(bufferSize.height), width: boundingBox.width*CGFloat(target_height)*CGFloat(bufferSize.width), height: boundingBox.height*CGFloat(bufferSize.height)) // Example bounding box
            boundingBoxLayer2.borderColor = UIColor.blue.cgColor
            boundingBoxLayer2.borderWidth = 2.0
            boundingBoxLayer2.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(0)).scaledBy(x: 0.6, y: -1))
//            let maskLayer = CALayer()
//            let mask = getMask(boundingBox, masks: result_0.featureValue.multiArrayValue!, masks_weight: result_1.featureValue.multiArrayValue!)
//            for y in 0..<mask.count {
//                for x in 0..<mask[y].count {
//                    let xFactor = Float(bufferSize.width) / 160
//                    let yFactor = Float(bufferSize.height) / 160
//                    let maskScaled_X = Double(x) * Double(xFactor)
//                    let maskScaled_Y = Double(y) * Double(yFactor)
//
//                    if mask[y][x] == 1.0 {
//                        let rectLayer = CALayer()
//                        rectLayer.frame = CGRect(x: maskScaled_X, y: maskScaled_Y, width: 2, height: 2)
//                        rectLayer.backgroundColor = UIColor.blue.withAlphaComponent(0.2).cgColor
//                        maskLayer.addSublayer(rectLayer)
//                    }
//                }
//            }
//            boundingBoxLayer.addSublayer(maskLayer)
            detectionOverlay.addSublayer(boundingBoxLayer)
            //detectionOverlay.addSublayer(boundingBoxLayer2)
            self.begin_measure = true
        }
        self.updateLayerGeometry()
        CATransaction.commit()
    }
    
    func drawRecipe(recipe: String) {
        detectionOverlay.sublayers = nil
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
        
        // 创建一个矩形层作为按钮
        let buttonLayer = CALayer()
        buttonLayer.backgroundColor = UIColor.blue.cgColor
        buttonLayer.frame = CGRect(x: 50, y: 50, width: 50, height: 80)
        buttonLayer.cornerRadius = 5 // 可选：为按钮添加圆角
        
        let backTextLayer = CATextLayer()
        backTextLayer.name = "Back Text"
        backTextLayer.string = "Back"
        backTextLayer.foregroundColor = UIColor.white.cgColor
        backTextLayer.fontSize = 20
        backTextLayer.frame = CGRect(x: 30, y: 10, width: 50, height: 80)
        backTextLayer.contentsScale = 2.0 // retina rendering
        backTextLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.view.addGestureRecognizer(tapGesture)
        
        // 将矩形层添加到视图的层级结构中
        detectionOverlay.addSublayer(buttonLayer)
        buttonLayer.addSublayer(backTextLayer)
        
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
//            self.navigationController?.popToRootViewController(animated: true)
            //removeAllCALayersFromLayer(self.detectionOverlay)
            self.detectionOverlay.removeFromSuperlayer()
            stopCaptureSession()
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
        
        do {
            try imageRequestHandler.perform(self.requestsMeasure)
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
        print(bounds.size.width)
        
        print(bounds.size.height)
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
