//
//  SMAWSManager.swift
//  selfieroulette
//
//  Created by Steven McMurray on 12/17/15.
//  Copyright © 2015 Steven McMurray. All rights reserved.
//
//SMAWS is a lightweight wrapper for the AWS SDK. Currently it allows simple connection to AWS S3 bucket and allows you to dump images into S3 asynchronously.

import Foundation

/**
 Blueprint of SMAWSConnector. SMAWSConnector is not a class. To implement custom functionality of SMAWSConnector, simply conform to this protocol and define your own implementation of the function connectToAWS().
*/
protocol SMAWSConnnectorProtocol {
    var regionType: AWSRegionType { get }
    var identityPoolID: String { get }
}

/**
 Defines connectToAWS configuration. If you wish to customize the implementation, simply define your own function with the same name and signature and the functionality of your custom implementation will be called.
*/
extension SMAWSConnnectorProtocol {
    func connectToAWS() {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: self.regionType, identityPoolId: self.identityPoolID)
        let configuration = AWSServiceConfiguration(region: AWSRegionType.USEast1, credentialsProvider: credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
    }
}

/**
 Main object for connecting to AWS. Simply create an instance of SMAWSConnector in an area such as your appDelegate in didFinishLaunchingWithOptions and call connectToAWS().
*/
struct SMAWSConnector: SMAWSConnnectorProtocol {
    var regionType: AWSRegionType
    var identityPoolID: String
    
    init(regionType: AWSRegionType, identityPoolID: String) {
        self.regionType = regionType
        self.identityPoolID = identityPoolID
    }
}

/**
 Upload Progress Tracker Delegate. Each time an instance of SMAWSImageUploader receives a change in the progress uploaded, the progressUpdated function will be called. Conform to this delegate to receive updates on upload progress and then implement UI Progress View if desired.
*/
protocol SMAWSImageUploadProgressTrackerDelegate {
    func progressUpdated(currentProgress: Float)
}

/**
 Main Protocol for uploading images. To implement custom functionality, simply create a class or struct that conforms to this protocol and implement any function. By default all classes or structs that conform to this protocol get access to the uploadImageToS3() function to upload images.
*/
protocol SMAWSImageUploaderProtocol {
    var bucketName: String { get }
    var urlPathIdentifier: String { get }
    var uploadProgressTrackerDelegate: SMAWSImageUploadProgressTrackerDelegate? { get }
}

extension SMAWSImageUploaderProtocol {
/**
Uploads images to S3 and returns a url for the image upon completion. After the image is uploaded to S3, you can use the completion block to save the URL to a database.
     - Parameters:
        - imageToUpload: The image you wish to send to S3
        - Completion block with signature: successURL?, error? will return either a url or error
*/
    func uploadImageToS3(imageToUpload: UIImage, SMAWSCompletionBlock: (successURL: String?, error: NSError?) -> Void) {
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("image.jpeg")
        let imageData = UIImageJPEGRepresentation(imageToUpload, 1.0)
        imageData!.writeToURL(path, atomically: true)
        
        uploadRequest.ACL = AWSS3ObjectCannedACL.PublicRead
        uploadRequest.bucket = self.bucketName
        uploadRequest.key = self.urlPathIdentifier
        uploadRequest.contentType = "image.jpeg"
        uploadRequest.body = path
        
        if self.uploadProgressTrackerDelegate != nil {
            var uploadProgressPercentage: Float = 0
            uploadRequest.uploadProgress =  { (bytesSent, totalBytesSent, totalBytesExpectedToSend) -> Void in
                if totalBytesExpectedToSend > 0 {
                    uploadProgressPercentage = Float(Double(totalBytesSent) / Double(totalBytesExpectedToSend))
                    self.uploadProgressTrackerDelegate?.progressUpdated(uploadProgressPercentage)
                }
            }
        }
        
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        transferManager.upload(uploadRequest).continueWithBlock { (task) -> AnyObject? in
            if task.error != nil {
                SMAWSCompletionBlock(successURL: nil, error: task.error)
            } else {
                SMAWSCompletionBlock(successURL: "https://\(self.bucketName).s3.amazonaws.com/\(self.urlPathIdentifier)", error: nil)
            }
            return nil
        }
    }
    
    func uploadAudioToS3(audioDataToUpload: NSData, SMAWSCompletionBlock: (successURL: String?, error: NSError?) -> Void) {
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("audio.m4a")
        audioDataToUpload.writeToURL(path, atomically: true)
        
        uploadRequest.ACL = AWSS3ObjectCannedACL.PublicRead
        uploadRequest.bucket = self.bucketName
        uploadRequest.key = self.urlPathIdentifier
        uploadRequest.contentType = "audio.m4a"
        uploadRequest.body = path
        
        if self.uploadProgressTrackerDelegate != nil {
            var uploadProgressPercentage: Float = 0
            uploadRequest.uploadProgress =  { (bytesSent, totalBytesSent, totalBytesExpectedToSend) -> Void in
                if totalBytesExpectedToSend > 0 {
                    uploadProgressPercentage = Float(Double(totalBytesSent) / Double(totalBytesExpectedToSend))
                    self.uploadProgressTrackerDelegate?.progressUpdated(uploadProgressPercentage)
                }
            }
        }
        
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        transferManager.upload(uploadRequest).continueWithBlock { (task) -> AnyObject? in
            if task.error != nil {
                SMAWSCompletionBlock(successURL: nil, error: task.error)
            } else {
                SMAWSCompletionBlock(successURL: "https://\(self.bucketName).s3.amazonaws.com/\(self.urlPathIdentifier)", error: nil)
            }
            return nil
        }
    }
}

/**
 Class that manages sending images to S3 given a specified bucket and path identifier. Create the path identifier to prevent URL clashing in your bucket. A good example would be something like userID_timestamp. Call function uploadToS3 to upload an image. 
 
Do not subclass SMAWSImageUploader. To configure your own class simply write a struct or class that conforms to the SMAWSImageUploaderProtocol and implement your own functionality of the function: uploadToS3().
*/
final class SMAWSImageUploader: SMAWSImageUploaderProtocol {

    var bucketName: String
    var urlPathIdentifier: String
    var uploadProgressTrackerDelegate: SMAWSImageUploadProgressTrackerDelegate?
    
    init(bucketName: String, urlPathIdentifier: String, uploadProgressTracker: SMAWSImageUploadProgressTrackerDelegate?) {
        self.bucketName = bucketName
        self.urlPathIdentifier = urlPathIdentifier
        self.uploadProgressTrackerDelegate = uploadProgressTracker
    }
}

/**
 Blueprint for the SMAWSImageResizer. Do not subclass SMAWSImageResizer. To customize functionality of the image resizer method, conform to this protocol and implement your own functionality of the resizeImage() function.
*/
protocol SMAWSImageResizerProtocol {
    var maximumHeight: Float { get set }
    var maximumWidth: Float { get set }
    var imageToResize: UIImage { get set }
}

extension SMAWSImageResizerProtocol {
/**
Resizes the image to be sent to the backend of whatever class or struct conforms to this protocol. Returns an image that is resized to the width and height defined in the protocol.
*/
    func resizeImage() -> UIImage {
        var actualHeight: Float = Float(imageToResize.size.height)
        var actualWidth: Float = Float(imageToResize.size.width)
        let maxHeight: Float = self.maximumHeight
        let maxWidth: Float = self.maximumWidth
        var imageRatio = actualWidth / actualHeight
        let maxRatio = maxWidth / maxHeight
        let compressionQuality = CGFloat(1.0)
        
        if (actualHeight > maxHeight || actualWidth > maxWidth) {
            if(imageRatio < maxRatio) {
                imageRatio = maxHeight / actualHeight
                actualWidth = imageRatio * actualWidth
                actualHeight = maxHeight
            } else if(imageRatio > maxRatio) {
                imageRatio = maxWidth / actualWidth
                actualHeight = imageRatio / actualHeight
                actualWidth = maxWidth
            } else {
                actualHeight = maxHeight
                actualWidth = maxWidth
            }
        }
        let rect = CGRectMake(0.0, 0.0, CGFloat(actualWidth), CGFloat(actualHeight))
        UIGraphicsBeginImageContext(rect.size)
        self.imageToResize.drawInRect(rect)
        let tmpImage = UIGraphicsGetImageFromCurrentImageContext()
        let data: NSData = UIImageJPEGRepresentation(tmpImage, compressionQuality)!
        UIGraphicsEndImageContext()
        return UIImage(data: data)!
    }
}

/**
 Class that manages image resizing. Simply create an instance of SMAWSImageResizer and call resizeImage() to reduce the image size to be sent to the S3 bucket. Default maximum height is 600, maximum width is 800. Not meant to be subclassed.
*/
final class SMAWSImageResizer : SMAWSImageResizerProtocol {
    var imageToResize: UIImage
    var maximumHeight: Float = 600.0
    var maximumWidth: Float = 800.0
    
    init(imageToResize: UIImage) {
        self.imageToResize = imageToResize
    }
}


