//
//  Resolver.swift
//  CoreResolver
//
//  Created by CoderBlocks on 09/09/2024.
//

import Foundation

@propertyWrapper
public struct Inject<T> {
    public var wrappedValue: T

    public init(resolver: Resolver = Resolver.shared) {
        self.wrappedValue = resolver.resolve()
    }
}

@propertyWrapper
public struct LazyInject<T> {
    public lazy var wrappedValue: T = Resolver.resolve()

    public init() {}
}

public class Resolver {
    fileprivate var dependencies = [String: AnyObject]()
    fileprivate var locked = [String]()
    public static var shared = Resolver()
    
    public enum Access {
        /// Every attempt to register a class will succeed, overriding the previous registrations
        /// This is default access.
        case unlocked
        /// Any future attempt of registering of class of this type will fail.
        case locked
    }

    public func register<T>(_ dependency: T) {
        let key = String(reflecting: T.self)
        dependencies[key] = dependency as AnyObject
    }

    public func resolve<T>() -> T {
        let key = String(reflecting: T.self)
        let dependency = dependencies[key] as? T

        guard let dependency = dependency else { fatalError("No \(key) dependency found!") }
        return dependency
    }
    
    public static func register<T>(_ dependency: T, _ access: Access = .unlocked) {
        let key = String(reflecting: T.self)
        guard !Resolver.shared.locked.contains(key) else { return }
        Resolver.shared.dependencies[key] = dependency as AnyObject
        if access == .locked {
            Resolver.shared.locked.append(key)
        }
    }
    
    public static func resolve<T>() -> T {
        let key = String(reflecting: T.self)
        let dependency = Resolver.shared.dependencies[key] as? T

        guard let dependency = dependency else { fatalError("No \(key) dependency found!") }
        return dependency
    }
    
    public static func resolve<T>(_ depenedency: T.Type) -> T {
        let key = String(reflecting: T.self)
        let dependency = Resolver.shared.dependencies[key] as? T

        guard let dependency = dependency else { fatalError("No \(key) dependency found!") }
        return dependency
    }
    
    public static func update<T>(_ dependency: T.Type, _ method: (inout T) -> T) {
        let key = String(reflecting: T.self)
        let dependency = Resolver.shared.dependencies[key] as? T
        guard var dependency = dependency else { fatalError("No \(key) dependency found!") }
        let updated: T = method(&dependency)
        Resolver.register(updated)
    }
    
    public static func update<T: Routable>(_ method: (inout T) -> T) {
        Resolver.update(T.self, method)
    }
}

public protocol Routable {
    associatedtype T
    var router: T { get }
}

public protocol UpdatableConfiguration {
    static func update<T: Routable>(_ method: (inout T) -> T)
}

public extension UpdatableConfiguration {
    static func update<T: Routable>(_ method: (inout T) -> T) {
        Resolver.update(T.self, method)
    }
}
