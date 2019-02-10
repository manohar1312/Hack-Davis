//
//  ViewController.swift
//  Hack-Davis
//
//  Created by Manohar Boppana on 2/9/19.
//  Copyright © 2019 Manohar Boppana. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {

    var imagevc:UIImagePickerController = UIImagePickerController()
    var session:AVCaptureSession = AVCaptureSession()
    var output:AVCapturePhotoOutput = AVCapturePhotoOutput()
    var captureTimer = Timer()
    
    
    
    @IBOutlet weak var previewImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //start the picture session
        setupSession()

    }
    
    @IBAction func captureButtonPressed(_ sender: UIButton) {
        if sender.tag == 0{
            sender.tag = 1
            capturePhoto()
            //time to take continuoous pictures
            captureTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(capturePhoto), userInfo: nil, repeats: true)
        }else if sender.tag == 1{
            captureTimer.invalidate()
            sender.tag = 0
        }
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("finish taking photo")
    }
    
    func setupSession() {
        session.sessionPreset = AVCaptureSession.Preset.photo
    
        let camera = AVCaptureDevice.default(for: AVMediaType.video)!
        var input:AVCaptureDeviceInput

        do {
            input = try AVCaptureDeviceInput(device: camera)
            
        } catch { return }
        
        guard session.canAddInput(input)
            && session.canAddOutput(output) else { return }
        
        session.addInput(input)
        session.addOutput(output)
        session.startRunning()
    }
    
    @objc func capturePhoto() {
        guard let connection = output.connection(with: AVMediaType.video) else { return }
        
        let settings = AVCapturePhotoSettings()
        settings.livePhotoVideoCodecType = .jpeg
        
        connection.videoOrientation = AVCaptureVideoOrientation.portrait
        
        output.capturePhoto(with: settings, delegate: self)
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("captured")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // capture image finished
        print("Image captured.")
        
        let photoMetadata = photo.metadata
        // Returns corresponting NSCFNumber. It seems to specify the origin of the image
        //                print("Metadata orientation: ",photoMetadata["Orientation"])
        
        // Returns corresponting NSCFNumber. It seems to specify the origin of the image
        print("Metadata orientation with key: ",photoMetadata[String(kCGImagePropertyOrientation)] as Any)
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("Error while generating image from photo capture data.");
            return
            
        }
        
        guard let uiImage = UIImage(data: imageData) else {
            print("Unable to generate UIImage from image data.");
            return
            
        }
        
        // generate a corresponding CGImage
        guard let cgImage = uiImage.cgImage else {
            print("Error generating CGImage");
            return
            
        }
        
        //variable to store the UIImage
        let lastPhoto = UIImage(cgImage: cgImage, scale: 1.0, orientation: UIImage.Orientation.right)
        
        
        //print(lastPhoto)
        print("UIImage generated. ")
        //add the image to the prieview view
        previewImageView.image = lastPhoto
        

        //API call begins
        let heads = ["Ocp-Apim-Subscription-Key": "d6483d377e8d4711afe655aa54311b9f"] //headers for api call
        let imgData = lastPhoto.jpegData(compressionQuality:0.8)! //compress the image
        
        
        Alamofire.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(imgData, withName: "fileset",fileName: "file.jpg", mimeType: "image/jpg")

        },
                         
        to:"https://westcentralus.api.cognitive.microsoft.com/vision/v2.0/analyze?visualFeatures=Description", method: .post, headers: heads)
        
        { (result) in
            switch result {
            case .success(let upload, _, _):
                
                upload.uploadProgress(closure: { (progress) in
                    //print("Upload Progress: \(progress.fractionCompleted)")
                })
                
                upload.responseJSON { response in
                    //print(response.result.value)
                    let swiftyJsonVar = JSON(response.result.value!)
                    print(swiftyJsonVar["description"]["captions"][0]["text"])
                }
                
            case .failure(let encodingError):
                print(encodingError)
            }
            
        }
        //API call ends

    }

}

