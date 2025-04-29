//
//  ShortcutSection.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 29/04/2025.
//

import Foundation

class ShortcutSection: Identifiable {
    var id: String = UUID().uuidString
    var title: String
    @Published var isExpanded: Bool
    var items: [ShortcutObject]
    
    init(title: String, isExpanded: Bool, items: [ShortcutObject]) {
        self.title = title
        self.isExpanded = isExpanded
        self.items = items
    }
}
