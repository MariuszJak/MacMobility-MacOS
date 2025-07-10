//
//  CircleSlice.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 04/07/2025.
//

import Foundation
import SwiftUI

struct CircleSlice: View {
    let index: Int
    let sliceAngle: Double
    let thickness: CGFloat

    var startAngle: Angle { .degrees(-20) }
    var rotation: Angle { .degrees(Double(index) * sliceAngle) }

    var body: some View {
        let sliceShape = CircleSliceShape(
            startAngle: startAngle,
            sliceAngle: .degrees(sliceAngle),
            thickness: thickness
        )

        return sliceShape
            .fill(LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 44/255, green: 44/255, blue: 46/255),
                    Color(red: 58/255, green: 58/255, blue: 60/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            ))
            .rotationEffect(rotation)
            .overlay {
                sliceShape
                    .stroke(Color(red: 44/255, green: 44/255, blue: 46/255), lineWidth: 1.0)
                    .rotationEffect(rotation)
            }
            .contentShape(sliceShape)
    }
}

struct CircleSliceBackground: View {
    let index: Int
    let sliceAngle: Double
    let thickness: CGFloat

    var startAngle: Angle { .degrees(-20) }
    var rotation: Angle { .degrees(Double(index) * sliceAngle) }

    var body: some View {
        let sliceShape = CircleSliceShape(
            startAngle: startAngle,
            sliceAngle: .degrees(sliceAngle),
            thickness: thickness
        )

        return sliceShape
            .fill(.cyan)
            .rotationEffect(rotation)
            .overlay {
                sliceShape
                    .stroke(Color(red: 44/255, green: 44/255, blue: 46/255), lineWidth: 1.0)
                    .rotationEffect(rotation)
            }
            .contentShape(sliceShape)
    }
}

struct CircleSliceButton: View {
    let index: Int
    let sliceAngle: Double
    let thickness: CGFloat
    let background: Color
    var startAngle: Angle { .degrees(-20) }
    var rotation: Angle { .degrees(Double(index) * sliceAngle) }

    var body: some View {
        let sliceShape = CircleSliceShape(
            startAngle: startAngle,
            sliceAngle: .degrees(sliceAngle),
            thickness: thickness
        )

        return sliceShape
            .fill(background)
            .rotationEffect(rotation)
            .overlay {
                sliceShape
                    .stroke(Color.black.opacity(0.2), lineWidth: 0.5)
                    .rotationEffect(rotation)
            }
            .contentShape(sliceShape)
    }
}
