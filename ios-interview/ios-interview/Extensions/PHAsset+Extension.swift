//
//  PHAsset+Extension.swift
//  ios-interview
//
//  Created by Kevin Bastien on 4/24/21.
//  Copyright © 2021 Supermall. All rights reserved.
//

import AVFoundation
import Photos
import UIKit

extension PHAsset {
    func urlFromAsset(completion: @escaping ((_ url: URL) -> Void)) {
        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        manager.requestAVAsset(forVideo: self, options: options) { (video, audio, nil) in
            guard let asset = video as? AVURLAsset else { return }
            completion(asset.url.absoluteURL)
        }
    }
    
    func thumbnailImageFromAsset(size: CGSize, completion: @escaping ((_ image: UIImage?) -> Void)) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        options.deliveryMode = .highQualityFormat
        PHImageManager.default().requestImage(for: self, targetSize: size, contentMode: .aspectFill, options: options) { (image, userInfo) -> Void in
            completion(image)
        }
    }
}
