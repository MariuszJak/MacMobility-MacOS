//
//  CircleSliceShape.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 04/07/2025.
//

import Foundation
import SwiftUI

struct CircleSliceShape: Shape {
    var startAngle: Angle = .degrees(-15)
    var sliceAngle: Angle = .degrees(36)
    var thickness: CGFloat = 50

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius - thickness
        let center = CGPoint(x: rect.midX, y: rect.midY)

        let endAngle = startAngle + sliceAngle

        var path = Path()
        
        // Outer arc
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)

        // Line to inner arc
        path.addArc(center: center,
                    radius: innerRadius,
                    startAngle: endAngle,
                    endAngle: startAngle,
                    clockwise: true)

        path.closeSubpath()
        return path
    }
}
