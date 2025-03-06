//
//  ConfigurableScreenViewModel.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 06/03/2025.
//

import Foundation
import SwiftUI

enum ConfigurableScreenType {
    case singleScreen
    case splitScreenHorizontal
}

enum ConfigurableScreenTypeSize {
    case small
    case medium
    
    var padding: CGFloat {
        switch self {
        case .small:
            return 0.5
        case .medium:
            return 8.0
        }
    }
    
    var lineWidth: CGFloat {
        switch self {
        case .small:
            return 1.5
        case .medium:
            return 4.0
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small:
            return 1.0
        case .medium:
            return 8.0
        }
    }
}

class ConfigurableScreenViewModel: ObservableObject {
    @Published var screenType: ConfigurableScreenType = .singleScreen
    var apps: [ScreenTypeContainer]?
    var addAction: ([ScreenTypeContainer]) -> Void
    var removeAction: (String) -> Void
    
    init(apps: [ScreenTypeContainer]?, addAction: @escaping ([ScreenTypeContainer]) -> Void, removeAction: @escaping (String) -> Void) {
        self.apps = apps
        self.screenType = (apps?.filter { $0.app != nil }.count ?? 0) > 1 ? .splitScreenHorizontal : .singleScreen
        self.addAction = addAction
        self.removeAction = removeAction
    }
    
    func resetToSingleScreen() {
        apps?[1] = .init(id: 1)
        addAction(apps ?? [])
    }
}
