//
//  UIControlsListView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 23/08/2025.
//

import Foundation
import SwiftUI

struct UIControlItem: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let shortcut: ShortcutObject
}

struct UIControlsListView: View {
    let controls: [UIControlItem] = [
        .init(
            id: UUID(),
            title: "Volume Slider",
            description: "Control Volume of your MacBook with elegant slider",
            shortcut: .init(type: .control, page: 1, index: nil, indexes: [], size: .init(width: 3, height: 1), path: UIControlType.slider.path, id: "volume-control-ver-1", title: "Volume Slider", color: "osascript -e \"output volume of (get volume settings)\"", faviconLink: "slider-icon", browser: nil, imageData: NSImage(named: "slider-icon")?.toData, scriptCode: "osascript -e \"set volume output volume %d\"", utilityType: .commandline, objects: nil, showTitleOnIcon: false, category: "MacOS")),
        .init(
            id: UUID(),
            title: "Volume Knob",
            description: "Control Volume of your MacBook with elegant knob",
            shortcut: .init(type: .control, page: 1, index: nil, indexes: [], size: .init(width: 2, height: 2), path: UIControlType.knob.path, id: "rotary-knob-ver-2", title: "Volume Knob", color: "osascript -e \"output volume of (get volume settings)\"", faviconLink: "knob-icon", browser: nil, imageData: NSImage(named: "knob-icon")?.toData, scriptCode: "osascript -e \"set volume output volume %d\"", utilityType: .commandline, objects: nil, showTitleOnIcon: false, category: "MacOS")
        )
    ]
    
    let installAction: (ShortcutObject) -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text("Select control type")
                    .font(.system(size: 17.0, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding([.horizontal, .top], 16)
                Spacer()
            }
            Divider()
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 350))], spacing: 6) {
                    ForEach(controls) { control in
                        VStack(alignment: .leading) {
                            VStack(alignment: .leading) {
                                HStack(alignment: .top) {
                                    if let imageName = control.shortcut.faviconLink {
                                        Image(imageName)
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .padding(.trailing, 20.0)
                                    }
                                    VStack(alignment: .leading) {
                                        Text(control.title)
                                            .lineLimit(1)
                                            .font(.system(size: 16, weight: .bold))
                                            .padding(.bottom, 4)
                                        Text(control.description)
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundStyle(Color.gray)
                                            .padding(.bottom, 8)
                                    }
                                }
                                Divider()
                                HStack {
                                    Spacer()
                                    ProminentButtonView("Install") {
                                        installAction(control.shortcut)
                                    }
                                }
                            }
                            .padding(.all, 10)
                        }
                        .padding(.all, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                    ComingMoreView()
                        .frame(height: 170.0)
                }
                .padding(.horizontal)
            }
            .padding(.all, 16.0)
        }
        .background(
            RoundedBackgroundView()
        )
        .padding()
    }
}
