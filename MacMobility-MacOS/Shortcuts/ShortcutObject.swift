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
    public let indexes: [Int]?
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
    public let size: CGSize?
    
    public init(
        type: ShortcutType,
        page: Int,
        index: Int? = nil,
        indexes: [Int]? = nil,
        size: CGSize? = nil,
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
        self.indexes = indexes ?? [index ?? 0]
        self.path = path
        self.id = id
        self.title = title
        self.size = size ?? .init(width: 1, height: 1)
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
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.index = try container.decodeIfPresent(Int.self, forKey: .index)
        self.indexes = try container.decodeIfPresent([Int].self, forKey: .indexes) ?? [self.index ?? 0]
        self.page = try container.decode(Int.self, forKey: .page)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.path = try container.decodeIfPresent(String.self, forKey: .path)
        self.color = try container.decodeIfPresent(String.self, forKey: .color)
        self.faviconLink = try container.decodeIfPresent(String.self, forKey: .faviconLink)
        self.type = try container.decode(ShortcutType.self, forKey: .type)
        self.imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        self.browser = try container.decodeIfPresent(Browsers.self, forKey: .browser)
        self.scriptCode = try container.decodeIfPresent(String.self, forKey: .scriptCode)
        self.utilityType = try container.decodeIfPresent(UtilityObject.UtilityType.self, forKey: .utilityType)
        self.objects = try container.decodeIfPresent([ShortcutObject].self, forKey: .objects)
        self.showTitleOnIcon = try container.decodeIfPresent(Bool.self, forKey: .showTitleOnIcon)
        self.category = try container.decodeIfPresent(String.self, forKey: .category)
        self.size = try container.decodeIfPresent(CGSize.self, forKey: .size)
    }
}
