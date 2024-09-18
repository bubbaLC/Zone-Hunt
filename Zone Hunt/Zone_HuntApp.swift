//
//  Zone_HuntApp.swift
//  Zone Hunt
//
//  Created by Liam Colton on 9/10/24.
//

import SwiftUI
import Firebase
// Define the AppDelegate to handle Firebase configuration
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
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

