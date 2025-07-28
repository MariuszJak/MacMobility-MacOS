//
//  SliceButton.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 06/07/2025.
//

import Foundation
import SwiftUI

struct SliceShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var thickness: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius - thickness

        var path = Path()

        path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()

        return path
    }
}

struct SliceButton<Content: View>: View {
    @State var isHovering = false
    var index: Int
    var totalSlices: Int
    var thickness: CGFloat
    var color: Color
    var action: (() -> Void)?
    var content: () -> AnyView

    var body: some View {
        let sliceAngle = 360.0 / Double(totalSlices)
        let startAngle = Angle(degrees: sliceAngle * Double(index) - 30)
        let endAngle = Angle(degrees: sliceAngle * Double(index + 1) - 30)
        let centerAngle = Angle(degrees: (startAngle.degrees + endAngle.degrees) / 2)

        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) / 2
            let innerRadius = radius - thickness
            let midRadius = (radius + innerRadius) / 2

            let centerX = geo.size.width / 2
            let centerY = geo.size.height / 2

            let x = centerX + CGFloat(cos(centerAngle.radians)) * midRadius
            let y = centerY + CGFloat(sin(centerAngle.radians)) * midRadius

            ZStack {
                SliceShape(startAngle: startAngle, endAngle: endAngle, thickness: thickness)
                    .fill(isHovering ? .cyan : color)
                    .overlay(
                        SliceShape(startAngle: startAngle, endAngle: endAngle, thickness: thickness)
                            .stroke(.black.opacity(0.4), lineWidth: 1)
                            .if(action != nil) {
                                $0.onHover { hovering in
                                    withAnimation {
                                        isHovering = hovering
                                    }
                                }
                            }
                    )
                    .contentShape(SliceShape(startAngle: startAngle, endAngle: endAngle, thickness: thickness))
                    .onTapGesture {
                        action?()
                    }

                content()
                    .position(x: x, y: y)
            }
        }
    }
}
