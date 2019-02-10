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

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {

    var imagevc:UIImagePickerController = UIImagePickerController()
    var session:AVCaptureSession = AVCaptureSession()
    var output:AVCapturePhotoOutput = AVCapturePhotoOutput()
    
    
    @IBOutlet weak var previewImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSession()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func captureButtonPressed(_ sender: UIButton) {
        capturePhoto()
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
    
    func capturePhoto() {
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

        
        let lastPhoto = UIImage(cgImage: cgImage, scale: 1.0, orientation: UIImage.Orientation.right)
        
        print(lastPhoto)
        print("UIImage generated. ")
        
        previewImageView.image = lastPhoto

    }
    
}

