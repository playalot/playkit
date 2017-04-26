//
//  CameraView.swift
//  imagepicker
//
//  Created by Tbxark on 28/12/2016.
//  Copyright © 2016 Tbxark. All rights reserved.
//

import UIKit
import AVFoundation


public typealias TKCameraShotCompletion = (UIImage) -> Void

class CameraView: UIView {
    
    var session: AVCaptureSession!
    var input: AVCaptureDeviceInput!
    var device: AVCaptureDevice!
    var imageOutput: AVCaptureStillImageOutput!
    var preview: AVCaptureVideoPreviewLayer!
    
    let cameraQueue = DispatchQueue.main
    
    var currentPosition = AVCaptureDevicePosition.back
    
    func startSession() {
        cameraQueue.async {
            self.createSession()
            self.session?.startRunning()
        }
    }
    
    func pauseSession() {
        cameraQueue.async {
            self.session?.stopRunning()
        }
    }
    
    func stopSession() {
        cameraQueue.async {
            self.session?.stopRunning()
            self.preview?.removeFromSuperlayer()
            
            self.session = nil
            self.input = nil
            self.imageOutput = nil
            self.preview = nil
            self.device = nil
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let p = preview {
            p.frame = bounds
        }
    }
    
    fileprivate func createSession() {
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetHigh
        DispatchQueue.main.async {
            self.createPreview()
        }
    }
    
    fileprivate func createPreview() {
        device = cameraWithPosition(currentPosition)
        
        let outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch {
            input = nil
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        imageOutput = AVCaptureStillImageOutput()
        imageOutput.outputSettings = outputSettings
        
        session.addOutput(imageOutput)
        
        preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill
        preview.frame = bounds
        
        layer.addSublayer(preview)
    }
    
    fileprivate func cameraWithPosition(_ position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        var _device: AVCaptureDevice?
        for d in devices! {
            if (d as AnyObject).position == position {
                _device = d as? AVCaptureDevice
                break
            }
        }
        
        return _device
    }
    
    func capturePhoto(_ completion: @escaping TKCameraShotCompletion) {
        cameraQueue.async {
            let orientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue)!
            CameraView.takePhoto(self.imageOutput, videoOrientation: orientation, cropSize: self.frame.size) { image in
                self.session.stopRunning()
                completion(image)
            }
        }
    }
    
    func swapCameraInput() {
        if session != nil && input != nil {
            session.beginConfiguration()
            session.removeInput(input)
            
            if input.device.position == AVCaptureDevicePosition.back {
                currentPosition = AVCaptureDevicePosition.front
                device = cameraWithPosition(currentPosition)
            } else {
                currentPosition = AVCaptureDevicePosition.back
                device = cameraWithPosition(currentPosition)
            }
            
            let error = NSErrorPointer(nilLiteral:())
            do {
                input = try AVCaptureDeviceInput(device: device)
            } catch let error1 as NSError {
                error?.pointee = error1
                input = nil
            }
            
            session.addInput(input)
            session.commitConfiguration()
        }
    }
    
    class func takePhoto(_ stillImageOutput: AVCaptureStillImageOutput, videoOrientation: AVCaptureVideoOrientation, cropSize: CGSize, completion: @escaping TKCameraShotCompletion) {
        var videoConnection: AVCaptureConnection? = nil
        
        for connection in stillImageOutput.connections {
            for port in (connection as! AVCaptureConnection).inputPorts {
                if (port as AnyObject).mediaType == AVMediaTypeVideo {
                    videoConnection = connection as? AVCaptureConnection
                    break
                }
            }
            
            if videoConnection != nil {
                break
            }
        }
        
        videoConnection?.videoOrientation = videoOrientation
        
        stillImageOutput.captureStillImageAsynchronously(from: videoConnection!, completionHandler: { buffer, error in
            if buffer != nil {
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                let image = UIImage(data: imageData!)!
                completion(image)
            }
        })
    }
    
    
    class func fixOrientation(source: UIImage) -> UIImage {
        guard let cgImage = source.cgImage else {
            return source
        }
        
        if source.imageOrientation == UIImageOrientation.up {
            return source
        }
        
        let width  = source.size.width
        let height = source.size.height
        
        var transform = CGAffineTransform.identity
        
        switch source.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: width, y: height)
            transform = transform.rotated(by: CGFloat.pi)
            
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.rotated(by: 0.5*CGFloat.pi)
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: height)
            transform = transform.rotated(by: -0.5*CGFloat.pi)
            
        case .up, .upMirrored:
            break
        }
        
        switch source.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        default:
            break;
        }
        
        guard let colorSpace = cgImage.colorSpace else {
            return source
        }
        
        guard let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: UInt32(cgImage.bitmapInfo.rawValue)
            ) else {
                return source
        }
        
        context.concatenate(transform);
        
        switch source.imageOrientation {
            
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: height, height: width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        guard let newCGImg = context.makeImage() else {
            return source
        }
        let img = UIImage(cgImage: newCGImg)
        return img
    }
    
    
    class func crop(image: UIImage, zoom: CGFloat,  cropRect: CGRect) -> UIImage {
       

        var rect = cropRect
        rect.origin.x *= image.scale * zoom
        rect.origin.y *= image.scale * zoom
        rect.size.width *= image.scale * zoom
        rect.size.height *= image.scale * zoom
        if rect.size.width <= 0 || rect.size.height <= 0 {
            return UIImage()
        }
        guard let cgImg = image.cgImage,
            let imageRef = cgImg.cropping(to: rect) else {
                return UIImage()
        }
        let image =  UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        let res = fixOrientation(source: image)

        return res
    }
    
}

