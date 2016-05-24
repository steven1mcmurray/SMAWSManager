# SMAWSManager

## SMAWSManager is a wrapper for the AWS SDK.

###### The goal of SMAWSManager is to extract the complex functionality of the existing AWS SDK for iOS and provide a wrapper to enable quick configuration of the most common tasks used.

By using the AWS SDK, you can send photos directly into a cloud storage bucket, instead of sending it to the server to facilitate the transfer into the bucket. This can drastically reduce server load, costs, efficiency etc.

To get started, first install the AWS SDK via cocoapods. Your podfile needs at least these pods:
```swift
platform :ios, '8.0'

pod 'AWSS3'
pod 'AWSCore'
pod 'AWSCognito'
```



First we simply connect to AWS in our AppDelegate didFinishLaunchingWithOptions function.

```swift
let connector = SMAWSConnector(regionType: <Your AWS Region Type>, identityPoolID: "<your identity pool>")
connector.connectToAWS()
```


By default photos are higher resolution than needed for most apps. SMAWSManager comes with a built in photo resizer. This is how you resize a UIImage:
```swift
let resizedImage = SMAWSImageResizer(imageToResize: UIImage).resizeImage()
```


Now we can simply send it directly to S3, getting the URL in the closure. Once you have the URL you can pass that as JSON to your server.

```swift
let urlPathIdentifier: String = <Some unique identifier here. I typically use userId + timestamp>
let imageUploader = SMAWSImageUploader(bucketName: <Your S3 Bucket Name>, urlPathIdentifier: urlPathIdentifier, uploadProgressTracker: nil)
  imageUploader.uploadImageToS3(resizedImage, SMAWSCompletionBlock: {
  successURL, error in
  if successURL != nil {
     //Pass successURL to your server           
  } else if error != nil {
     //Handle error           
  }
})
```

Tracking the progress of your upload is incredibly simple with SMAWSManager. Simply conform to the SMAWSImageUploadProgressTrackerDelegate protocol.
```swift
class ViewController : SMAWSImageUploadProgressTrackerDelegate
```

Then when you initiate your SMAWSImageUploader instance, pass in self as the delegate:
```swift
let imageUploader = SMAWSImageUploader(bucketName: <Your S3 Bucket Name>, urlPathIdentifier: urlPathIdentifier, uploadProgressTracker: self)
```

This method 'progressUpdated' gets called with a float between 0 and 1 representing the current upload percentage.
```swift
func progressUpdated(currentProgress: Float) {
  print("Upload progress is: \(currentProgress)")
}
```

#### These are the steps needed to get setup on AWS S3 if you haven't before.
#### In AWS, you need to configure your identidyPool and get an 'identityPoolID'. Here's how to do that.

Cognito Identity provides secure access to AWS services. Identities are managed by an identity pool. Roles specify resources an identity can access and are associated with an identity pool. To create an identity pool for your application:

    *Log into the Cognito Console and click the New Identity Pool button

    *Give your Identity Pool a unique name and enable access to unauthenticated identities

    *Click the Create Pool button and then the Update Roles to create your identity pool and associated roles

    *Using SMAWSManager is very simple. First, connect to AWS via your appDelegate with just one method:

Configure your Cognito Identity to have access to the S3 buckets in your AWS account:

    *Navigate to the Identity and Access Management Console and click Roles in the left-hand pane.

    *Type your Identity Pool name into the search box - two roles will be listed one for unauthenticated users and one for authenticated users.

    *Click the role for unauthenticated users (it will have unauth appended to your Identity Pool name).

    *Click the Create Role Policy button, select Policy Generator, and click the Select button.

    *Set the configuration as follows:  
      Effect: Allow
      AWS Service: Amazon S3
      Actions: All Actions Selected

