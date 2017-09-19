//
//  CameraLayerViewController.swift
//  MainStand
//
//  Created by Tendai Prince Dzonga on 10/14/16.
//  Copyright © 2016 Tendai Prince Dzonga. All rights reserved.
//

import UIKit
import AVFoundation

class CameraLayerViewController: UIViewController {
    
    
    //MARK::  Device Management
    
    var authStatusVideo: SessionSetupResult = .success {
        didSet {
           
        }
    }
    
    var authStatusAudio: SessionSetupResult = .success {
        didSet {
           
        }
    }
    
    let deviceDiscoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDuoCamera, .builtInMicrophone, .builtInTelephotoCamera], mediaType: nil, position: .unspecified)
    
    @IBAction func enableCamera(_ sender: AnyObject) {
        
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: {  granted in
            
            if !granted {
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
            }
            
            self.authStatusVideo = .success
            DispatchQueue.main.async {
                self.enableCameraBtn.isHidden = true
                self.viewDidAppear(true)
                
            }
        })
        
    }
    
    @IBAction func enableMic(_ sender: AnyObject) {
        
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeAudio, completionHandler: { [unowned self] granted in
            
            if !granted {
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
            }
            
            self.authStatusAudio = .success
            DispatchQueue.main.async {
                self.enableMicBtn.isHidden = true
            }
        })
        
        
    }
    
    

    //MARK:: CaptureSession Management
    
    enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    var session = AVCaptureSession()
    
    let sessionQueue = DispatchQueue(label: "session Queue")
    
    var deviceInput: AVCaptureDeviceInput!
    
    //On sessionQueue as session.start running is blocking
    private func configureSession() {
        
        if authStatusAudio == .notAuthorized && authStatusVideo == .notAuthorized {
            return
        }
        else  {
            DispatchQueue.main.async {
                self.infoLabel.isHidden = true
                self.enableCameraBtn.isHidden = true
                self.enableMicBtn.isHidden = true
            }
        }
        
        session.beginConfiguration()
        
        if session.canSetSessionPreset(AVCaptureSessionPresetPhoto) {
            session.sessionPreset = AVCaptureSessionPresetPhoto
        }
        else {
            return
        }
        
        //Add video input
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            if let dualCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInDuoCamera, mediaType: AVMediaTypeVideo, position: .back) {
                
                defaultVideoDevice = dualCameraDevice
            }
                
            else if let backCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back){
                
                defaultVideoDevice = backCameraDevice
            }
            
            else if let frontCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) {
                
                defaultVideoDevice = frontCameraDevice
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.deviceInput = videoDeviceInput
                
                //Manipulation on main thread
                DispatchQueue.main.async {
                    let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
                    let cameraView : UIView = self.preview
                    captureVideoPreviewLayer!.frame = cameraView.bounds
                    captureVideoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                    cameraView.layer.addSublayer(captureVideoPreviewLayer!)
                    self.session.startRunning()
                }
            }
            
        }catch {
            print("Could not create a video device input: \(error)")
            session.commitConfiguration()
            return
        }
        
        //Add Audio Input
        
        do {
            let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            }
            else {
                print("Could not add audio device input to the session")
            }
            
        }catch {
            
            print("Could not create audio device input: \(error)")
            
        }
        
        //Add photo output
        
        
        
        session.commitConfiguration()
    }
    
    @IBAction func changeCamera(_ sender: Any) {
        
        sessionQueue.async { [unowned self] in
            
            let currentVideoDevice = self.deviceInput.device
            let currentPosition = currentVideoDevice!.position
            
            let preferredPosition: AVCaptureDevicePosition
            let preferredDeviceType: AVCaptureDeviceType
            
            switch currentPosition {
                case .unspecified, .front:
                    preferredPosition = .back
                    preferredDeviceType = .builtInDuoCamera
                
                case .back:
                    preferredPosition = .front
                    preferredDeviceType = .builtInWideAngleCamera
                
            }
            
            let devices = self.deviceDiscoverySession?.devices!
            
            var newVideoDevice: AVCaptureDevice? = nil
            
            //First, look for a device with both a preferred position and device type. Otherwise, look for a device with only the preferred position
            
            if let device = devices?.filter({ $0.position == preferredPosition && $0.deviceType == preferredDeviceType }).first {
                
                newVideoDevice = device
            }
            else if let device = devices?.filter({ $0.position == preferredPosition }).first {
                
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.session.beginConfiguration()
                    
                    //Remove the existing device input, since simultaneous use of front and back cameras is not supported 
                    self.session.removeInput(self.deviceInput)
                    
                    //Add and remove observers
                    
                    if self.session.canAddInput(videoDeviceInput){
                        self.session.addInput(videoDeviceInput)
                        self.deviceInput = videoDeviceInput
                    }
                    else{
                        self.session.addInput(self.deviceInput)
                    }
                    
                    self.session.commitConfiguration()
                    
                }catch {
                    
                    print("Error occured while creating video device input: \(error)")
                }
            }
            
        }
    }
    
    
    
    
    //MARK:: Capturing Photos
    
    let photoOutput = AVCapturePhotoOutput()
    
    //MARK::  ViewController Management
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var enableCameraBtn: UIButton!
    @IBOutlet weak var enableMicBtn: UIButton!
    @IBOutlet weak var cameraBtn: UIButton!
    @IBOutlet weak var switchCamerasBtn: UIButton!
    @IBOutlet weak var flashBtn: UIButton!
    @IBOutlet weak var preview : UIView!
    @IBOutlet weak var videoButton: UIView!
    
    
    
    
    override var prefersStatusBarHidden: Bool {
        
        return true
    }
    
    
    @IBAction func longPressVideo(_ sender: UILongPressGestureRecognizer) {
        
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.5, animations: {
            
                self.videoButton.alpha = 1.0
                self.cameraBtn.alpha = 0.0
            
            
            })
        
            let square = self.generateSquareLayer(view: self.videoButton)
            self.videoButton.layer.addSublayer(square)
        
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoButton.alpha = 0.0
        videoButton.backgroundColor = UIColor.clear
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //videoButton.alpha = 0.0
        //videoButton.backgroundColor = UIColor.clear
        configureSession()
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    //MARK: - Animations 
    
    func generateSquareLayer(view: UIView) -> CAShapeLayer {
        let square = CAShapeLayer()
        square.bounds = view.bounds
        square.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        let allCorners = UIRectCorner.allCorners
        let cornerRadius = CGSize(width: 8, height: 8)
        let squareRect = CGRect(x: 0, y: 0, width: view.bounds.width , height: view.bounds.height )
        square.path = UIBezierPath(roundedRect: squareRect, byRoundingCorners: allCorners, cornerRadii: cornerRadius).cgPath
        square.strokeColor = UIColor.red.cgColor
        square.fillColor = UIColor.clear.cgColor
        square.strokeStart = 0.0 //0.0, 0.125
        square.strokeEnd = 0.0   //1.0
        
        let start = CABasicAnimation(keyPath: "strokeStart")
        start.toValue = 0.0  //1.0
        let end = CABasicAnimation(keyPath: "strokeEnd")
        end.toValue = 1.0   //1.0
        
        let group = CAAnimationGroup()
        group.animations = [end,]
        group.duration = 15
        group.autoreverses = true
        group.repeatCount = HUGE
        square.add(group, forKey: nil)
        
        return square
    }
    

}


