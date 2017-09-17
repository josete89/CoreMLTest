//
//  ViewController.swift
//  CoreMLTest
//
//  Created by Alcala, Jose Luis on 7/17/17.
//  Copyright © 2017 alcaljos. All rights reserved.
//

import UIKit
import Vision
import CoreMedia

class ViewController: UIViewController {

    @IBOutlet weak var lable: UILabel!
    let model = Resnet50()
    var videoCapture: VideoCapture!
    let sema = DispatchSemaphore(value: 2)
    @IBOutlet weak var cameraView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setUpCamera()
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 50
        videoCapture.setUp { success in
            if success {
                // Add the video preview into the UI.
                if let previewLayer = self.videoCapture.previewLayer {
                    self.cameraView.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                self.videoCapture.start()
            }
        }
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = cameraView.bounds
    }
    
    func predict(pixelBuffer: CVPixelBuffer){
        guard let visionModel = try? VNCoreMLModel(for: model.model) else {
            print("Error: could not create Vision model")
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel, completionHandler: requestDidComplete)
        request.imageCropAndScaleOption = .centerCrop
        
        
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
        
    }
    
    func requestDidComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNClassificationObservation] {
            
            // The observations appear to be sorted by confidence already, so we
            // take the top 5 and map them to an array of (String, Double) tuples.
            let top5 = observations.prefix(through: 4)
                .map { ($0.identifier, Double($0.confidence)) }
            
            lable.text = top5.reduce("", { (res, entrySet) -> String in
                return res + entrySet.0
            })
            sema.signal()
        }
    }
    

}

extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        if let pixelBuffer = pixelBuffer {
            // For better throughput, perform the prediction on a background queue
            // instead of on the VideoCapture queue. We use the semaphore to block
            // the capture queue and drop frames when Core ML can't keep up.
            sema.wait()
            DispatchQueue.main.async {
                self.predict(pixelBuffer: pixelBuffer)
            }
        }
    }
}

