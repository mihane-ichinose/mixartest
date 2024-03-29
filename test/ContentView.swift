//
//  ContentView.swift
//  test
//
//  Created by Huang, Zhi on 3/25/24.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    var body: some View {
        //        ARViewContainer().edgesIgnoringSafeArea(.all)
//        print("\(OpenCVWrapper.getOpenCVVersion())")

        CVImage(grayOut)
    }
}
struct CVImage: UIViewControllerRepresentable {
    
    func makeUIView(context: Context) -> UIImageView {
        print("\(OpenCVWrapper.getOpenCVVersion())")
        let rgbaIn = UIImage(named: "drinkingglasses.jpg")!
        let gray = OpenCVWrapper.grayscaleImg(rgbaIn)
        
        let imageview = UIImageView(image: gray)
        return imageview
    }
    func updateUIView(_ uiView: ARView, context: Context) {}
}
struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        print("\(OpenCVWrapper.getOpenCVVersion())")
        let rgbaIn = UIImage(named: "drinkingglasses.jpg")!
        let grayOut = OpenCVWrapper.grayscaleImg(rgbaIn)
        let arView = ARView(frame: .zero)

        // Create a cube model
        let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
        let material = SimpleMaterial(color: .gray, roughness: 0.15, isMetallic: true)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.transform.translation.y = 0.05

        // Create horizontal plane anchor for the content
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        anchor.children.append(model)

        // Add the horizontal plane anchor to the scene
        arView.scene.anchors.append(anchor)

        return arView
        
    }
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

#Preview {
//    print("\(OpenCVWrapper.getOpenCVVersion())")
    ContentView()
    
}
