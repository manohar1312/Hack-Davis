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
    
    @IBOutlet weak var tempImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSession()
        // Do any additional setup after loading the view, typically from a nib.
    }

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let imagevc:CameraViewController = segue.destination as! CameraViewController
//        imagevc.sourceType = .camera
//        imagevc.allowsEditing = true
//        imagevc.delegate = self
//        imagevc.cameraCaptureMode = UIImagePickerController.CameraCaptureMode.photo;
//        imagevc.cameraDevice = UIImagePickerController.CameraDevice.rear;
//    }
    
    @IBAction func cameraButtonPressed(_ sender:UIButton) {
        
//        imagevc.sourceType = .camera
//        imagevc.allowsEditing = true
//        imagevc.delegate = self
//        imagevc.cameraCaptureMode = UIImagePickerController.CameraCaptureMode.photo;
//        imagevc.cameraDevice = UIImagePickerController.CameraDevice.rear;
//        present(imagevc, animated: true) {
//            print("camera view presented")
//        }
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

//        camera.capturePhoto(with: settings, delegate: self)
        
        guard session.canAddInput(input)
            && session.canAddOutput(output) else { return }
        
        session.addInput(input)
        session.addOutput(output)
        
//        previewLayer = AVCaptureVideoPreviewLayer(session: session)
//
//        previewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
//        previewLayer!.connection?.videoOrientation = .Portrait
//
//        view.layer.addSublayer(previewLayer!)
        
        session.startRunning()
    }
    
    func capturePhoto() {
        guard let connection = output.connection(with: AVMediaType.video) else { return }
        
        let settings = AVCapturePhotoSettings()
        settings.livePhotoVideoCodecType = .jpeg
        
        connection.videoOrientation = AVCaptureVideoOrientation.portrait
        
        output.capturePhoto(with: settings, delegate: self)
        
//        output.captureStillImageAsynchronouslyFromConnection(connection) { (sampleBuffer, error) in
//            guard sampleBuffer != nil && error == nil else { return }
//
//            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
//            guard let image = UIImage(data: imageData) else { return }
//
//            //do stuff with image
//
//        }
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

        
        let lastPhoto = UIImage(cgImage: cgImage, scale: 1.0, orientation: UIImage.Orientation.up)
        
        print(lastPhoto)
        print("UIImage generated. ")
        
        tempImageView.image = lastPhoto

    }
    
//    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
//        <#code#>
//    }
//
//    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
//        if let error = error {
//            print(error.localizedDescription)
//        }
//
//        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage =
//            photoSampleBuffer.
//            AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer)
//        {
//            print(UIImage(data: dataImage)!.size) // Your Image
//        }
//
//    }

//    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
//        <#code#>
//    }
//
//    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: AVCapturePhoto, error: Error?) {
//        if let error = error {
//            print(error.localizedDescription)
//        }
////
//        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
//            print(image: UIImage(data: dataImage).size) // Your Image
//        }
//    }
}

