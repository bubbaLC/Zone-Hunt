//
//  Zone_HuntApp.swift
//  Zone Hunt
//
//  Created by Liam Colton on 9/10/24.
//

//import SwiftUI
//import Firebase
//import UIKit
//import UserNotifications
//import FirebaseCore
//import FirebaseMessaging
//
//// Define the AppDelegate to handle Firebase configuration
//class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
//    func application(_ application: UIApplication,
//                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
//        // Configure Firebase
//        FirebaseApp.configure()
//        print("Firebase configured")
//
//        // Set the messaging delegate
//        Messaging.messaging().delegate = self
//
//        // Register for remote notifications
//        UNUserNotificationCenter.current().delegate = self
//        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//        UNUserNotificationCenter.current().requestAuthorization(
//            options: authOptions,
//            completionHandler: { granted, error in
//                if let error = error {
//                    print("Failed to request authorization: \(error)")
//                } else {
//                    print("Authorization granted: \(granted)")
//                }
//            }
//        )
//        
//        application.registerForRemoteNotifications()
//
//        return true
//    }
//
//    // Implement required MessagingDelegate methods
//    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//        print("Firebase registration token: \(fcmToken ?? "")")
//        // If necessary, send the token to your server
//    }
//
//    // Implement required UNUserNotificationCenterDelegate methods
//    func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                willPresent notification: UNNotification,
//                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        completionHandler([.alert, .badge, .sound])
//    }
//
//    func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                didReceive response: UNNotificationResponse,
//                                withCompletionHandler completionHandler: @escaping () -> Void) {
//        print("User tapped on notification")
//        completionHandler()
//    }
//}
//
//@main
//struct Zone_HuntApp: App {
//    // Register the AppDelegate for Firebase setup
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}

import SwiftUI
import Firebase
import GoogleSignIn
// Define the AppDelegate to handle Firebase configuration
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        print("Firebase configured")
        return true
    }
}
@main
struct Zone_HuntApp: App {
    // Register the AppDelegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
