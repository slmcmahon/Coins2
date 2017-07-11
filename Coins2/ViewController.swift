//
//  ViewController.swift
//  Coins2
//
//  Created by Stephen McMahon on 6/20/17.
//  Copyright © 2017 Stephen McMahon. All rights reserved.
//

import UIKit
import MBProgressHUD

class ViewController: UIViewController,
                      UIImagePickerControllerDelegate,
                      UINavigationControllerDelegate {

    var _hud : MBProgressHUD? = nil
    let _viewModel = CoinViewModel()
    
    @IBOutlet var photoDisplay: UIImageView!
    @IBOutlet var takePhotoButton: UIButton!
    @IBOutlet var selectPhotoButton: UIButton!
    @IBOutlet var analyzePhotoButton: UIButton!
    
    override func viewDidAppear(_ animated: Bool) {
        
        if (!UIImagePickerController .isSourceTypeAvailable(.camera)) {
            showMessage(message: "This app will crash if you try to access the camera in a simulator!", title: "Warning")
        }
        
        super.viewDidAppear(animated)
    }

    @IBAction func takePhotoTouched(_ sender: Any) {
        let picker = getImagePicker(camera: true)
        present(picker, animated: true, completion: nil)
    }

    @IBAction func selectPhotoTouched(_ sender: Any) {
        let picker = getImagePicker(camera: false)
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func analyzePhotoTouched(_ sender: Any) {
        if self.photoDisplay.image == nil {
            showMessage(message: "Please take or select a photo to analyze.", title: "Note")
            return
        }
        showHUD()
        _viewModel.recognizeImage(onSuccess: { (successMessage) in
            self.hideHUD()
            self.showMessage(message: successMessage, title: "Analysis Complete")
        }, onFailure: { (failureMessage) in
            self.hideHUD()
            self.showMessage(message: failureMessage, title: "Error")
        }, image: self.photoDisplay.image!)
    }
    
    func getImagePicker(camera : Bool) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = camera ? .camera : .photoLibrary
        return picker
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let chosenImage = info[UIImagePickerControllerEditedImage]
        self.photoDisplay.image = (chosenImage as! UIImage)
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func showHUD() {
        self.analyzePhotoButton.isEnabled = false
        _hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        _hud?.mode = .indeterminate
        _hud?.label.text = "Analyzing Photo..."
    }
    
    func hideHUD() {
        self.analyzePhotoButton.isEnabled = true;
        _hud?.hide(animated: true)
    }
    
    func showMessage(message : String, title: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle:.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

