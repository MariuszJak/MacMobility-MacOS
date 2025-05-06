//
//  View+Ext.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 14/03/2024.
//

import SwiftUI

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            content(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func `ifLet`<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }
}

public struct StrokeModifier: ViewModifier {
    private let id = UUID()
    var strokeSize: CGFloat = 1
    var strokeColor: Color = .blue

    public func body(content: Content) -> some View {
        if strokeSize > 0 {
            appliedStrokeBackground(content: content)
        } else {
            content
        }
    }

    private func appliedStrokeBackground(content: Content) -> some View {
        content
            .padding(strokeSize*2)
            .background(
                Rectangle()
                    .foregroundColor(strokeColor)
                    .mask(alignment: .center) {
                        mask(content: content)
                    }
            )
    }

    func mask(content: Content) -> some View {
        Canvas { context, size in
            context.addFilter(.alphaThreshold(min: 0.01))
            if let resolvedView = context.resolveSymbol(id: id) {
                context.draw(resolvedView, at: .init(x: size.width/2, y: size.height/2))
            }
        } symbols: {
            content
                .tag(id)
                .blur(radius: strokeSize)
        }
    }
}

import SwiftUI

extension View {
    func outlinedText(strokeColor: Color = .black, lineWidth: CGFloat = 2) -> some View {
        ZStack {
            ForEach(0..<16, id: \.self) { i in
                self
                    .offset(x: CGFloat(cos(Double(i) / 16 * 2 * .pi)) * lineWidth,
                            y: CGFloat(sin(Double(i) / 16 * 2 * .pi)) * lineWidth)
                    .foregroundColor(strokeColor)
            }
            self
        }
    }
}
