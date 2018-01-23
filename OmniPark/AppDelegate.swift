//
//  AppDelegate.swift
//  OminPark
//
//  Created by Emanuel  Guerrero on 10/21/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import UIKit
import UserNotifications
import GoogleMaps
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Fabric.with([Crashlytics.self])
        GMSServices.provideAPIKey(GOOGLE_MAPS_API_KEY)
        UserManager.shared.login()
        let current = UNUserNotificationCenter.current()
        current.requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
            DispatchQueue.main.async {
                print(granted)
                if granted {
                    application.registerForRemoteNotifications()
                }
            }
        }
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Device registered for notifications")
        let notificationAction = UNNotificationAction(identifier: "com.silverlogic.OmniPark.renewaction",
                                                      title: "Renew",
                                                      options: .foreground)
        let notificationCategory = UNNotificationCategory(identifier: "com.silverlogic.OmniPark.category",
                                                          actions: [notificationAction], intentIdentifiers: [],
                                                          hiddenPreviewsBodyPlaceholder: "Renew Parking",
                                                          options: [])
        let current = UNUserNotificationCenter.current()
        current.setNotificationCategories([notificationCategory])
        current.delegate = self
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Error registering for notifications")
        print(error)
    }
}


// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let actionIdentifier = response.actionIdentifier
        let content = response.notification.request.content
        switch actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            completionHandler()
        case UNNotificationDefaultActionIdentifier:
            completionHandler()
        case "com.silverlogic.OmniPark.renewaction":
            print("Action chosen")
            let content2 = UNMutableNotificationContent()
            content2.title = "Parking Space Expired"
            content2.sound = UNNotificationSound.default()
            content2.categoryIdentifier = "com.silverlogic.OmniPark.category.expiring"
            let trigger2 = UNTimeIntervalNotificationTrigger(timeInterval: 25, repeats: false)
            let notification2 = UNNotificationRequest(identifier: "com.silverlogic.OmniPark.request",
                                                      content: content2,
                                                      trigger: trigger2)
            UNUserNotificationCenter.current().add(notification2) { (error) in
                guard error == nil else {
                    print("Error setting notification")
                    return
                }
                print("Notification sent")
            }
            ParkBookingManager.shared.extendParkBooking(completion: { (error) in
                completionHandler()
            })
        default:
            completionHandler()
        }
    }
}


// MARK: - Private Instance Attributes
private extension AppDelegate {
    func extendParkBooking(completion: @escaping () -> Void) {
        ParkBookingManager.shared.extendParkBooking { (error) in
            completion()
        }
    }
}

