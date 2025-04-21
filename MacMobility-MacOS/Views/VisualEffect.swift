//
//  VisualEffect.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 21/04/2025.
//

import AppKit
import SwiftUI

struct VisualEffect: NSViewRepresentable {
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    func makeNSView(context: Self.Context) -> NSView {
        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.material = .popover
        return visualEffect
    }
}
