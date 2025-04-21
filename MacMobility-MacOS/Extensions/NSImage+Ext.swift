//
//  NSImage+Ext.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 21/04/2025.
//

import AppKit

extension NSImage {
    var toData: Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmap.representation(using: .png, properties: [:])
    }
    
    func resizedImage(newSize: NSSize) -> NSImage {
        guard let bitmapRep = self.representations.first else { return self }

        let originalSize = NSSize(width: bitmapRep.pixelsWide, height: bitmapRep.pixelsHigh)
        let widthRatio = newSize.width / originalSize.width
        let heightRatio = newSize.height / originalSize.height
        let scaleFactor = min(widthRatio, heightRatio)

        let finalSize = NSSize(width: originalSize.width * scaleFactor,
                               height: originalSize.height * scaleFactor)

        let newImage = NSImage(size: finalSize)
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        self.draw(in: NSRect(origin: .zero, size: finalSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .copy,
                  fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}
