//
//  CameraViewController.swift
//  Test_Vision_API
//
//  Created by Edwin on 11/2/2024.
//

import AVFoundation
import UIKit
import Vision

enum errors: Error{
    case CameraError
}

final class CameraViewController : UIViewController{
    
    private var cameraFeedSession: AVCaptureSession?
    var fingerPositions: [CGPoint] = []
    
    override func loadView() {
        view = CameraPreview()
    }
    
    private var cameraView: CameraPreview{ view as! CameraPreview}
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do{
            
            if cameraFeedSession == nil{
                try setupAVSession()
                
                cameraView.previewLayer.session = cameraFeedSession
                //MARK: Commented out cause it cropped out our View Finder
             //   cameraView.previewLayer.videoGravity = .resizeAspectFill
            }
            
            //MARK: Surronded the code into a DispatchQueue cause it may cause a crash
            DispatchQueue.global(qos: .userInteractive).async {
                self.cameraFeedSession?.startRunning()
               }
            
        }catch{
            print(error.localizedDescription)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        cameraFeedSession?.stopRunning()
        super.viewDidDisappear(animated)
    }
    
    private let videoDataOutputQueue =
        DispatchQueue(label: "CameraFeedOutput", qos: .userInteractive)
    
    
    func setupAVSession() throws {
        //Start of Camera setup
        guard let videoDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) else {
            throw errors.CameraError
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else{
            throw errors.CameraError
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        //You can change the quality of the media from view finder from this line
        session.sessionPreset = AVCaptureSession.Preset.medium
        
        guard session.canAddInput(deviceInput) else{
            throw errors.CameraError
        }
        
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput){
            session.addOutput(dataOutput)
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        }else{
            throw errors.CameraError
        }
        
        session.commitConfiguration()
        cameraFeedSession = session
    }
    
    
    //MARK: Vision Init Below
    
    private let handPoseRequest : VNDetectHumanHandPoseRequest = {
            let request = VNDetectHumanHandPoseRequest()
             // Here is where we limit the number of hands Vision can detect at a single given moment
            request.maximumHandCount = 1
            return request
        }()
        
     
        var pointsProcessorHandler: (([CGPoint]) -> Void)?

        func processPoints(_ fingerTips: [CGPoint]) {
          
          let convertedPoints = fingerTips.map {
            cameraView.previewLayer.layerPointConverted(fromCaptureDevicePoint: $0)
          }

          pointsProcessorHandler?(convertedPoints)
        }
    }

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
     //Handler and Observation
     
     func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
         
         var fingerTips: [CGPoint] = []
         defer {
           DispatchQueue.main.sync {
             self.processPoints(fingerTips)
           }
         }

         
         let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer,   orientation: .up,   options: [:])
         
         do{
             try handler.perform([handPoseRequest])
             
             guard let results = handPoseRequest.results?.prefix(2),     !results.isEmpty  else{
                 return
             }
             
             var recognizedPoints: [VNRecognizedPoint] = []
             
             try results.forEach { observation in
                 
                 let fingers = try observation.recognizedPoints(.all)
                 
                 
                 if fingers[.thumbTip]?.confidence ?? 0.0 > 0.7{
                     recognizedPoints.append(fingers[.thumbTip]!)
                 }
                 
                 
                 if fingers[.indexTip]?.confidence ?? 0.0 > 0.7  {
                         recognizedPoints.append(fingers[.indexTip]!)
                     }
                 
                 
                 if fingers[.middleTip]?.confidence ?? 0.0 > 0.7 {
                     recognizedPoints.append(fingers[.middleTip]!)
                 }
                 
                 
                 if fingers[.ringTip]?.confidence ?? 0.0 > 0.7 {
                     recognizedPoints.append(fingers[.ringTip]!)
                 }
                 
                 if fingers[.littleTip]?.confidence ?? 0.0 > 0.7 {
                     recognizedPoints.append(fingers[.littleTip]!)
                 }
                 
             }
             
             fingerTips = recognizedPoints.filter {
               $0.confidence > 0.9
             }
             .map {
               CGPoint(x: $0.location.x, y: 1 - $0.location.y)
             }
             
             
         }catch{
             cameraFeedSession?.stopRunning()
         }
         
     }
     
 }
