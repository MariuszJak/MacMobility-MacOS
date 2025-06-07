//
//  ShortcutObject.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 29/04/2025.
//

import Foundation

public enum ShortcutType: String, Codable {
    case shortcut
    case app
    case webpage
    case utility
    case html
}

extension Array where Element: Equatable {
    mutating func appendUnique(contentsOf newElements: [Element]) {
        for element in newElements {
            if !self.contains(element) {
                self.append(element)
            }
        }
    }
}

public struct ShortcutObject: Identifiable, Codable, Equatable {
    public var index: Int?
    public var page: Int
    public let id: String
    public let title: String
    public var path: String?
    public var color: String?
    public var faviconLink: String?
    public let type: ShortcutType
    public var imageData: Data?
    public var browser: Browsers?
    public var scriptCode: String?
    public var utilityType: UtilityObject.UtilityType?
    public var objects: [ShortcutObject]?
    public var showTitleOnIcon: Bool?
    public var category: String?
    
    public init(
        type: ShortcutType,
        page: Int,
        index: Int? = nil,
        path: String? = nil,
        id: String,
        title: String,
        color: String? = nil,
        faviconLink: String? = nil,
        browser: Browsers? = nil,
        imageData: Data? = nil,
        scriptCode: String? = nil,
        utilityType: UtilityObject.UtilityType? = nil,
        objects: [ShortcutObject]? = nil,
        showTitleOnIcon: Bool = true,
        category: String? = nil
    ) {
        self.page = page
        self.type = type
        self.index = index
        self.path = path
        self.id = id
        self.title = title
        self.color = color
        self.scriptCode = scriptCode
        self.utilityType = utilityType
        self.imageData = imageData
        self.faviconLink = faviconLink
        self.browser = browser
        self.objects = objects
        self.showTitleOnIcon = showTitleOnIcon
        self.category = category
    }
}
