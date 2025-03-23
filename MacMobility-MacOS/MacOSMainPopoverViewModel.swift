//
//  MacOSMainPopoverViewModel.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 23/03/2025.
//

import Foundation
import SwiftUI

class MacOSMainPopoverViewModel: ObservableObject {
    @Published var isPaidLicense = false
    @Published var isTrialExpired: Bool = false
    @Inject var appLincenseManager: AppLicenseManager
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
