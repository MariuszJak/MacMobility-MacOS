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
            shortcut: .init(type: .control, page: 1, index: nil, indexes: [], size: .init(width: 3, height: 1), path: "control:horizontal-slider", id: "volume-control-ver-1", title: "Volume Control", color: nil, faviconLink: "slider-icon", browser: nil, imageData: NSImage(named: "slider-icon")?.toData, scriptCode: "osascript -e \"set volume output volume %d\"", utilityType: .commandline, objects: nil, showTitleOnIcon: false, category: "MacOS")),
        .init(
            id: UUID(),
            title: "Volume Knob",
            description: "Control Volume of your MacBook with elegant knob",
            shortcut: .init(type: .control, page: 1, index: nil, indexes: [], size: .init(width: 2, height: 2), path: "control:rotary-knob", id: "rotary-knob-ver-2", title: "Rotary Zoom", color: nil, faviconLink: "knob-icon", browser: nil, imageData: NSImage(named: "knob-icon")?.toData, scriptCode: "", utilityType: .automation, objects: nil, showTitleOnIcon: false, category: "MacOS")
        )
    ]
    
    let installAction: (ShortcutObject) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 400))], spacing: 6) {
                ForEach(controls) { control in
                    HStack(alignment: .top) {
                        if let imageName = control.shortcut.faviconLink {
                            Image(imageName)
                                .resizable()
                                .frame(width: 80.0, height: 80.0)
                                .padding(.trailing, 20.0)
                        }
                        VStack(alignment: .leading) {
                            Text(control.title)
                                .font(.title2)
                                .padding(.bottom, 6.0)
                            Text(control.description)
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                                .padding(.bottom, 8.0)
                            
                        }
                        Spacer()
                        Button("Install") {
                            installAction(control.shortcut)
                        }
                        .padding()
                    }
                    .padding(.all, 18.0)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
            }
            .padding()
        }
        .background(
            RoundedBackgroundView()
        )
        .padding(.all, 16.0)
    }
}
