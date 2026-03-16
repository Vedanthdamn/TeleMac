//
//  TeleMacApp.swift
//  TeleMac
//
//  Created by Vedanth Dama on 09/03/26.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var viewModel: TeleprompterViewModel?
    var teleprompterWindowController: TeleprompterWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct TeleMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isPromptingActive = false

    var body: some Scene {
        WindowGroup(id: "settings") {
            ContentView(isPromptingActive: $isPromptingActive)
        }
    }
}
