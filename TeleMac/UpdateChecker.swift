import Foundation
import AppKit

class UpdateChecker {
    static let currentVersion = "1.1"
    static let githubAPI = "https://api.github.com/repos/Vedanthdamn/TeleMac/releases/latest"
    static let downloadURL = "https://github.com/Vedanthdamn/TeleMac/releases/latest"

    static func checkForUpdates() {
        guard let url = URL(string: githubAPI) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let latestTag = json["tag_name"] as? String else { return }

            let latest = latestTag.replacingOccurrences(of: "v", with: "")

            if latest != currentVersion {
                DispatchQueue.main.async {
                    showUpdateAlert(newVersion: latest)
                }
            }
        }.resume()
    }

    static func showUpdateAlert(newVersion: String) {
        let alert = NSAlert()
        alert.messageText = "TeleMac \(newVersion) is available!"
        alert.informativeText = "A new version of TeleMac is ready to download."
        alert.addButton(withTitle: "Download Update")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: downloadURL)!)
        }
    }
}//
//  UpdateChecker.swift
//  TeleMac
//
//  Created by Vedanth Dama on 16/03/26.
//

