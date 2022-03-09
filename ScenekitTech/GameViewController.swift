//
//  GameViewController.swift
//  ScenekitTech
//
//  Created by Richard Pickup on 12/02/2017.
//  Copyright © 2017 RP Software Ltd. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

public struct PixelData {
    var a:UInt8 = 255
    var r:UInt8
    var g:UInt8
    var b:UInt8
}

class GameViewController: UIViewController {

    let numShells = 60
    var scnView:SCNView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene();
       // let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
        
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
//        guard let ship = scene.rootNode.childNode(withName: "shipMesh", recursively: true) else {
//            return
//        }
        
        let ship = SCNNode(geometry: SCNPyramid(width: 1, height: 1, length: 1))
        
        let tigger = #imageLiteral(resourceName: "bigtiger")
        
//        guard let tigger = UIImage(named: "art.scnassets/texture.png") else {
//            return
//        }
            
        let myImage = generateTexture(image:tigger, width: Int(tigger.size.width), height: Int(tigger.size.height))

        
        ship.geometry?.firstMaterial?.diffuse.contents = tigger
        
        let attachNode = SCNNode()
        
        for  i in 0...numShells {
            let  iScale = Float(i) / Float(numShells)
            let cloneNode:SCNNode = (ship.clone())
            
            cloneNode.geometry = ship.geometry?.copy() as! SCNGeometry?
     
            
            let material = SCNMaterial()
            material.diffuse.contents = myImage
            
            cloneNode.geometry?.firstMaterial = material
            cloneNode.geometry?.firstMaterial?.isDoubleSided = true
            
            cloneNode.opacity = CGFloat(Float(1 - iScale));
            
            
            let scaleF = CGFloat(1 + iScale);
            cloneNode.scale = SCNVector3(scaleF,scaleF,scaleF);
   
            attachNode.addChildNode(cloneNode)
            
        };
        
        ship.addChildNode(attachNode)
        
        
        scene.rootNode.addChildNode(ship)
        

        // animate the 3d object
        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 2, y: 2, z: 2, duration: 5)))
        
        // retrieve the SCNView
        scnView = self.view as? SCNView
        
        // set the scene to the view
        scnView?.scene = scene
        
        // allows the user to manipulate the camera
        scnView?.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView?.showsStatistics = true
        
        // configure the view
        scnView?.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
    
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        scnView?.addGestureRecognizer(tapGesture)
    }
    

    
    @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result: AnyObject = hitResults[0]
            
            // get its material
            let material = result.node!.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
            
            
            SCNTransaction.commit()
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    private let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    private let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)

    
    func generateTexture(image: UIImage, width: Int, height:Int) -> UIImage {

        let bitsPerComponent:UInt = 8
        let bitsPerPixel:UInt = 32
                
        let colorArray = image.pixelData()
        
        var pixelArray = [PixelData](repeating: PixelData(a: 0, r:0, g: 0, b: 0), count: width * height)
        
        let totalPixels = width * height
        
        let nrStrands = Int(0.7 * Float(totalPixels))
        
        //compute the number of strands that stop at each layer
        let strandsPerLayer = nrStrands / numShells
        
        
        for i in 0...nrStrands {
            let x = arc4random_uniform(UInt32(height))
            let y = arc4random_uniform(UInt32(width))
            
            let index = Int(x) * width + Int(y)
            
            
            let max_layer = Float(i) / Float(strandsPerLayer)
            //normalize into [0..1] range
            var max_layer_n = Float(max_layer) / Float(numShells)
            
            
            max_layer_n = Float(sin(max_layer_n))
            
          //  max_layer_n = Float(pow(max_layer_n, 5))
            
          //  max_layer_n = Float(sqrt(max_layer_n))
            
            //put color (which has an alpha value of 255, i.e. opaque)
            //max_layer_n needs to be multiplied by 255 to achieve a color in [0..255] range
            
            let rVal = colorArray?[index].a
            let gVal = colorArray?[index].r
            let bVal = colorArray?[index].g
       
            let rValf = Float(rVal!) / 255.0 * max_layer_n
            let gValf = Float(gVal!) / 255.0 * max_layer_n
            let bValf = Float(bVal!) / 255.0 * max_layer_n
            
            let r = UInt8(rValf * 255)
            let g = UInt8(gValf * 255)
            let b = UInt8(bValf * 255)
            
            
            pixelArray[index].r = r
            pixelArray[index].g = g
            pixelArray[index].b = b
            pixelArray[index].a = 255
            
        }
        
        assert(pixelArray.count == Int(width * height))
        
        var data = pixelArray // Copy to mutable []
        let providerRef = CGDataProvider(
            data: NSData(bytes: &data, length: data.count * MemoryLayout<PixelData>.size)
        )
        
        let cgim = CGImage(
            width: width,
            height: height,
            bitsPerComponent: Int(bitsPerComponent),
            bitsPerPixel: Int(bitsPerPixel),
            bytesPerRow: width * MemoryLayout<PixelData>.size,
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef!,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
        
        
        let image = UIImage(cgImage: cgim!)
        return image
    }

}



extension UIImage {
    func pixelData() -> [PixelData]? {
        let size = self.size
        let dataSize = size.width * size.height * 4
    
        var pixelData = [PixelData](repeating: PixelData(a: 0, r:0, g: 0, b: 0), count: Int(dataSize))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: 4 * Int(size.width),
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        return pixelData
    }
}



