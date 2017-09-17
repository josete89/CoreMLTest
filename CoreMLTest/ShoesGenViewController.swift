//
//  ShoesGenViewController.swift
//  CoreMLTest
//
//  Created by Alcala, Jose Luis on 7/21/17.
//  Copyright © 2017 alcaljos. All rights reserved.
//

import UIKit
import CoreML

class ShoesGenViewController: UIViewController {

    let model = shoesGenerator()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let image = try? model.prediction(input1: generateRandomData()!)
        let byts  = convert(image)
        let visibleIMge = createImage(data: byts, width: 128, height: 128, components: 3)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     * Convert a MLMultiarray, containig Doubles, to a bytearray.
     */
    func convert(_ data: MLMultiArray) -> [UInt8] {
        
        var byteData: [UInt8] = []
        
        for i in 0..<data.count {
            let out = data[i]
            let floatOut = out as! Float32
            
            if DeviceInformation.simulator {
                let bytesOut = toByteArray((floatOut + 1.0) / 2.0)
                byteData.append(contentsOf: bytesOut)
            }
            else {
                let byteOut: UInt8 = UInt8((floatOut * 127.5) + 127.5)
                byteData.append(byteOut)
            }
        }
        
        return byteData
        
    }
    
    
    /**
     * Create a CGImage from a bytearray.
     */
    func createImage(data: [UInt8], width: Int, height: Int, components: Int) -> CGImage? {
        
        let colorSpace: CGColorSpace
        switch components {
        case 1:
            colorSpace = CGColorSpaceCreateDeviceGray()
            break
        case 3:
            colorSpace = CGColorSpaceCreateDeviceRGB()
            break
        default:
            fatalError("Unsupported number of components per pixel.")
        }
        
        let cfData = CFDataCreate(nil, data, width*height*components*bitsPerComponent / 8)!
        let provider = CGDataProvider(data: cfData)!
        
        let image = CGImage(width: width,
                            height: height,
                            bitsPerComponent: bitsPerComponent, //
            bitsPerPixel: bitsPerComponent * components, //
            bytesPerRow: ((bitsPerComponent * components) / 8) * width, // comps
            space: colorSpace,
            bitmapInfo: bitMapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: CGColorRenderingIntent.defaultIntent)!
        
        return image
        
    }
    
    
    func generateRandomData() -> MLMultiArray? {
        guard let input = try? MLMultiArray(shape: [100], dataType: MLMultiArrayDataType.double) else {
            return nil
        }
    
        for i in 0...99 {
            let number = 2 * Double(Float(arc4random()) / Float(UINT32_MAX)) - 1
            input[i] = NSNumber(floatLiteral: number)
        }
    
        return input
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
