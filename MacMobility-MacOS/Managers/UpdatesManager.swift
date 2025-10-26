//
//  UpdatesManager.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 13/04/2025.
//

import Foundation
import SwiftUI

struct Version: Comparable {
    let components: [Int]

    init(_ versionString: String) {
        self.components = versionString
            .split(separator: ".")
            .map { Int($0) ?? 0 }
    }

    static func < (lhs: Version, rhs: Version) -> Bool {
        for (l, r) in zip(lhs.components, rhs.components) {
            if l != r {
                return l < r
            }
        }
        return lhs.components.count < rhs.components.count
    }
}

public class UpdatesManager: ObservableObject {
    @Inject private var useCase: AppUpdateUseCaseProtocol
    private(set) var updateData: AppUpdateResponse?
    private var isDownloadingUpdate: Bool = false
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    public init() {}
    
    @MainActor
    public func checkVersion(completion: @escaping (Bool) -> Void) async {
        let result = await useCase.checkForUpdate()
        switch result {
        case .success(let data):
            updateData = data
            completion(Version(data.latest_version) > Version(appVersion))
        case .failure:
            completion(false)
        }
    }
    
    func downloadAndInstallUpdate(_ completion: @escaping () -> Void) {
        guard !isDownloadingUpdate, let updateData, let url = URL(string: updateData.download_url) else { return }
        isDownloadingUpdate = true
        let task = URLSession.shared.downloadTask(with: url) { localURL, _, _ in
            guard let localURL = localURL else { return }

            let fileManager = FileManager.default
            let downloadsDir = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            let destinationZip = downloadsDir.appendingPathComponent("macmobility.zip")
            let destinationApp = "/Applications/MacMobility.app"

            try? fileManager.removeItem(at: destinationZip)
            try? fileManager.moveItem(at: localURL, to: destinationZip)

            // Unzip and replace old app
            let unzipTask = Process()
            unzipTask.launchPath = "/usr/bin/ditto"
            unzipTask.arguments = ["-xk", destinationZip.path, downloadsDir.path]
            unzipTask.launch()
            unzipTask.waitUntilExit()

            // Replace old app
            DispatchQueue.main.async {
                let appPath = downloadsDir.appendingPathComponent("MacMobility.app")
                do {
                    if fileManager.fileExists(atPath: destinationApp) {
                        try fileManager.removeItem(atPath: destinationApp)
                    }
                    try fileManager.moveItem(atPath: appPath.path, toPath: destinationApp)
                    self.relaunchWithDelay(newAppPath: destinationApp)
                } catch {
                    print("Failed to update: \(error)")
                    completion()
                }
                self.isDownloadingUpdate = false
            }
        }
        task.resume()
    }
    
    func relaunchWithDelay(newAppPath: String) {
        let script = """
        /bin/bash -c 'sleep 1; open "\(newAppPath)"'
        """
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", script]
        try? task.run()
        NSApp.terminate(nil)
    }
}
