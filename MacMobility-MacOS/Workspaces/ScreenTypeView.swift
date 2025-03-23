//
//  ScreenTypeView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 06/03/2025.
//

import Foundation
import SwiftUI

struct ScreenTypeContainer: Identifiable, Codable {
    let id: Int
    let size: CGSize?
    let position: CGPoint?
    let app: AppInfo?
    
    init(id: Int, size: CGSize? = nil, position: CGPoint? = nil, app: AppInfo? = nil) {
        self.id = id
        self.size = size
        self.position = position
        self.app = app
    }
}

struct ScreenTypeView: View {
    let id: String
    let screenType: ConfigurableScreenType
    let size: ConfigurableScreenTypeSize
    let addAction: ([ScreenTypeContainer]) -> Void
    var removeAction: ((String) -> Void)?
    @State var apps: [ScreenTypeContainer]
    
    var screenSize: CGSize {
        guard let test = getFrameOfScreen() else {
            return .zero
        }
        switch screenType {
        case .singleScreen:
            return .init(width: test.width, height: test.height)
        case .splitScreenHorizontal:
            return .init(width: test.width / 2, height: test.height)
        }
    }
    
    init(
        id: String,
        screenType: ConfigurableScreenType,
        size: ConfigurableScreenTypeSize,
        apps: [ScreenTypeContainer]?,
        removeAction: ((String) -> Void)? = nil,
        addAction: @escaping ([ScreenTypeContainer]) -> Void
    ) {
        self.id = id
        self.removeAction = removeAction
        self.apps = apps ?? [.init(id: 0), .init(id: 1)]
        self.screenType = screenType
        self.size = size
        self.addAction = addAction
    }
    
    var body: some View {
        VStack {
            switch screenType {
            case .singleScreen:
                cell(index: 0)
            case .splitScreenHorizontal:
                HStack {
                    cell(index: 0)
                    cell(index: 1)
                }
            }
            if let removeAction {
                Button("Delete") {
                    removeAction(id)
                }
            }
        }
    }
    
    func getFrameOfScreen() -> NSRect? {
        if let window = NSApplication.shared.mainWindow {
            if let screen = window.screen {
                let screenFrame = screen.frame
                return screenFrame
            }
        }
        return nil
    }
    
    func cell(index: Int) -> some View {
        VStack {
            if let path = apps[safe: index]?.app?.path {
                ZStack {
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .stroke(Color.gray, lineWidth: size.lineWidth)
                        .padding(.all, size.padding)
                    Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                        .resizable()
                        .frame(width: 32, height: 32)
                        .cornerRadius(6)
                        .onDrag {
                            NSItemProvider(object: path as NSString)
                        }
                }
            } else {
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: size.cornerRadius)
                            .stroke(Color.gray, lineWidth: size.lineWidth)
                            .padding(.all, size.padding)
                        if size == .medium {
                            Text("Drop app here")
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(Color.black)
                )
            }
        }
        .onDrop(of: [.text], isTargeted: nil) { providers in
            providers.first?.loadObject(ofClass: NSString.self) { (droppedItem, _) in
                if let droppedString = droppedItem as? String {
                    DispatchQueue.main.async {
                        if apps[safe: index]?.app?.path != createAppFromPath(droppedString).path {
                            apps.enumerated().forEach { (index, app) in
                                if app.app?.path == createAppFromPath(droppedString).path {
                                    apps[index] = .init(id: index)
                                }
                            }
                            let position: CGPoint = index == 0 ? .init(x: 0, y: 0) : .init(x: screenSize.width, y: 0)
                            apps[index] = .init(id: index, size: screenSize, position: position, app: createAppFromPath(droppedString))
                            addAction(apps)
                        }
                    }
                }
            }
            return true
        }
    }
    
    func createAppFromPath(_ path: String) -> AppInfo {
        let appName = URL(string: path)?.deletingPathExtension().lastPathComponent ?? ""
        return .init(id: UUID().uuidString, name: appName, path: path)
    }
}
