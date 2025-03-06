//
//  WebpagesWindowViewModel.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 06/03/2025.
//

import Foundation
import SwiftUI

struct WebpageItem: Identifiable, Codable, Equatable {
    var id: String
    var webpageTitle: String
    var webpageLink: String
    var faviconLink: String?
    var browser: Browsers
}

class WebpagesWindowViewModel: ObservableObject, WebpagesWindowDelegate {
    @Published var selectedId: String?
    @Published var webpages: [WebpageItem] = []
    var close: () -> Void = {}
    
    init(selectedId: String? = nil, close: @escaping () -> Void = {}) {
        self.selectedId = selectedId
        self.webpages = UserDefaults.standard.getWebItems() ?? []
        self.close = close
    }
    
    func refreshFromStorage() {
        webpages = UserDefaults.standard.getWebItems() ?? []
    }
    
    func getAutomations() -> [WebpageItem] {
        webpages
    }
    
    func saveWebpage(with webpageItem: WebpageItem) {
        if let index = webpages.firstIndex(where: { $0.id == webpageItem.id }) {
            webpages[index] = webpageItem
            UserDefaults.standard.storeWebItems(webpages)
            return
        }
        webpages.append(webpageItem)
        UserDefaults.standard.storeWebItems(webpages)
    }
    
    func removeWebPageItem(with webpageItem: WebpageItem) {
        webpages = webpages.filter { $0.id != webpageItem.id }
        UserDefaults.standard.storeWebItems(webpages)
    }
    
    func saveWebpages() {
        UserDefaults.standard.storeWebItems(webpages)
    }
}
