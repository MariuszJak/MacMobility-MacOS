//
//  NSColor+Ext.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 16/03/2025.
//

import SwiftUI

extension NSColor {
    func toHex(alpha: Bool = false) -> String? {
        guard let rgbColor = usingColorSpace(.sRGB) else {
            return nil
        }

        let r = Int(rgbColor.redComponent * 255)
        let g = Int(rgbColor.greenComponent * 255)
        let b = Int(rgbColor.blueComponent * 255)

        if alpha {
            let a = Int(rgbColor.alphaComponent * 255)
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        } else {
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }
}
