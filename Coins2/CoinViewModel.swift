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
            let tag = dic["Tag"].string!
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
                // all of the tags are pluralized, but we want to refer to the singular form in the response.
                coinName = tag == "Pennies" ? "Penny" : tag.substring(to: tag.index(before: tag.endIndex))
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
