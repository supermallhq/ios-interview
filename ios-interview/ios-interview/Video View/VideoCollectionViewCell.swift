//
//  VideoCollectionViewCell.swift
//  ios-interview
//
//  Created by Kevin Bastien on 4/23/21.
//  Copyright © 2021 Supermall. All rights reserved.
//

import UIKit
import AVFoundation

class VideoCollectionViewCell: UICollectionViewCell {
    
    // MARK: Constants

    struct Constants {
        static let progressLabelText = "Upload"
        static let progressViewHeight: CGFloat = 8.0
        static let progressViewCornerRadius: CGFloat = Constants.progressViewHeight/2
        static let playButtonSize: CGFloat = 50.0
    }

    // MARK: Properties
    
    private let videoContainer = UIView()
    private let thumbnailImageView = UIImageView()
    private let playButtonImageView = UIImageView()
    private var player: AVQueuePlayer?
    private var playerLooper: NSObject?
    private let uploadTitleLabel = UILabel()

    var progressLabel = UILabel()
    var progressView = UIProgressView()
    let playerLayer = AVPlayerLayer()
    
    static let identifier = "VideoCollectionViewCellIdentifier"
    
    // MARK: Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        constructViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Construct Views
    
    private func constructViews() {
        contentView.clipsToBounds = true
        contentView.addSubview(videoContainer)
        
        videoContainer.addSubview(thumbnailImageView)
        videoContainer.addSubview(progressView)
        videoContainer.addSubview(uploadTitleLabel)
        videoContainer.addSubview(progressLabel)
        videoContainer.layer.addSublayer(playerLayer)
        videoContainer.addSubview(playButtonImageView)
        videoContainer.clipsToBounds = true
        videoContainer.frame = contentView.bounds
        
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.frame = contentView.bounds
        
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .systemGreen
        progressView.trackTintColor = .clear
        
        guard let progressViewSublayers = progressView.layer.sublayers else { return }
        progressViewSublayers[1].cornerRadius = Constants.progressViewCornerRadius
        progressView.subviews[1].clipsToBounds = true
        progressView.heightAnchor.constraint(equalToConstant: Constants.progressViewHeight).isActive = true
        progressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        progressView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        progressView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        
        uploadTitleLabel.text = Constants.progressLabelText
        uploadTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        uploadTitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        uploadTitleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        progressLabel.text = "0%"
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.topAnchor.constraint(equalTo: uploadTitleLabel.bottomAnchor).isActive = true
        progressLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        playButtonImageView.isHidden = true
        playButtonImageView.image = UIImage(named: "play")?.withRenderingMode(.alwaysTemplate)
        playButtonImageView.tintColor = .white
        playButtonImageView.translatesAutoresizingMaskIntoConstraints = false
        playButtonImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        playButtonImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        playButtonImageView.heightAnchor.constraint(equalToConstant: Constants.playButtonSize).isActive = true
        playButtonImageView.widthAnchor.constraint(equalToConstant: Constants.playButtonSize).isActive = true
    }
    
    // MARK: Populate

    func populate(using model: VideoModel) {
        if let videoURL = model.compressedVideoURL {
            thumbnailImageView.image = model.thumbnailImage
            let url = URL(fileURLWithPath: videoURL.absoluteString)
            playerLayer.frame = contentView.bounds
            playerLayer.videoGravity = .resizeAspectFill
            let item = AVPlayerItem(url: url)
            let queuePlayer = AVQueuePlayer(playerItem: item)
            playerLayer.player = queuePlayer
            self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
            queuePlayer.play()
        } else {
            uploadTitleLabel.text = Constants.progressLabelText
            progressLabel.text = "0%"
            thumbnailImageView.image = model.thumbnailImage
        }
    }
    
    // MARK: Player Helpers
    
    func pausePlayer() {
        playerLayer.player?.pause()
        playButtonImageView.isHidden = false
    }
    
    func playPlayer() {
        playerLayer.player?.play()
        playButtonImageView.isHidden = true
    }
    
    // MARK: Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playerLayer.player = nil
        thumbnailImageView.image = nil
        uploadTitleLabel.text = nil
        progressLabel.text = nil
        progressView.progress = 0
    }
}
