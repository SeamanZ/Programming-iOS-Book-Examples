

import UIKit
import AVFoundation
import AVKit
import MobileCoreServices
import Photos
import ImageIO

func checkForPhotoLibraryAccess(andThen f:(()->())? = nil) {
    let status = PHPhotoLibrary.authorizationStatus()
    switch status {
    case .authorized:
        f?()
    case .notDetermined:
        PHPhotoLibrary.requestAuthorization() { status in
            if status == .authorized {
                DispatchQueue.main.async {
                	f?()
				}
            }
        }
    case .restricted:
        // do nothing
        break
    case .denied:
        // do nothing, or beg the user to authorize us in Settings
        break
    }
}

func checkForMicrophoneCaptureAccess(andThen f:(()->())? = nil) {
    let status = AVCaptureDevice.authorizationStatus(for:.audio)
    switch status {
    case .authorized:
        f?()
    case .notDetermined:
        AVCaptureDevice.requestAccess(for:.audio) { granted in
            if granted {
                DispatchQueue.main.async {
                    f?()
                }
            }
        }
    case .restricted:
        // do nothing
        break
    case .denied:
        let alert = UIAlertController(
            title: "Need Authorization",
            message: "Wouldn't you like to authorize this app " +
            "to use the microphone?",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: "No", style: .cancel))
        alert.addAction(UIAlertAction(
        title: "OK", style: .default) {
            _ in
            let url = URL(string:UIApplicationOpenSettingsURLString)!
            UIApplication.shared.open(url)
        })
        UIApplication.shared.delegate!.window!!.rootViewController!.present(alert, animated:true)
    }
}



func checkForMovieCaptureAccess(andThen f:(()->())? = nil) {
    let status = AVCaptureDevice.authorizationStatus(for:.video)
    switch status {
    case .authorized:
        f?()
    case .notDetermined:
        AVCaptureDevice.requestAccess(for:.video) { granted in
            if granted {
                DispatchQueue.main.async {
                	f?()
				}
            }
        }
    case .restricted:
        // do nothing
        break
    case .denied:
        let alert = UIAlertController(
            title: "Need Authorization",
            message: "Wouldn't you like to authorize this app " +
            "to use the camera?",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: "No", style: .cancel))
        alert.addAction(UIAlertAction(
        title: "OK", style: .default) {
            _ in
            let url = URL(string:UIApplicationOpenSettingsURLString)!
            UIApplication.shared.open(url)
        })
        UIApplication.shared.delegate!.window!!.rootViewController!.present(alert, animated:true)
    }
}




class ViewController: UIViewController,
UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var redView: UIView!
    weak var picker : UIImagePickerController?
        
    @IBAction func doTake (_ sender: Any!) {
        checkForMovieCaptureAccess(andThen: self.micCheck)
    }
    
    func micCheck() {
        checkForMicrophoneCaptureAccess(andThen:self.reallyTake)
    }
    
    func reallyTake() {
        let src = UIImagePickerControllerSourceType.camera
        guard UIImagePickerController.isSourceTypeAvailable(src) else {return}
        
        var which : Int {return 4} // 1, 2, 3, 4
        let desiredTypes : [String] = {
            switch which {
            case 1: return [kUTTypeImage as String]
            case 2: return [kUTTypeMovie as String]
            case 3: return [kUTTypeImage as String, kUTTypeMovie as String]
            case 4: return [kUTTypeImage as String, kUTTypeLivePhoto as String] // nope
            default: return [kUTTypeImage as String, kUTTypeMovie as String, kUTTypeLivePhoto as String] // nope
            }
        }()
        // so I think what this proves is that they are not going to let me take a live photo this way
        let picker = UIImagePickerController()
        picker.sourceType = src
        picker.mediaTypes = desiredTypes
        print(picker.mediaTypes) // if you include live photo, they throw it away
        picker.allowsEditing = false
        picker.delegate = self
        
        self.present(picker, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated:true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : Any]) {
            print(info[UIImagePickerControllerPHAsset] as Any)
            let url = info[UIImagePickerControllerMediaURL] as? URL
            var im = info[UIImagePickerControllerOriginalImage] as? UIImage
            if let ed = info[UIImagePickerControllerEditedImage] as? UIImage {
                im = ed
            }
            if let live = info[UIImagePickerControllerLivePhoto] {
                print("I got a live photo!") // nope
                _ = live
            }
            let imurl = info[UIImagePickerControllerImageURL] as? URL
            print(imurl as Any)
            let m = info[UIImagePickerControllerMediaMetadata] as? NSDictionary
            print(m as Any)
            self.dismiss(animated:true) {
                let mediatype = info[UIImagePickerControllerMediaType]
                guard let type = mediatype as? NSString else {return}
                switch type as CFString {
                case kUTTypeImage:
                    if im != nil {
                        self.showImage(im!)
                        // showing how simple it is to save into the Camera Roll
                        // return;
                        checkForPhotoLibraryAccess {
                            var which : Int { return 0 }
                            switch which {
                            case 0: // simply add image to library
                                let lib = PHPhotoLibrary.shared()
                                lib.performChanges({
                                    typealias Req = PHAssetChangeRequest
                                    let req = Req.creationRequestForAsset(from: im!)
                                    // apply metadata info here, as desired
                                })
                            case 1: // add image while folding in the metadata
                                let jpeg = UIImageJPEGRepresentation(im!, 1)!
                                let src = CGImageSourceCreateWithData(jpeg as CFData, nil)!
                                let data = NSMutableData()
                                let uti = CGImageSourceGetType(src)!
                                let dest = CGImageDestinationCreateWithData(data as CFMutableData, uti, 1, nil)!
                                CGImageDestinationAddImageFromSource(dest, src, 0, m)
                                CGImageDestinationFinalize(dest)
                                let lib = PHPhotoLibrary.shared()
                                lib.performChanges({
                                    let req = PHAssetCreationRequest.forAsset()
                                    req.addResource(with: .photo, data: data as Data, options: nil)
                                })
                            default: break
                            }
                            
                        }
                    }
                case kUTTypeMovie:
                    if url != nil {
                        self.showMovie(url!)
                    }
                default:break
                }
            }
    }
    
    func clearAll() {
        if self.childViewControllers.count > 0 {
            let av = self.childViewControllers[0] as! AVPlayerViewController
            av.willMove(toParentViewController: nil)
            av.view.removeFromSuperview()
            av.removeFromParentViewController()
        }
        self.redView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    func showImage(_ im:UIImage) {
        self.clearAll()
        let iv = UIImageView(image:im)
        iv.contentMode = .scaleAspectFit
        iv.frame = self.redView.bounds
        self.redView.addSubview(iv)
    }
    
    func showMovie(_ url:URL) {
        self.clearAll()
        let av = AVPlayerViewController()
        let player = AVPlayer(url:url)
        av.player = player
        self.addChildViewController(av)
        av.view.frame = self.redView.bounds
        av.view.backgroundColor = self.redView.backgroundColor
        self.redView.addSubview(av.view)
        av.didMove(toParentViewController: self)
    }
    
    func tap (g:UIGestureRecognizer) {
        self.picker?.takePicture()
    }
    
    
}
