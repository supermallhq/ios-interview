//
//  VideoModel.swift
//  ios-interview
//
//  Created by Kevin Bastien on 4/23/21.
//  Copyright © 2021 Supermall. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

struct VideoModel {
    let originalVideoURL: URL
    let thumbnailImage: UIImage
    let videoFileFormat: String
    var compressedVideoURL: URL? = nil
    var videoCaptions: String? = nil
    var videoHashtags: String? = nil
    var metadata: [AVMetadataItem]? = nil
    var uploadInProgress: Bool = false
}
