//
//  InstallAutomationsView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 29/04/2025.
//

import SwiftUI

struct InstallAutomationsView: View {
    let automationItem: AutomationItem
    let action: () -> Void
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack {
                    if let data = automationItem.imageData, let image = NSImage(data: data)  {
                        Image(nsImage: image)
                            .resizable()
                            .frame(width: 128, height: 128)
                            .cornerRadius(20)
                            .padding(.bottom, 21.0)
                        Button("Open") {
                            action()
                        }
                        .padding(.bottom, 28.0)
                    }
                }
                .padding(.trailing, 21.0)
                VStack(alignment: .leading) {
                    Text(automationItem.title)
                        .font(.system(size: 21, weight: .bold))
                        .padding(.bottom, 4.0)
                        .padding(.top, 16.0)
                    Text(automationItem.description)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.gray)
                        .padding(.bottom, 8.0)
                    
                    Spacer()
                }
                Spacer()
            }
            .padding(.all, 8.0)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }
}

struct UIControlChoiceView: View {
    @State private var selectedMode: String = "prepared"
    private let action: (SetupMode) -> Void
    
    let options: [SetupMode] = [
        SetupMode(title: "Premade UI Controls",
                  description: "Get started quickly with few premade UI Controls",
                  imageName: "sparkles",
                  type: .advanced),
        
        SetupMode(title: "Create Yourself",
                  description: "Choose UI Control type and customize to your liking",
                  imageName: "square.dashed",
                  type: .basic)
    ]
    
    init(_ setupMode: SetupMode?, action: @escaping (SetupMode) -> Void) {
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Text("What would you like to do?")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Choose a UI control type.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 24) {
                ForEach(options.indices, id: \.self) { index in
                    let mode = options[index]
                    let isSelected = (selectedMode == "prepared" && index == 0) || (selectedMode == "blank" && index == 1)
                    
                    VStack(spacing: 12) {
                        Image(systemName: mode.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(isSelected ? .blue : .gray)

                        Text(mode.title)
                            .font(.headline)

                        Text(mode.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                            )
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedMode = (index == 0) ? "prepared" : "blank"
                    }
                }
            }
            Button("Confirm") {
                let index = selectedMode == "prepared" ? 0 : 1
                action(options[index])
            }
        }
        .padding()
    }
}

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
            shortcut: .init(type: .control, page: 1, index: nil, indexes: [], size: .init(width: 3, height: 1), path: "control:horizontal-slider", id: "volume-control-ver-1", title: "Volume Control", color: nil, faviconLink: nil, browser: nil, imageData: nil, scriptCode: "osascript -e \"set volume output volume %d\"", utilityType: .commandline, objects: nil, showTitleOnIcon: false, category: "MacOS")),
        .init(
            id: UUID(),
            title: "Volume Knob",
            description: "Control Volume of your MacBook with elegant knob",
            shortcut: .init(type: .control, page: 1, index: nil, indexes: [], size: .init(width: 2, height: 2), path: "control:rotary-knob", id: "rotary-knob-ver-2", title: "Rotary Zoom", color: nil, faviconLink: nil, browser: nil, imageData: nil, scriptCode: "", utilityType: .automation, objects: nil, showTitleOnIcon: false, category: "MacOS")
        )
    ]
    
    let installAction: (ShortcutObject) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 400))], spacing: 6) {
                ForEach(controls) { control in
                    HStack(alignment: .top) {
                        Image(systemName: "switch.2")
                            .resizable()
                            .frame(width: 30.0, height: 30.0)
                            .padding(.trailing, 20.0)
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
