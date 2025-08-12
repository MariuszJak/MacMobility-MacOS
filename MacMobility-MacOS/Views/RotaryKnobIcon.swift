//
//  RotaryKnobIcon.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 12/08/2025.
//

import Foundation
import SwiftUI

struct RotaryKnobIcon: View {
    var angle: Double = 120
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.96, green: 0.96, blue: 0.96))
                .shadow(color: .black.opacity(0.05), radius: 4)
            
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let knobRadius = size * 0.45
                let markerOffset = knobRadius * 0.75
                let dotOffset = knobRadius * 0.9
                
                // Knob base
                Circle()
                    .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .shadow(color: .black.opacity(0.08), radius: 4)
                    .overlay(
                        Circle()
                            .stroke(Color(red: 0.88, green: 0.88, blue: 0.88), lineWidth: 3)
                    )
                    .frame(width: knobRadius * 2, height: knobRadius * 2)
                    .position(center)
                
                // Fixed top dot
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .position(x: center.x, y: center.y - dotOffset)
                
                // Rotating marker
                Circle()
                    .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .frame(width: knobRadius * 2, height: knobRadius * 2)
                    .overlay(
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 6, height: markerOffset)
                            .offset(y: -markerOffset / 2)
                    )
                    .rotationEffect(.degrees(angle))
                    .position(center)
                
                // Arc from top dot to marker
                ArcFullSweepShape(center: center,
                                  radius: dotOffset,
                                  startDeg: -90,
                                  sweepDeg: angle)
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .foregroundColor(.orange.opacity(0.9))
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(width: 100, height: 100)
        }
    }
}

// Shape for the arc
struct ArcFullSweepShape: Shape {
    let center: CGPoint
    let radius: CGFloat
    let startDeg: Double
    let sweepDeg: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let endDeg = startDeg + sweepDeg
        p.addArc(center: center,
                 radius: radius,
                 startAngle: Angle(degrees: startDeg),
                 endAngle: Angle(degrees: endDeg),
                 clockwise: false)
        return p
    }
}
