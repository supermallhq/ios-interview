//
//  StorageManager.swift
//  ios-interview
//
//  Created by Kevin Bastien on 4/24/21.
//  Copyright © 2021 Supermall. All rights reserved.
//

import AVFoundation
import AWSS3

// MARK: TypeAlias

typealias CompressCompletion = (_ exportSession: AVAssetExportSession?) -> Void
typealias Completion = (_ result: URL?, _ error: Error?) -> Void
typealias Progress = (_ progress: Double) -> Void

class StorageManager {
    // MARK: Properties
    
    private let bucketName = "supermallbucket"

    // MARK: Public Compress/Upload Function

    func compressAndUploadVideo(videoURL: URL, progress: Progress?, completion: Completion?) {
        let videoName = ProcessInfo.processInfo.globallyUniqueString + "." + videoURL.pathExtension
        let compressedURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString).appendingPathExtension(videoURL.pathExtension)
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.compressVideo(inputURL: videoURL, outputURL: compressedURL) { session in
                switch session?.status {
                case .completed:
                    self?.uploadVideoToS3(videoURL: compressedURL, videoName: videoName, progress: progress, completion: completion)
                default:
                    print("Failed to compress video")
                }
            }
        }
    }
    
    // MARK: Compress Video
    
    private func compressVideo(inputURL: URL, outputURL: URL, completion: @escaping CompressCompletion) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(nil)
            return
        }
 
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.canPerformMultiplePassesOverSourceMediaData = true
        exportSession.videoComposition = AVVideoComposition(propertiesOf: urlAsset)
        exportSession.exportAsynchronously {
            completion(exportSession)
        }
   }
    
    // MARK: Upload to s3
    
    private func uploadVideoToS3(videoURL: URL, videoName: String, progress: Progress?, completion: Completion?) {
        let expression = AWSS3TransferUtilityUploadExpression()
        var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?

        expression.progressBlock = {(task, awsProgress) in
            guard let uploadProgress = progress else { return }
            DispatchQueue.main.async {
                uploadProgress(awsProgress.fractionCompleted)
            }
        }

        completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async {
                if error == nil {
                    let url = AWSS3.default().configuration.endpoint.url
                    let publicURL = url?.appendingPathComponent(self.bucketName).appendingPathComponent(videoName)
                    
                    if let completion = completion {
                        completion(publicURL, nil)
                    }
                } else {
                    if let completion = completion {
                        completion(nil, error)
                    }
                }
            }
        }
        
        AWSS3TransferUtility.default().uploadFile(
            videoURL,
            bucket: bucketName,
            key: videoName,
            contentType: "video",
            expression: expression,
            completionHandler: completionHandler
        )
    }
}
