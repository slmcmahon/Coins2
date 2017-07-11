//
//  CoinViewModel.swift
//  Coins2
//
//  Created by Stephen McMahon on 6/20/17.
//  Copyright © 2017 Stephen McMahon. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class CoinViewModel {
    var _coinLookup : [String:String]
    
    init() {
        _coinLookup = [
            "b579bb4d-8b73-4609-bc79-168aaa5d499e": "Quarter",
            "e37e12e1-7371-4453-9b9d-0ad1a3f66b3f": "Penny",
            "16d39636-5ce5-4022-a98f-85e66e84a524": "Nickel",
            "9280095b-0241-42fd-9d3f-2f4606bb36db": "Half Dollar",
            "9011fba8-63e6-408f-b59c-f18dff457464": "Dollar",
            "e95f0bd8-4759-4e1d-8736-7031f7d4834b": "Dime"
        ]
    }
    
    func recognizeImage(onSuccess:@escaping (String) -> Void, onFailure:@escaping (String) -> Void, image : UIImage) {
        let resized = self.resizeImage(image: image, size: CGSize(width: image.size.width / 4.0, height: image.size.height / 4.0))
        let imgData = UIImagePNGRepresentation(resized)
        
        Alamofire.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(imgData!, withName: "image",fileName: "png", mimeType: "image/png")
        }, to:Constants.RecognizerUrl, headers: ["Prediction-Key" : Constants.PredictionKey])
        { (result) in
            switch result {
            case .success(let upload, _, _):
                
                upload.uploadProgress(closure: { (progress) in
                    print("Upload Progress: \(progress.fractionCompleted)")
                })
                
                upload.responseJSON { response in
                    print(response.result.value ?? "")
                    let json = JSON(response.result.value ?? "")
                    let predictions = json["Predictions"].array!
                    onSuccess(self.readPredictions(predictions: predictions))
                }
            case .failure(let encodingError):
                onFailure(encodingError as! String)
            }
        }
    }
    
    func readPredictions(predictions : [JSON]) -> String {
        var allCoinsProbability = 0
        var coinName = "unknown"
        var coinProbability = 0.00000001
        
        for dic in predictions {
            let tagId = dic["TagId"].string
            let tag = dic["Tag"].string
            let pb = dic["Probability"].doubleValue
            let percent = pb * 100
            if tag == "All Coins" {
                if Int(percent) < Constants.MinimumProbability {
                    return "We didn't recognize any coins in this photo"
                } else {
                    allCoinsProbability = Int(percent)
                    continue
                }
            }
            
            if (pb > coinProbability) {
                coinProbability = pb
                coinName = _coinLookup[tagId!]!
            }
        }
        
        return "We are \(allCoinsProbability) certain that the photo contains a \(coinName)."
    }
    
    private func resizeImage(image : UIImage, size : CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        image.draw(in: rect)
        let destImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return destImage!
    }
}
