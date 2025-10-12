//
//  TrackerService.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 12/10/2025.
//

import Foundation
import SwiftUI
import AppKit
import ObjectiveC

public typealias CoreObserverAdditions = [String: String]
public typealias CoreObserverAction = (EventClass) async -> Void

public struct EventClass: Codable {
    public let event: CoreObserver.Event
    public let additions: CoreObserverAdditions
    
    public init(event: CoreObserver.Event, additions: CoreObserverAdditions) {
        self.event = event
        self.additions = additions
    }
}

public protocol CoreObserverProtocol {
    func submit(event: CoreObserver.Event, additions: CoreObserverAdditions)
    func subscribe(_ subscriber: AnyHashable, _ completion: @escaping CoreObserverAction)
    func unsubscribe(_ subscriber: AnyHashable)
}

public class CoreObserver: CoreObserverProtocol {
    private var subscribers: [AnyHashable: CoreObserverAction] = [:]
    
    public init() {
        NSWindow.swizzleMakeKeyAndOrderFront
    }
    
    public enum Event: String, Codable {
        case screen
        case action
    }
    
    public func submit(event: Event, additions: CoreObserverAdditions) {
        for subscriber in subscribers.values {
            Task {
                await subscriber(.init(event: event, additions: additions))
            }
        }
    }
    
    public func subscribe(_ subscriber: AnyHashable, _ completion: @escaping CoreObserverAction) {
        subscribers[subscriber] = completion
    }
    
    public func unsubscribe(_ subscriber: AnyHashable) {
        subscribers[subscriber] = nil
    }
}

public extension NSWindow {
    static let swizzleMakeKeyAndOrderFront: Void = {
        let originalSelector = #selector(NSWindow.makeKeyAndOrderFront(_:))
        let swizzledSelector = #selector(swizzled_makeKeyAndOrderFront(_:))

        guard let originalMethod = class_getInstanceMethod(NSWindow.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(NSWindow.self, swizzledSelector) else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()

    @objc private func swizzled_makeKeyAndOrderFront(_ sender: Any?) {
        // Call original implementation
        self.swizzled_makeKeyAndOrderFront(sender)
        Resolver.resolve(CoreObserverProtocol.self).submit(event: .screen, additions: ["WindowAppear": self.title])
    }
}
