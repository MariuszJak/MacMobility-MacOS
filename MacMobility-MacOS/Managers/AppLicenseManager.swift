//
//  AppLicenseManager.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 23/03/2025.
//

import Foundation
import AppKit

public enum LicenseType: String, Codable {
    case free
    case paid
}

public struct ValidateKeyResponse: Codable {
    let success: Bool
    let message: String
}

public struct ValidateKeyBody: Codable {
    let key: String
}

public class AppLicenseManager: ObservableObject {
    @Inject private var useCase: LicenseValidationUseCaseProtocol
    public static let shared: AppLicenseManager = .init()
    var license: LicenseType = .free
    public var completion: ((LicenseType) -> Void)?
    
    public init() {
//        UserDefaults.standard.clear(key: .license)
        self.license = UserDefaults.standard.get(key: .license) ?? .free
        completion?(license)
    }
    
    public func checkLicenseStatus() -> LicenseType {
        completion?(license)
        return license
    }
    
    public func degrade() {
        license = .free
        completion?(license)
        UserDefaults.standard.store(license, for: .license)
    }
    
    @MainActor
    public func validate(key: String, completion: @escaping (Bool) -> Void) async {
        if LicenseKeyGenerator().validateKey(key) {
            let result = await useCase.validateLicense(key)
            switch result {
            case .success(let body):
                if body.success {
                    upgrade()
                    completion(true)
                } else {
                    completion(false)
                }
            case .failure:
                completion(false)
            }
        } else {
            completion(false)
        }
    }
    
    private func upgrade() {
        license = .paid
        completion?(license)
        UserDefaults.standard.store(license, for: .license)
    }
}

// ---

public class UpdatesManager: ObservableObject {
    @Inject private var useCase: AppUpdateUseCaseProtocol
    public static let shared: UpdatesManager = .init()
    public var completion: ((LicenseType) -> Void)?
    private var updateData: AppUpdateResponse?
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
            completion(data.latest_version > appVersion)
        case .failure(let error):
            print(error)
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
                    NSWorkspace.shared.open(URL(fileURLWithPath: destinationApp))
                    exit(0)
                } catch {
                    print("Failed to update: \(error)")
                    completion()
                }
                self.isDownloadingUpdate = false
            }
        }
        task.resume()
    }
}
