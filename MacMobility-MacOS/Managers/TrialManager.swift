//
//  TrialManager.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 23/03/2025.
//

import Foundation

class TrialManager: ObservableObject {
    private let firstActivationKey = UserDefaults.Const.firstActivationDate.rawValue
    private let trialDuration: TimeInterval = 14 * 24 * 60 * 60 // 14 days
//    private let trialDuration: TimeInterval = 30 // 30 seconds

    @Published var isTrialExpired: Bool = false

    init() {
        checkTrialStatus()
    }

    func checkTrialStatus() {
        let defaults = UserDefaults.standard

        if let firstDate = defaults.object(forKey: firstActivationKey) as? Date {
            let expireTime = firstDate.addingTimeInterval(trialDuration)
            isTrialExpired = Date() >= expireTime
        } else {
            defaults.set(Date(), forKey: firstActivationKey)
            defaults.synchronize()
            isTrialExpired = false
        }
    }

    func resetTrial() {
        UserDefaults.standard.removeObject(forKey: firstActivationKey)
        checkTrialStatus()
    }
}
