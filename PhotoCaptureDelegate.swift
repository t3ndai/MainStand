//
//  PhotoCaptureDelegate.swift
//  MainStand
//
//  Created by Tendai Prince Dzonga on 9/29/16.
//  Copyright © 2016 Tendai Prince Dzonga. All rights reserved.
//

import UIKit
import Photos

//MARK: Delegate Object

class PhotoCaptureDelegate: NSObject {
    
    var photoData: Data? = nil
    private(set) var photoSettings: AVCapturePhotoSettings
    
    init(photoData: Data, photoSettings: AVCapturePhotoSettings) {
        self.photoData = photoData
        self.photoSettings = photoSettings
    }
    
}

//MARK: AVCapturePhotoCaptureDelegate Implementation

extension PhotoCaptureDelegate: AVCapturePhotoCaptureDelegate {
    
    //Mark:: Monitoring Capture Progress
    
    func capture(_ captureOutput: AVCapturePhotoOutput, willBeginCaptureForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings) {
        
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, willCapturePhotoForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings) {
        
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didCapturePhotoForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings) {
        
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishCaptureForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        
    }
    
    //Mark:: Receiving Capture Results
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        
        if let photoSampleBuffer = photoSampleBuffer {
            
            photoData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
            
        }else{
            print(error?.localizedDescription)
        }
    }
    
}
