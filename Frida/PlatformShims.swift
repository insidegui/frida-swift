import Foundation

// MARK: - Type Aliases

#if os(iOS)
@_exported import UIKit

public typealias FridaPlatformImage = UIImage
public typealias NSSize = CGSize
#else
@_exported import Cocoa

public typealias FridaPlatformImage = NSImage
#endif

// MARK: - Compatibility Extensions

#if os(iOS)

public extension FridaPlatformImage {
    convenience init?(cgImage: CGImage, size: NSSize) {
        self.init(cgImage: cgImage)
    }
}

#endif
