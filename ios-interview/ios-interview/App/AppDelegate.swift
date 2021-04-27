//
//  AppDelegate.swift
//  ios-interview
//
//  Created by Kevin Bastien on 4/23/21.
//  Copyright © 2021 Supermall. All rights reserved.
//

import AWSS3
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureS3()
        
        let videoViewController = VideoViewController()
        window = UIWindow()
        window?.rootViewController = videoViewController
        window?.makeKeyAndVisible()
        
        return true
    }
    
    // MARK: Configure s3

    func configureS3() {
        let poolId = "us-west-2:440de1bc-fe71-4cf6-a48b-8c83f8fe5a30"
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USWest2, identityPoolId: poolId)
        let configuration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
}

