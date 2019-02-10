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

enum VoiceType: String {
    case undefined
    case waveNetFemale = "en-US-Wavenet-F"
    case waveNetMale = "en-US-Wavenet-D"
    case standardFemale = "en-US-Standard-E"
    case standardMale = "en-US-Standard-D"
}

let ttsAPIUrl = "https://texttospeech.googleapis.com/v1beta1/text:synthesize"
let APIKey = "AIzaSyBxCloQoXVBivA2yZKI8CuY8iNP-734Pz4"

class SpeechService: NSObject, AVAudioPlayerDelegate {
    
    static let shared = SpeechService()
    private(set) var busy: Bool = false
    
    private var player: AVAudioPlayer?
    private var completionHandler: (() -> Void)?
    
    func speak(text: String, voiceType: VoiceType = .waveNetFemale, completion: @escaping () -> Void) {
        guard !self.busy else {
            print("Speech Service busy!")
            return
        }
        
        self.busy = true
        
        DispatchQueue.global(qos: .background).async {
            let postData = self.buildPostData(text: text, voiceType: voiceType)
            let headers = ["X-Goog-Api-Key": APIKey, "Content-Type": "application/json; charset=utf-8"]
            let response = self.makePOSTRequest(url: ttsAPIUrl, postData: postData, headers: headers)
            
            // Get the `audioContent` (as a base64 encoded string) from the response.
            guard let audioContent = response["audioContent"] as? String else {
                print("Invalid response: \(response)")
                self.busy = false
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            
            // Decode the base64 string into a Data object
            guard let audioData = Data(base64Encoded: audioContent) else {
                self.busy = false
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            
            DispatchQueue.main.async {
                self.completionHandler = completion
                self.player = try! AVAudioPlayer(data: audioData)
                self.player?.delegate = self
                self.player!.play()
            }
        }
    }
    
    private func buildPostData(text: String, voiceType: VoiceType) -> Data {
        
        var voiceParams: [String: Any] = [
            // All available voices here: https://cloud.google.com/text-to-speech/docs/voices
            "languageCode": "en-US"
        ]
        
        if voiceType != .undefined {
            voiceParams["name"] = voiceType.rawValue
        }
        
        let params: [String: Any] = [
            "input": [
                "text": text
            ],
            "voice": voiceParams,
            "audioConfig": [
                // All available formats here: https://cloud.google.com/text-to-speech/docs/reference/rest/v1beta1/text/synthesize#audioencoding
                "audioEncoding": "LINEAR16"
            ]
        ]
        
        // Convert the Dictionary to Data
        let data = try! JSONSerialization.data(withJSONObject: params)
        return data
    }
    
    // Just a function that makes a POST request.
    private func makePOSTRequest(url: String, postData: Data, headers: [String: String] = [:]) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [:]
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.httpBody = postData
        
        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        // Using semaphore to make request synchronous
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] {
                dict = json!
            }
            
            semaphore.signal()
        }
        
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        return dict
    }
    
    // Implement AVAudioPlayerDelegate "did finish" callback to cleanup and notify listener of completion.
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player?.delegate = nil
        self.player = nil
        self.busy = false
        
        self.completionHandler!()
        self.completionHandler = nil
    }
}

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
            captureTimer = Timer.scheduledTimer(timeInterval: 7.0, target: self, selector: #selector(capturePhoto), userInfo: nil, repeats: true)
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
                    let description:String = "\(swiftyJsonVar["description"]["captions"][0]["text"])"
                    print(description)
                    SpeechService.shared.speak(text: description) {}
                }
                
            case .failure(let encodingError):
                print(encodingError)
            }
            
        }
        //API call ends

    }

}

