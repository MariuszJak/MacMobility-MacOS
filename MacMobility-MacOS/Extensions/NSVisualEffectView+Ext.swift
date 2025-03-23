//
//  NSVisualEffectView+Ext.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 06/03/2025.
//

import SwiftUI

extension NSVisualEffectView {
    public static func createVisualAppearance(for window: NSWindow?) -> NSVisualEffectView? {
        guard let window else { return nil }
        
        let visualEffectView = NSVisualEffectView(frame: window.contentView?.bounds ?? .zero)
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.appearance = NSAppearance(named: .vibrantDark)
        
        return visualEffectView
    }
}
