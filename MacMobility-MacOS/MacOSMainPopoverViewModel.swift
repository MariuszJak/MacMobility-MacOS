//
//  MacOSMainPopoverViewModel.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 23/03/2025.
//

import Foundation
import SwiftUI

class MacOSMainPopoverViewModel: ObservableObject {
    @Published var isPaidLicense = false
    @Published var isTrialExpired: Bool = false
    @Published var needsUpdate: Bool = false
    @Published var isUpdating: Bool = false
    @Inject var appLincenseManager: AppLicenseManager
    @Inject var appUpdatesManager: UpdatesManager
    private var timer: Timer?
    var trialManager = TrialManager()
    
    init() {
        startMonitoring()
        appLincenseManager.completion = { [weak self] license in
            guard let self else { return }
            isPaidLicense = license == .paid
            if isPaidLicense {
                timer?.invalidate()
            }
        }
        isPaidLicense = appLincenseManager.checkLicenseStatus() == .paid
        if isPaidLicense {
            timer?.invalidate()
        } else {
            isTrialExpired = trialManager.isTrialExpired
        }
    }
    
    @MainActor
    func checkVersion() async {
        await appUpdatesManager.checkVersion { [weak self] needsUpdate in
            self?.needsUpdate = needsUpdate
        }
    }
    
    func updateApp() {
        isUpdating = true
        appUpdatesManager.downloadAndInstallUpdate { [weak self] in
            self?.isUpdating = false
        }
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self else { return }
            trialManager.checkTrialStatus()
            isTrialExpired = trialManager.isTrialExpired
        }
    }
    
    func resetTrial() {
        trialManager.resetTrial()
    }
    
    deinit {
        timer?.invalidate()
    }
}
