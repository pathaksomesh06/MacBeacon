@_exported import SwiftUI
@_exported import Combine

import AppKit

class WindowDelegate: NSObject, NSWindowDelegate {
    func windowWillEnterFullScreen(_ notification: Notification) {
        // Prevent entering full-screen mode
        if let window = notification.object as? NSWindow {
            window.toggleFullScreen(nil)
        }
    }
    
    func windowDidResize(_ notification: Notification) {
        // Ensure window doesn't get too large
        if let window = notification.object as? NSWindow {
            let maxWidth: CGFloat = 1600
            let maxHeight: CGFloat = 1000
            
            if window.frame.width > maxWidth || window.frame.height > maxHeight {
                var newFrame = window.frame
                newFrame.size.width = min(newFrame.width, maxWidth)
                newFrame.size.height = min(newFrame.height, maxHeight)
                window.setFrame(newFrame, display: true)
            }
        }
    }
    
    func windowWillMove(_ notification: Notification) {
        // Ensure window stays above dock
        if let window = notification.object as? NSWindow {
            let screen = NSScreen.main ?? NSScreen.screens.first
            if let screen = screen {
                let dockHeight: CGFloat = 80 // Approximate dock height
                let maxY = screen.frame.maxY - dockHeight
                
                if window.frame.maxY > maxY {
                    var newFrame = window.frame
                    newFrame.origin.y = maxY - newFrame.height
                    window.setFrame(newFrame, display: true)
                }
            }
        }
    }
}

@main
struct MacBeaconApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ModernSecurityDashboard()
                .frame(minWidth: 1200, idealWidth: 1400, minHeight: 800, idealHeight: 900)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1400, height: 900)
        .windowResizability(.contentSize)
        .commands {
            // Remove full-screen command to prevent accidental full-screen
            CommandGroup(replacing: .windowSize) { }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowDelegate = WindowDelegate()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set window delegate for all windows
        if let window = NSApplication.shared.windows.first {
            window.delegate = windowDelegate
            window.collectionBehavior = [.managed, .fullScreenNone]
            
            // Ensure window stays above dock
            let screen = NSScreen.main ?? NSScreen.screens.first
            if let screen = screen {
                let dockHeight: CGFloat = 80
                let maxY = screen.frame.maxY - dockHeight
                
                if window.frame.maxY > maxY {
                    var newFrame = window.frame
                    newFrame.origin.y = maxY - newFrame.height
                    window.setFrame(newFrame, display: true)
                }
            }
        }
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Ensure no windows are in full-screen mode
        for window in NSApplication.shared.windows {
            if window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        }
    }
}

