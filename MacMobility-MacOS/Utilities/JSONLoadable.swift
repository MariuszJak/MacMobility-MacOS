//
//  JSONLoadable.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 29/04/2025.
//

import Foundation

protocol JSONLoadable {
    func loadJSON<T: Decodable>(_ filename: String) -> T
}

extension JSONLoadable {
    func loadJSON<T: Decodable>(_ filename: String) -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            fatalError("Failed to locate \(filename).json in bundle.")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(filename).json from bundle.")
        }

        let decoder = JSONDecoder()
        guard let loaded = try? decoder.decode(T.self, from: data) else {
            fatalError("Failed to decode \(filename).json from bundle.")
        }

        return loaded
    }
}

protocol ImageLoadable {
    func loadImage(named name: String) -> NSImage?
}

extension ImageLoadable {
    func loadImage(named name: String) -> NSImage? {
        if let fromAssets = NSImage(named: name) { return fromAssets }
        if let url = Bundle.main.url(forResource: name, withExtension: nil, subdirectory: "Icons") {
            return NSImage(contentsOf: url)
        }
        return nil
    }
}
