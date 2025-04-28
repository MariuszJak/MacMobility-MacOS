//
//  AppleScriptCommandable.swift
//  MacMobility
//
//  Created by CoderBlocks on 22/07/2023.
//

import Foundation
import AppKit
import os

protocol AppleScriptCommandable {
    func execute(_ scriptString: String, completion: ((NSDictionary) -> Void)?)
}

extension AppleScriptCommandable {
    func execute(_ scriptString: String, completion: ((NSDictionary) -> Void)? = nil) {
        DispatchQueue.main.async {
            guard let script = NSAppleScript(source: scriptString) else {
                return
            }
            var errorInfo: NSDictionary?
            script.executeAndReturnError(&errorInfo)
            if let error = errorInfo {
                completion?(error)
            }
        }
    }
}
