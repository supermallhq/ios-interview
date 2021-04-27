//
//  AVPlayer+Extension.swift
//  ios-interview
//
//  Created by Kevin Bastien on 4/26/21.
//  Copyright © 2021 Supermall. All rights reserved.
//

import AVFoundation

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}
