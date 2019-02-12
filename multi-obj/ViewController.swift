//
//  ViewController.swift
//  multi-obj
//
//  Created by davydka on 2/6/19.
//  Copyright © 2019 davydka. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum BodyType : Int {
    case box = 1
    case plane = 2
    case car = 3
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var planes = [OverlayPlane]()
    
    private let label :UILabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // plane stuff
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.label.frame = CGRect(x: 0, y: 0, width: self.sceneView.frame.size.width, height: 44)
        self.label.center = self.sceneView.center
        self.label.textAlignment = .center
        self.label.textColor = UIColor.white
        self.label.font = UIFont.preferredFont(forTextStyle: .headline)
        self.label.alpha = 0
        self.sceneView.addSubview(self.label)
        // END plane stuff
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        let box = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
        
        let material = SCNMaterial()
        material.name = "Color"
        material.diffuse.contents = UIImage(named: "wood.jpeg")
        //  material.diffuse.contents = UIColor.blue
        
        let boxNode = SCNNode(geometry: box)
        boxNode.position = SCNVector3(0,0,-0.5)
        boxNode.geometry?.materials = [material]
        
        
        let sphere = SCNSphere(radius: 0.3)
        
        let material2 = SCNMaterial()
        material2.name = "Color"
        material2.diffuse.contents = UIImage(named: "earth.jpg")
        // material2.diffuse.contents = UIColor.red
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(0.5, 0, -0.5)
        sphereNode.geometry?.materials = [material2]
        
        self.sceneView.scene.rootNode.addChildNode(boxNode)
        self.sceneView.scene.rootNode.addChildNode(sphereNode)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        
        tapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.sceneView.addGestureRecognizer(doubleTapGestureRecognizer)
    }
    
    @objc func doubleTapped(recognizer :UIGestureRecognizer){
        let sceneView = recognizer.view as! ARSCNView
        let touchLocation = recognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(touchLocation, options: [:])
        
        if !hitResults.isEmpty {
            guard let hitResult = hitResults.first else {
                return
            }
            let node = hitResult.node
            node.physicsBody?.applyForce(
                SCNVector3(
                    hitResult.worldCoordinates.x,
                    hitResult.worldCoordinates.y,
                    hitResult.worldCoordinates.z
                ),
                asImpulse: true)
        }
    }
    
    @objc func tapped(recognizer :UIGestureRecognizer) {
        let sceneView = recognizer.view as! ARSCNView
        let touchLocation = recognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        
        if !hitResults.isEmpty {
            guard let hitResult = hitResults.first else {
                return
            }
            addModel(hitResult :hitResult)
        }
    }
    
    private func addModel(hitResult :ARHitTestResult) {
        let thisScene = SCNScene(named: "art.scnassets/Hush_3d_Block.scn")
        let thisNode = thisScene?.rootNode.childNode(withName: "polySurface3", recursively: true)
        thisNode?.scale = SCNVector3(0.05, 0.05, 0.05)
        thisNode?.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        thisNode?.physicsBody?.categoryBitMask = BodyType.box.rawValue
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.random()
        
        thisNode?.geometry?.materials = [material]
        
        thisNode?.position = SCNVector3(
            hitResult.worldTransform.columns.3.x,
            hitResult.worldTransform.columns.3.y + Float(0.5),
            hitResult.worldTransform.columns.3.z
        )
        self.sceneView.scene.rootNode.addChildNode(thisNode!)
    }
    
    /*
    @objc func tapped(recognizer :UIGestureRecognizer) {
    let sceneView = recognizer.view as! SCNView
    let touchLocation = recognizer.location(in: sceneView)
    let hitResults = sceneView.hitTest(touchLocation, options: [:])

    if !hitResults.isEmpty {
    let node = hitResults[0].node
    let material = node.geometry?.material(named: "Color")

    material?.diffuse.contents = UIColor.random()
    }
    }
    */
    
    private func addBox(hitResult :ARHitTestResult) {
        let boxGeometry = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.random()
        boxGeometry.materials = [material]
        let boxNode = SCNNode(geometry: boxGeometry)
        boxNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        boxNode.physicsBody?.categoryBitMask = BodyType.box.rawValue
        boxNode.position = SCNVector3(
            hitResult.worldTransform.columns.3.x,
            hitResult.worldTransform.columns.3.y + Float(0.5),
            hitResult.worldTransform.columns.3.z
        )
        
        self.sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            self.label.text = "Place Detected"
            
            UIView.animate(withDuration: 3.0, animations: {
                self.label.alpha = 1.0
            }) { (completion :Bool) in
                self.label.alpha = 0.0
            }
        }
        
        if !(anchor is ARPlaneAnchor) {
            return
        }
        
        let plane = OverlayPlane(anchor: anchor as! ARPlaneAnchor)
        self.planes.append(plane)
        node.addChildNode(plane)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        let plane = self.planes.filter { plane in
            return plane.anchor.identifier == anchor.identifier
        }.first
        
        if plane == nil {
            return
        }
        
        plane?.update(anchor: anchor as! ARPlaneAnchor)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

}
