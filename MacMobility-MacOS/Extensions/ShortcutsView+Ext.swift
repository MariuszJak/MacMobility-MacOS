//
//  ShortcutsView+Ext.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 23/08/2025.
//

import Foundation
import SwiftUI

extension ShortcutsView {
    @ViewBuilder
    func mainItemView(index: Int, page: Int) -> some View {
        VStack {
            ZStack(alignment: .topLeading) {
                itemViews(for: index, page: page, size:
                        .init(
                            width: 70 * (viewModel.objectAt(index: index, page: page)?.size?.width ?? 1)
                            + testSize * (viewModel.objectAt(index: index, page: page)?.size?.width ?? 1),
                            height: 70 * (viewModel.objectAt(index: index, page: page)?.size?.height ?? 1)
                            + testSize * (viewModel.objectAt(index: index, page: page)?.size?.height ?? 1)
                        ))
                .frame(width: 70 * (viewModel.objectAt(index: index, page: page)?.size?.width ?? 1)
                       + testSize * (viewModel.objectAt(index: index, page: page)?.size?.width ?? 1),
                       height: 70 * (viewModel.objectAt(index: index, page: page)?.size?.height ?? 1)
                       + testSize * (viewModel.objectAt(index: index, page: page)?.size?.height ?? 1))
                .onDrop(of: [.text], isTargeted: nil) { providers in
                    providers.first?.loadObject(ofClass: NSString.self) { (droppedItem, _) in
                        if let droppedString = droppedItem as? String,
                           let object = viewModel.object(for: droppedString, index: index, page: page) {
                            handleOnDrop(index: index, page: page, object: object)
                        }
                    }
                    return true
                }
                .if((viewModel.objectAt(index: index, page: page)?.size?.width ?? 0) > 1) {
                    $0.padding(.leading, ((70 + testSize) * ((viewModel.objectAt(index: index, page: page)?.size?.width ?? 1) - 1) + testSize))
                }
                .if((viewModel.objectAt(index: index, page: page)?.size?.height ?? 0) > 1) {
                    $0.padding(.top, (70 + testSize) * ((viewModel.objectAt(index: index, page: page)?.size?.height ?? 1) - 1))
                }
                .clipped()
                .ifLet(viewModel.objectAt(index: index, page: page)) { view, object in
                    dragView(view, object: object)
                }
                .if(viewModel.objectAt(index: index, page: page) != nil && viewModel.draggingData.size != nil) {
                    $0.overlay(
                        plusView(index: index, page: page)
                            .opacity(0.01)
                    )
                }
                .if(viewModel.objectAt(index: index, page: page) != nil && viewModel.draggingData.size == nil) {
                    $0.overlay(
                        EmptyView()
                    )
                }
                if let id = viewModel.objectAt(index: index, page: page)?.id {
                    VStack {
                        HStack {
                            Spacer()
                            RedXButton {
                                viewModel.removeShortcut(id: id, page: page)
                            }
                        }
                        Spacer()
                    }
                    .if((viewModel.objectAt(index: index, page: page)?.size?.width ?? 0) > 1) {
                        $0.padding(.leading, ((70 + testSize) * ((viewModel.objectAt(index: index, page: page)?.size?.width ?? 1) - 1) + testSize))
                    }
                    .if((viewModel.objectAt(index: index, page: page)?.size?.height ?? 0) > 1) {
                        $0.padding(.top, (70 + testSize) * ((viewModel.objectAt(index: index, page: page)?.size?.height ?? 1) - 1))
                    }
                }

            }
        }
    }
    
    func openCreateNewWebpageWindow(item: ShortcutObject? = nil) {
        if nil == newWindow {
            newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 550),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            newWindow?.center()
            newWindow?.setFrameAutosaveName("Webpages")
            newWindow?.isReleasedWhenClosed = false
            newWindow?.titlebarAppearsTransparent = true
            newWindow?.appearance = NSAppearance(named: .darkAqua)
            newWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: newWindow) else {
                return
            }
            newWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: NewWebpageView(item: item, delegate: viewModel))
            viewModel.close = {
                tab = .webpages
                newWindow?.close()
            }
            newWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = newWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            newWindow?.makeKeyAndOrderFront(nil)
            return
        }
        newWindow?.contentView?.subviews.forEach { $0.removeFromSuperview() }
        let hv = NSHostingController(rootView: NewWebpageView(item: item, delegate: viewModel))
        viewModel.close = {
            newWindow?.close()
        }
        newWindow?.contentView?.addSubview(hv.view)
        hv.view.frame = newWindow?.contentView?.bounds ?? .zero
        hv.view.autoresizingMask = [.width, .height]
        newWindow?.makeKeyAndOrderFront(nil)
    }
    
    func openCompanionAppWindow() {
        if nil == newWindow {
            companionAppWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 550),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            companionAppWindow?.center()
            companionAppWindow?.setFrameAutosaveName("Webpages")
            companionAppWindow?.isReleasedWhenClosed = false
            companionAppWindow?.titlebarAppearsTransparent = true
            companionAppWindow?.appearance = NSAppearance(named: .darkAqua)
            companionAppWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: companionAppWindow) else {
                return
            }
            companionAppWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: CompanionAppView())
            companionAppWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = companionAppWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            companionAppWindow?.makeKeyAndOrderFront(nil)
            return
        }
        companionAppWindow?.contentView?.subviews.forEach { $0.removeFromSuperview() }
        let hv = NSHostingController(rootView: CompanionAppView())
        companionAppWindow?.contentView?.addSubview(hv.view)
        hv.view.frame = companionAppWindow?.contentView?.bounds ?? .zero
        hv.view.autoresizingMask = [.width, .height]
        companionAppWindow?.makeKeyAndOrderFront(nil)
    }
    
    func openUIControlAppWindow() {
        uiControlAppWindow?.close()
        uiControlAppWindow = nil
        if nil == uiControlAppWindow {
            uiControlAppWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 350),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            uiControlAppWindow?.center()
            uiControlAppWindow?.setFrameAutosaveName("UIControl")
            uiControlAppWindow?.isReleasedWhenClosed = false
            uiControlAppWindow?.titlebarAppearsTransparent = true
            uiControlAppWindow?.appearance = NSAppearance(named: .darkAqua)
            uiControlAppWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: uiControlAppWindow) else {
                return
            }
            uiControlAppWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: UIControlChoiceView(nil, action: { mode in
                switch mode.type {
                case .advanced:
                    openCreateUIControlListAppWindow()
                case .basic:
                    openUIControlListAppWindow()
                }
                uiControlAppWindow?.close()
            }))
            uiControlAppWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = uiControlAppWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            uiControlAppWindow?.makeKeyAndOrderFront(nil)
            return
        }
    }
    
    func openUIControlListAppWindow() {
        uiControlListAppWindow?.close()
        uiControlListAppWindow = nil
        if nil == uiControlListAppWindow {
            uiControlListAppWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 850, height: 550),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            uiControlListAppWindow?.center()
            uiControlListAppWindow?.setFrameAutosaveName("UIControlList")
            uiControlListAppWindow?.isReleasedWhenClosed = false
            uiControlListAppWindow?.titlebarAppearsTransparent = true
            uiControlListAppWindow?.appearance = NSAppearance(named: .darkAqua)
            uiControlListAppWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: uiControlListAppWindow) else {
                return
            }
            uiControlListAppWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: UIControlsListView(installAction: { object in
                uiControlListAppWindow?.close()
                tab = .utilities
                if let category = object.category {
                    viewModel.expandSectionIfNeeded(for: category)
                }
                viewModel.saveUtility(with: object)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.scrollToApp = object.title
                }
            }))
            uiControlListAppWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = uiControlListAppWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            uiControlListAppWindow?.makeKeyAndOrderFront(nil)
            return
        }
    }
    
    func openCreateUIControlListAppWindow() {
        uiControlListAppWindow?.close()
        uiControlListAppWindow = nil
        if nil == uiControlListAppWindow {
            uiControlListAppWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 850, height: 550),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            uiControlListAppWindow?.center()
            uiControlListAppWindow?.setFrameAutosaveName("UICreateControlList")
            uiControlListAppWindow?.isReleasedWhenClosed = false
            uiControlListAppWindow?.titlebarAppearsTransparent = true
            uiControlListAppWindow?.appearance = NSAppearance(named: .darkAqua)
            uiControlListAppWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: uiControlListAppWindow) else {
                return
            }
            uiControlListAppWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: UIControlCreateListView(createAction: { type in
                uiControlListAppWindow?.close()
                openCreateUIControlWindow(type: type)
            }))
            uiControlListAppWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = uiControlListAppWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            uiControlListAppWindow?.makeKeyAndOrderFront(nil)
            return
        }
    }
    
    func openInstallAutomationsWindow() {
        if nil == automationsToInstallWindow {
            automationsToInstallWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1100, height: 700),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            automationsToInstallWindow?.center()
            automationsToInstallWindow?.setFrameAutosaveName("AutomationsToInstallWindow")
            automationsToInstallWindow?.isReleasedWhenClosed = false
            automationsToInstallWindow?.titlebarAppearsTransparent = true
            automationsToInstallWindow?.appearance = NSAppearance(named: .darkAqua)
            automationsToInstallWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: automationsToInstallWindow) else {
                return
            }
            automationsToInstallWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: ExploreAutomationsView(openDetailsPage: { item in
                openAutomationItemWindow(item)
            }))
            automationsToInstallWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = automationsToInstallWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            automationsToInstallWindow?.makeKeyAndOrderFront(nil)
            return
        }
        automationsToInstallWindow?.makeKeyAndOrderFront(nil)
    }
    
    func openIconsPickerWindow() {
        iconPickerWindow?.close()
        iconPickerWindow = nil
        if nil == iconPickerWindow {
            iconPickerWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            iconPickerWindow?.center()
            iconPickerWindow?.setFrameAutosaveName("IconPickerWindow")
            iconPickerWindow?.isReleasedWhenClosed = false
            iconPickerWindow?.titlebarAppearsTransparent = true
            iconPickerWindow?.appearance = NSAppearance(named: .darkAqua)
            iconPickerWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: iconPickerWindow) else {
                return
            }
            iconPickerWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: IconSelectorView(action: { name in
                iconPickerWindow?.close()
                print(name)
            }))
            iconPickerWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = iconPickerWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            iconPickerWindow?.makeKeyAndOrderFront(nil)
            return
        }
        iconPickerWindow?.makeKeyAndOrderFront(nil)
    }
    
    func openCreateUIControlWindow(type: UIControlType) {
        uiControlCreateWindow?.close()
        uiControlCreateWindow = nil
        if nil == uiControlCreateWindow {
            uiControlCreateWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 850, height: 700),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            uiControlCreateWindow?.center()
            uiControlCreateWindow?.setFrameAutosaveName("UIControlCreateWindow")
            uiControlCreateWindow?.isReleasedWhenClosed = false
            uiControlCreateWindow?.titlebarAppearsTransparent = true
            uiControlCreateWindow?.appearance = NSAppearance(named: .darkAqua)
            uiControlCreateWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: uiControlCreateWindow) else {
                return
            }
            
            uiControlCreateWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: UIControlCreateView(
                type: type,
                connectionManager: viewModel.connectionManager,
                categories: viewModel.allCategories(),
                delegate: viewModel,
                closeAction: { object in
                    uiControlCreateWindow?.close()
                    guard let object else { return }
                    tab = .utilities
                    if let category = object.category {
                        viewModel.expandSectionIfNeeded(for: category)
                    }
                    viewModel.saveUtility(with: object)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.scrollToApp = object.title
                    }
                }, testAction: { payload in
                    openCreateUIControlTestWindow(payload: payload)
                }
            ))
            uiControlCreateWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = uiControlCreateWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        uiControlCreateWindow?.makeKeyAndOrderFront(nil)
    }
    
    func openCreateUIControlTestWindow(payload: UIControlPayload) {
        uiControlCreateTestWindow?.close()
        uiControlCreateTestWindow = nil
        if nil == uiControlCreateTestWindow {
            uiControlCreateTestWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: payload.type.size.width * 120, height: payload.type.size.height * 120),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            uiControlCreateTestWindow?.center()
            uiControlCreateTestWindow?.setFrameAutosaveName("UIControlCreateTestWindow")
            uiControlCreateTestWindow?.isReleasedWhenClosed = false
            uiControlCreateTestWindow?.titlebarAppearsTransparent = true
            uiControlCreateTestWindow?.appearance = NSAppearance(named: .darkAqua)
            uiControlCreateTestWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: uiControlCreateTestWindow) else {
                return
            }
            
            uiControlCreateTestWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: UIControlTestView(
                payload: payload,
                connectionManager: viewModel.connectionManager
            ))
            uiControlCreateTestWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = uiControlCreateTestWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        uiControlCreateTestWindow?.makeKeyAndOrderFront(nil)
    }
    
    func openCreateNewUtilityWindow() {
        newUtilityWindow?.close()
        newUtilityWindow = nil
        if nil == newUtilityWindow {
            newUtilityWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1150, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            newUtilityWindow?.center()
            newUtilityWindow?.setFrameAutosaveName("NewUtility")
            newUtilityWindow?.isReleasedWhenClosed = false
            newUtilityWindow?.titlebarAppearsTransparent = true
            newUtilityWindow?.appearance = NSAppearance(named: .darkAqua)
            newUtilityWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: newUtilityWindow) else {
                return
            }
            
            newUtilityWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: SelectUtilityTypeWindowView(
                connectionManager: viewModel.connectionManager,
                categories: viewModel.allCategories(),
                delegate: viewModel,
                closeAction: {
                    newUtilityWindow?.close()
                }))
            newUtilityWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = newUtilityWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        newUtilityWindow?.makeKeyAndOrderFront(nil)
    }
    
    func openQuickActionWindow() {
        quickActionSetupWindow?.close()
        quickActionSetupWindow = nil
        if nil == quickActionSetupWindow {
            quickActionSetupWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            quickActionSetupWindow?.center()
            quickActionSetupWindow?.setFrameAutosaveName("QuickActionSetupWindow")
            quickActionSetupWindow?.isReleasedWhenClosed = false
            quickActionSetupWindow?.titlebarAppearsTransparent = true
            quickActionSetupWindow?.appearance = NSAppearance(named: .darkAqua)
            quickActionSetupWindow?.styleMask.insert(.fullSizeContentView)
            quickActionSetupWindow?.level = .floating
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: quickActionSetupWindow) else {
                return
            }
            
            quickActionSetupWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: QuicActionMenuSetupView(
                setupViewModel: .init(
                    items: viewModel.quickActionItems,
                    allItems: viewModel.allObjects()),
                action: { items, shouldClose in
                    if let items {
                        viewModel.saveQuickActionItems(items)
                    }
                    if shouldClose {
                        quickActionSetupWindow?.close()
                    }
                })
            )
            quickActionSetupWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = quickActionSetupWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        quickActionSetupWindow?.makeKeyAndOrderFront(nil)
    }
    
    func openAutomationItemWindow(_ item: AutomationItem) {
        automationItemWindow?.close()
        automationItemWindow = nil
        if nil == automationItemWindow {
            automationItemWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 700),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            automationItemWindow?.center()
            automationItemWindow?.setFrameAutosaveName("AutomationsToInstallWindow")
            automationItemWindow?.isReleasedWhenClosed = false
            automationItemWindow?.titlebarAppearsTransparent = true
            automationItemWindow?.appearance = NSAppearance(named: .darkAqua)
            automationItemWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: automationItemWindow) else {
                return
            }
            automationItemWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: AutomationInstallView(automationItem: item, selectedScriptsAction: { scripts in
                viewModel.addAutomations(from: scripts)
                automationItemWindow?.close()
                tab = .utilities
            }, close: {
                automationItemWindow?.close()
            }))
            automationItemWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = automationItemWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            automationItemWindow?.makeKeyAndOrderFront(nil)
            return
        }
    }
    
    func openEditUtilityWindow(item: ShortcutObject) {
        editUtilitiesWindow?.close()
        editUtilitiesWindow = nil
        if nil == editUtilitiesWindow {
            if item.color == .convert {
                editUtilitiesWindow = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 520, height: 300),
                    styleMask: [.titled, .closable, .miniaturizable],
                    backing: .buffered,
                    defer: false
                )
            } else {
                editUtilitiesWindow = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 520, height: 470),
                    styleMask: item.utilityType == .commandline || item.utilityType == .automation || item.utilityType == .html ? [.titled, .closable, .resizable, .miniaturizable] : [.titled, .closable, .miniaturizable],
                    backing: .buffered,
                    defer: false
                )
            }
            editUtilitiesWindow?.center()
            editUtilitiesWindow?.setFrameAutosaveName("Utilities")
            editUtilitiesWindow?.isReleasedWhenClosed = false
            editUtilitiesWindow?.titlebarAppearsTransparent = true
            editUtilitiesWindow?.appearance = NSAppearance(named: .darkAqua)
            editUtilitiesWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: editUtilitiesWindow) else {
                return
            }
            
            editUtilitiesWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            switch item.utilityType {
            case .commandline:
                if item.color == .convert {
                    let hv = NSHostingController(rootView: ConverterView(item: item, delegate: viewModel){
                        editUtilitiesWindow?.close()
                    })
                    editUtilitiesWindow?.contentView?.addSubview(hv.view)
                    hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
                    hv.view.autoresizingMask = [.width, .height]
                } else if item.color == .raycast {
                    let hv = NSHostingController(rootView: RaycastUtilityView(item: item, delegate: viewModel){
                        editUtilitiesWindow?.close()
                    })
                    editUtilitiesWindow?.contentView?.addSubview(hv.view)
                    hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
                    hv.view.autoresizingMask = [.width, .height]
                } else {
                    let hv = NSHostingController(rootView: NewBashUtilityView(categories: viewModel.allCategories(), item: item, delegate: viewModel) {
                        editUtilitiesWindow?.close()
                    })
                    editUtilitiesWindow?.contentView?.addSubview(hv.view)
                    hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
                    hv.view.autoresizingMask = [.width, .height]
                }
            case .html:
                let hv = NSHostingController(rootView: HTMLUtilityView(categories: viewModel.allCategories(), item: item, delegate: viewModel) {
                    editUtilitiesWindow?.close()
                })
                editUtilitiesWindow?.contentView?.addSubview(hv.view)
                hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
                hv.view.autoresizingMask = [.width, .height]
            case .multiselection:
                let hv = NSHostingController(rootView: NewMultiSelectionUtilityView(item: item, delegate: viewModel) {
                    editUtilitiesWindow?.close()
                })
                editUtilitiesWindow?.contentView?.addSubview(hv.view)
                hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
                hv.view.autoresizingMask = [.width, .height]
            case .automation:
                let hv = NSHostingController(rootView: NewAutomationUtilityView(categories: viewModel.allCategories(), showsSizePicker: false, item: item, delegate: viewModel) {
                    editUtilitiesWindow?.close()
                })
                editUtilitiesWindow?.contentView?.addSubview(hv.view)
                hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
                hv.view.autoresizingMask = [.width, .height]
            case .macro:
                let hv = NSHostingController(rootView: MacroRecorderView(item: item, delegate: viewModel){
                    editUtilitiesWindow?.close()
                })
                editUtilitiesWindow?.contentView?.addSubview(hv.view)
                hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
                hv.view.autoresizingMask = [.width, .height]
            case .none:
                break
            }
            editUtilitiesWindow?.makeKeyAndOrderFront(nil)
            return
        }
    }
}
