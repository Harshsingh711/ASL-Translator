//
//  ViewController.swift
//  ASL Translator
//
//  Created by Harsh on 1/10/22.
//

import UIKit
import AVKit
import AVFoundation
import Vision
import CoreML

let SERVER_URL = "https://asltranslator.herokuapp.com/asl"
//"http://192.168.1." + "185" + ":3000/asl"
class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var connImage: UIImageView!
    @IBOutlet weak var confLabel: UILabel!
    
    var videoWriterInput: AVAssetWriterInput!
    var assetWriter: AVAssetWriter!
    override open var shouldAutorotate: Bool {
        return false
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .low
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {return}
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        captureSession.beginConfiguration()
        captureSession.addInput(input)
        captureSession.commitConfiguration()
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.beginConfiguration()
        captureSession.addOutput(dataOutput)
        captureSession.commitConfiguration()
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        print("Start Session")
        captureSession.startRunning()
    }
    
    var previousLetter : String = ""
    var repeatedTimes : Int32 = 0
    var spoken : Bool = false
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Capture Frame", Date())
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        func resizeImage(image: UIImage, newWidth: CGFloat, newHeight: CGFloat) -> UIImage {
            UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
            image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage ?? UIImage()
        }
        let image = resizeImage(image: UIImage(ciImage: ciImage), newWidth: 50, newHeight: 50)
        let imageData = image.pngData()
        let base64Image = imageData?.base64EncodedString(options: .lineLength64Characters)
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: SERVER_URL)!)
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        var body = ""
        body += "--\(boundary)\r\n"
        body += "Content-Disposition:form-data; name=\"media\""
        body += "\r\n\r\n\(base64Image ?? "")\r\n"
        body += "--\(boundary)--\r\n"
        let postData = body.data(using: .utf8)
        request.httpBody = postData
        let sem = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            print("Response Arrived")
            sem.signal()
            if let error = error {
                DispatchQueue.main.async {
                    self.label.text = ""
                    self.connImage.tintColor = .blue
                    self.confLabel.text = "Connecting to Server..."
                }
                print("Error: \(error)")
                return
            }
            DispatchQueue.main.async {
                self.connImage.tintColor = .green
            }
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print(dataString)
                if let jsonRes = dataString.data(using: String.Encoding.utf8) {
                    do {
                        let res = try JSONSerialization.jsonObject(with: jsonRes, options: []) as! [String: Any]
                        print(res)
                        DispatchQueue.main.async {
                            let prediction = res["prediction"] as! String
                            let confidence = res["confidence"] as! String
                            self.label.text = prediction
                            self.confLabel.text = "Confidence: " + confidence + "%"
                            
                            if (self.previousLetter == prediction) {
                                self.repeatedTimes += 1
                            } else {
                                self.previousLetter = prediction
                                self.repeatedTimes = 0
                                self.spoken = false
                            }
                            
                            let lowercase = Character(prediction).lowercased()
                            
                            // utter the text
                            //let utterance = AVSpeechUtterance(string:"Hi")
                            if (Double(confidence)! > 50 && self.repeatedTimes >= 3 && !self.spoken) {
                                let utterance = AVSpeechUtterance(string: lowercase)
                                //let utterance = AVSpeechUtterance(string: "Hi")
                                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                                utterance.rate = 0.5
                                let synthesizer = AVSpeechSynthesizer()
                                self.spoken = true
                                synthesizer.speak(utterance)
                            }
                            // if repeated more than 5 (frame) times => speak
                            // if same character as previous, wait till new character
                            // GGGGWWWGGGGG*GGGGGGDDDDD*
                            // GD
                        }
                    } catch {
                        print(error)
                    }
                }
            }
        }
        task.resume()
        print("Request Sent")
        sem.wait()
        
        /*
        On Device Recognition:
         
        DispatchQueue.main.async {
            UIImageWriteToSavedPhotosAlbum(UIImage(ciImage: ciImage), self, #selector(self.complete), nil)
        }
        let srcWidth = CGFloat(ciImage.extent.width)
        let srcHeight = CGFloat(ciImage.extent.height)
        let dstWidth: CGFloat = 50
        let dstHeight: CGFloat = 50
        let resizedCIImage = ciImage.transformed(by: CGAffineTransform(scaleX: dstWidth / srcWidth, y: dstHeight / srcHeight))
        print(UIImage(ciImage: resizedCIImage).size)
        guard let modelURL = Bundle.main.url(forResource: "custom_mod", withExtension: "mlmodelc") else {return}
        guard let model = try? VNCoreMLModel(for: MLModel(contentsOf: modelURL)) else {return}
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            func convToArr(from mlarr: MLMultiArray) -> [Double] {
                var arr: [Double] = []
                for i in 0...mlarr.count - 1 {
                    arr.append(Double(truncating: mlarr[[0, NSNumber(value: i)]]))
                }
                return arr
            }
            if let results = finishedReq.results {
                guard let observation = results[0] as? VNCoreMLFeatureValueObservation else {
                    return
                }
                let labels : Dictionary = [0: "A", 1: "B", 2: "C", 3: "D", 4: "E", 5: "F", 6: "G", 7: "H", 8: "I", 9: "J", 10: "K", 11: "L", 12: "M", 13: "N", 14: "O", 15: "P", 16: "Q", 17: "R", 18: "S", 19: "T", 20: "U", 21: "V", 22: "W", 23: "X", 24: "Y", 25: "Z", 26: "del", 27: "nothing", 28: "space", 29: "other"]
                print(observation.featureValue)
                let predarr = convToArr(from: observation.featureValue.multiArrayValue ?? MLMultiArray())
                guard let maxValue = predarr.max() else {return}
                guard let index = predarr.firstIndex(of: maxValue) else {return}
                print(index)
                print(labels[index] ?? "Could Not Find")
            }
        }
        try? VNImageRequestHandler(ciImage: resizedCIImage, options: [:]).perform([request])
        */
    }

}

