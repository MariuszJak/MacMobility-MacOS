//
//  ScreenItem.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 06/03/2025.
//

import Foundation

class ScreenItem: Identifiable, Codable {
    let id: String
    var apps: [ScreenTypeContainer]
    
    init(id: String, apps: [ScreenTypeContainer] = [.init(id: 0), .init(id: 1)]) {
        self.id = id
        self.apps = apps
    }
    
    func updateApps(_ containers: [ScreenTypeContainer]) {
        apps = containers
    }
}
