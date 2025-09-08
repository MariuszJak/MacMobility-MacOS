//
//  ItemSize.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 08/09/2025.
//

import Foundation

enum ItemSize: String, CaseIterable {
    case size1x1
    case size1x2
    case size1x3
    case size2x1
    case size2x2
    case size2x3
    case size3x1
    case size3x2
    case size3x3
    
    var cgSize: CGSize {
        switch self {
        case .size1x1:
            CGSize(width: 1, height: 1)
        case .size1x2:
            CGSize(width: 1, height: 2)
        case .size1x3:
            CGSize(width: 1, height: 3)
        case .size2x1:
            CGSize(width: 2, height: 1)
        case .size2x2:
            CGSize(width: 2, height: 2)
        case .size2x3:
            CGSize(width: 2, height: 3)
        case .size3x1:
            CGSize(width: 3, height: 1)
        case .size3x2:
            CGSize(width: 3, height: 2)
        case .size3x3:
            CGSize(width: 3, height: 3)
        }
    }
    
    var description: String {
        switch self {
        case .size1x1:
            return "1x1"
        case .size1x2:
            return "1x2"
        case .size1x3:
            return "1x3"
        case .size2x1:
            return "2x1"
        case .size2x2:
            return "2x2"
        case .size2x3:
            return "2x3"
        case .size3x1:
            return "3x1"
        case .size3x2:
            return "3x2"
        case .size3x3:
            return "3x3"
        }
    }
}

extension ItemSize {
    static var onlyRectangleSizes: [ItemSize] {
        [.size1x1, .size2x2, .size3x3]
    }
}

extension CGSize {
    var toItemSize: ItemSize? {
        if width.isZero || height.isZero {
            return nil
        }
        
        let widthInt = Int(width)
        let heightInt = Int(height)
        
        switch (widthInt, heightInt) {
        case (1, 1):
            return .size1x1
        case (1, 2):
            return .size1x2
        case (1, 3):
            return .size1x3
        case (2, 1):
            return .size2x1
        case (2, 2):
            return .size2x2
        case (2, 3):
            return .size2x3
        case (3, 1):
            return .size3x1
        case (3, 2):
            return .size3x2
        case (3, 3):
            return .size3x3
        default:
            return nil
        }
    }
}
