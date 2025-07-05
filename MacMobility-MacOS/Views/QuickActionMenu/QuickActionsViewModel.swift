//
//  QuickActionsViewModel.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 04/07/2025.
//

import Foundation
import SwiftUI

class QuickActionsViewModel: ObservableObject {
    @Published var items: [ShortcutObject] = []
    @Published var sections: [Int: [ShortcutObject]] = [:]
    @Published var pages: Int = 1
    @Published var currentPage: Int = 1
    private let allItems: [ShortcutObject]
    
    init(items: [ShortcutObject], allItems: [ShortcutObject]) {
        self.items = items
        self.allItems = allItems
        self.currentPage = UserDefaults.standard.get(key: .subitemCurrentPage) ?? 1
        self.pages = UserDefaults.standard.get(key: .subitemPages) ?? 1
        self.sections = [pages: items]
    }
    
    func object(for id: String) -> ShortcutObject? {
        (allItems + items).first { $0.id == id }
    }
    
    func prevPage() {
        if currentPage > 1 {
            currentPage -= 1
        }
        UserDefaults.standard.store(currentPage, for: .subitemCurrentPage)
    }
    
    func nextPage() {
        if currentPage < pages {
            currentPage += 1
        }
        UserDefaults.standard.store(currentPage, for: .subitemCurrentPage)
    }
    
    func addPage() {
        pages = pages + 1
        currentPage = pages
        (0..<10).forEach { index in
            items.append(.empty(for: index, page: currentPage))
        }
        UserDefaults.standard.store(pages, for: .subitemPages)
        UserDefaults.standard.store(currentPage, for: .subitemCurrentPage)
    }
    
    func removePage(with number: Int) {
        items.removeAll { $0.page == number }
        items.enumerated().forEach { (index, object) in
            if items[index].page > number {
                items[index].page -= 1
                items[index].index = index
            }
        }
        if pages > 1 {
            pages -= 1
        }
        currentPage = pages
        UserDefaults.standard.store(pages, for: .subitemPages)
        UserDefaults.standard.store(currentPage, for: .subitemCurrentPage)
    }
    
    func add(_ object: ShortcutObject, at newIndex: Int = 0) {
        let offset = newIndex + ((currentPage - 1) * 10)
        if let oldIndex = items.firstIndex(where: { $0.id == object.id && items[offset].title != "EMPTY" }) {
            let oldObject = items[offset]
            var tmp = object
            tmp.index = offset
            tmp.page = currentPage
            items[offset] = tmp
            
            if items[offset].objects == nil {
                items[offset].objects = (0..<5).map { .empty(for: $0) }
            }
            
            var tmp2 = oldObject
            tmp2.index = oldIndex
            items[oldIndex] = tmp2
            
            if items[oldIndex].objects == nil {
                items[oldIndex].objects = (0..<5).map { .empty(for: $0) }
            }
        } else {
            var objects: [ShortcutObject]?
            if let oldIndex = items.firstIndex(where: { $0.id == object.id }) {
                objects = items[oldIndex].objects
            }
            items.enumerated().forEach { (i, item) in
                if item.id == object.id {
                    items[i] = .empty(for: i, page: currentPage)
                    items[i].objects = (0..<5).map { .empty(for: $0) }
                }
            }
            let offset = newIndex + ((currentPage - 1) * 10)
            var tmp = object
            tmp.index = offset
            tmp.page = currentPage
            items[offset] = tmp
            if items[offset].objects == nil {
                items[offset].objects = objects ?? (0..<5).map { .empty(for: $0) }
            }
        }
    }
    
    func addSubitem(to itemId: String, item: ShortcutObject, at subIndex: Int) -> ShortcutObject? {
        if let index = items.firstIndex(where: { $0.id == itemId }), items[index].title != "EMPTY" {
            if items[index].objects == nil {
                items[index].objects = (0..<5).map { .empty(for: $0) }
            }
            items[index].objects?[subIndex] = item
            return items[index]
        } else {
            return nil
        }
    }
    
    func removeSubitem(from itemId: String, at subIndex: Int) -> ShortcutObject? {
        let offset = subIndex + ((currentPage - 1) * 10)
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].objects?[offset] = .empty(for: offset)
            return items[index]
        }
        return nil
    }
    
    func remove(at index: Int) -> ShortcutObject {
        let offset = index + ((currentPage - 1) * 10)
        items[offset] = .empty(for: offset, page: currentPage)
        items[offset].objects = (0..<5).map { .empty(for: $0) }
        return items[offset]
    }
}
