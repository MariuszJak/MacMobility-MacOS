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
    @Published var isCheckingForUpdate = false
    @Published var appIsUpToDate: Bool?
    
    @Inject var appLincenseManager: AppLicenseManager
    @Inject var appUpdatesManager: UpdatesManager
    private var timer: Timer?
    private var updatedTimer: Timer?
    var trialManager = TrialManager()
    var updateData: AppUpdateResponse? {
        appUpdatesManager.updateData
    }
    
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
    func checkVersion(_ completion: (() -> Void)? = nil) async {
        isCheckingForUpdate = true
        await appUpdatesManager.checkVersion { [weak self] needsUpdate in
            self?.isCheckingForUpdate = false
            self?.needsUpdate = needsUpdate
            self?.appIsUpToDate = !needsUpdate
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self?.appIsUpToDate = nil
            }
            completion?()
        }
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            trialManager.checkTrialStatus()
            isTrialExpired = trialManager.isTrialExpired
        }
        
        updatedTimer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.checkVersion()
            }
        }
    }
    
    func resetTrial() {
        trialManager.resetTrial()
    }
    
    deinit {
        timer?.invalidate()
        updatedTimer?.invalidate()
    }
}
