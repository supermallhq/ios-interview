//
//  VideoViewController.swift
//  ios-interview
//
//  Created by Kevin Bastien on 4/23/21.
//  Copyright © 2021 Supermall. All rights reserved.
//

import Photos
import UIKit

class VideoViewController: UIViewController, UICollectionViewDelegate {
    
    // MARK: Constants

    struct Constants {
        static let spinnerTopOffset: CGFloat = 10.0
    }

    // MARK: Properties

    private var fetchingAssetsLabel = UILabel()
    private var spinnerView = UIActivityIndicatorView()
    private var collectionView: UICollectionView?
    private var dataModel = [VideoModel]()
    private var storageManager = StorageManager()

    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkAuthorizationForCameraRollAndGetAssets()
        setupView()
    }
    
    // MARK: View Setup

    private func setupView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: view.frame.size.width, height: view.frame.size.height)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(VideoCollectionViewCell.self, forCellWithReuseIdentifier: VideoCollectionViewCell.identifier)
        collectionView.frame = view.bounds
        collectionView.isScrollEnabled = false
        self.collectionView = collectionView
        
        self.view.addSubview(collectionView)
        self.view.addSubview(fetchingAssetsLabel)
        self.view.addSubview(spinnerView)

        fetchingAssetsLabel.text = "Fetching Videos"
        fetchingAssetsLabel.translatesAutoresizingMaskIntoConstraints = false
        fetchingAssetsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        fetchingAssetsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        spinnerView.topAnchor.constraint(equalTo: fetchingAssetsLabel.bottomAnchor, constant: Constants.spinnerTopOffset).isActive = true
        spinnerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinnerView.startAnimating()
        
    }
    
    // MARK: Camera Roll Helpers
    
    private func checkAuthorizationForCameraRollAndGetAssets() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == PHAuthorizationStatus.authorized {
            getVideosFromCameraRoll()
        } else {
            PHPhotoLibrary.requestAuthorization{ [weak self] status in
                if status == PHAuthorizationStatus.authorized {
                    self?.getVideosFromCameraRoll()
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.collectionView?.backgroundColor = .red
                    }
                }
            }
        }
    }
    
    private func getVideosFromCameraRoll() {
        DispatchQueue.main.async { [weak self] in
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let videos = PHAsset.fetchAssets(with: .video, options: options)
            let size = self?.collectionView?.bounds.size ?? CGSize.zero

            videos.enumerateObjects { (video, index, _) in
                video.urlFromAsset { url in
                    video.thumbnailImageFromAsset(size: size) { image in
                        guard let thumbnailImage = image else { return }
                        let model = VideoModel(originalVideoURL: url, thumbnailImage: thumbnailImage, videoFileFormat: url.pathExtension)
                        self?.dataModel.append(model)
                        
                        if let lastObject = videos.lastObject, videos.index(of: lastObject) == index {
                            DispatchQueue.main.async { [weak self] in
                                self?.collectionView?.reloadData()
                                self?.spinnerView.isHidden = true
                                self?.fetchingAssetsLabel.isHidden = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Upload
    
    private func uploadVideoFromIndexPath(indexPath: IndexPath) {
        let originalVideoURL = dataModel[indexPath.row].originalVideoURL

        storageManager.compressAndUploadVideo(videoURL: originalVideoURL) { [weak self] progress in
            self?.dataModel[indexPath.row].uploadInProgress = true
            
            DispatchQueue.main.async { [weak self] in
                if let cell = self?.collectionView?.cellForItem(at: indexPath) as? VideoCollectionViewCell {
                    let percentage = round(progress * 100)
                    let progressText = String(format: "%.0f", percentage) + "%"
                    cell.progressView.setProgress(Float(progress), animated: true)
                    cell.progressLabel.text = progressText
                }
            }
        } completion: { [weak self] (result, error) in
            if let url = result {
                self?.dataModel[indexPath.row].compressedVideoURL = url
                self?.dataModel[indexPath.row].uploadInProgress = false
                
                DispatchQueue.main.async { [weak self] in
                    self?.collectionView?.isScrollEnabled = true
                    self?.collectionView?.reloadData()
                }
            } else {
                print("Error: ", error.debugDescription)
            }
        }
    }
}

// MARK: UICollectionViewDataSource

extension VideoViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCollectionViewCell.identifier, for: indexPath) as? VideoCollectionViewCell,
            !dataModel.isEmpty && dataModel.count > indexPath.row
        else {
            return UICollectionViewCell(frame: view.frame)
        }
        
        cell.populate(using: dataModel[indexPath.row])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let cell = collectionView.cellForItem(at: indexPath) as? VideoCollectionViewCell,
            let player = cell.playerLayer.player,
            dataModel[indexPath.row].compressedVideoURL != nil
        else {
            return
        }
        
        if player.isPlaying {
            cell.pausePlayer()
        } else {
            cell.playPlayer()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if dataModel[indexPath.row].uploadInProgress == false && dataModel[indexPath.row].compressedVideoURL == nil {
            uploadVideoFromIndexPath(indexPath: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard
            let cell = collectionView.visibleCells.first as? VideoCollectionViewCell,
            let index = collectionView.indexPath(for: cell)
        else {
            return
        }
        
        if dataModel[index.row].uploadInProgress == false && dataModel[index.row].compressedVideoURL == nil {
            collectionView.isScrollEnabled = false
        }
    }
}

// MARK: UICollectionViewDelegateFlowLayout

extension VideoViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

