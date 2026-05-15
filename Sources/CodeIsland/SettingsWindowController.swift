import AppKit
import SwiftUI

@MainActor
class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?
    weak var appState: AppState?

    private var closeObserver: NSObjectProtocol?

    private func clearCloseObserver() {
        if let closeObserver {
            NotificationCenter.default.removeObserver(closeObserver)
            self.closeObserver = nil
        }
    }

    func show() {
        // Switch to regular activation policy so the window can receive focus
        NSApp.setActivationPolicy(.regular)
        // Use the actual bundle app icon so Dock matches the packaged asset catalog icon.
        NSApp.applicationIconImage = Self.bundleAppIcon()

        if let window = window {
            bringToFront(window)
            return
        }

        let settingsView = SettingsView(appState: appState)
        let hostingView = NSHostingView(rootView: settingsView)

        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenW = screen?.frame.width ?? 1440
        let screenH = screen?.frame.height ?? 900
        let winW = min(660, screenW * 0.5)
        let winH = min(540, screenH * 0.6)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: winW, height: winH),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .visible
        window.title = L10n.shared["settings_title"]
        window.backgroundColor = .windowBackgroundColor
        window.contentView = hostingView
        window.contentMinSize = NSSize(width: min(560, screenW * 0.4), height: min(420, screenH * 0.4))
        window.collectionBehavior.insert(.moveToActiveSpace)
        window.toolbar = nil
        window.center()
        window.isReleasedWhenClosed = false
        bringToFront(window)

        // Revert to accessory policy after close without hiding the entire app.
        // Hiding here causes the panel to blink even though only the settings
        // window is being dismissed.
        clearCloseObserver()
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: window, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.window = nil
                self?.clearCloseObserver()
                DispatchQueue.main.async {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }

        self.window = window
    }

    private func bringToFront(_ window: NSWindow) {
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        window.collectionBehavior.insert(.moveToActiveSpace)
        window.orderFrontRegardless()
        NSRunningApplication.current.activate(options: [.activateAllWindows])
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        // Re-assert on the next run-loop turn. Changing an accessory app to
        // regular activation can lag behind the first order-front request,
        // especially when opening settings from the non-activating panel.
        DispatchQueue.main.async { [weak window] in
            guard let window else { return }
            window.orderFrontRegardless()
            NSRunningApplication.current.activate(options: [.activateAllWindows])
            window.makeKeyAndOrderFront(nil)
        }
    }

    static func bundleAppIcon() -> NSImage {
        let image = NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        image.size = NSSize(width: 256, height: 256)
        return image
    }
}
