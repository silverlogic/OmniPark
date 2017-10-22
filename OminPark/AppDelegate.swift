//
//  AppDelegate.swift
//  OminPark
//
//  Created by Emanuel  Guerrero on 10/21/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import UIKit
import GoogleMaps

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        GMSServices.provideAPIKey(GOOGLE_MAPS_API_KEY)
        return true
    }
}

