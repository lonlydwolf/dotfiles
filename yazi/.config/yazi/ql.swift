import Cocoa
import Quartz

class AppDelegate: NSObject, NSApplicationDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    let path: String
    
    init(path: String) {
        self.path = path
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let panel = QLPreviewPanel.shared() {
            panel.dataSource = self
            panel.delegate = self
            panel.updateController() // Ensure panel is ready
            panel.makeKeyAndOrderFront(nil)
            // panel.center() // Optional: let OS decide or center
            NSApp.activate(ignoringOtherApps: true)
            
            // Observe close to terminate
            NotificationCenter.default.addObserver(self, selector: #selector(panelWillClose), name: NSWindow.willCloseNotification, object: panel)
        } else {
             print("Failed to get QLPreviewPanel")
             NSApp.terminate(nil)
        }
    }
    
    @objc func panelWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return 1
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        return URL(fileURLWithPath: path) as QLPreviewItem
    }
}

let args = CommandLine.arguments
if args.count < 2 {
    print("Usage: swift ql.swift <file>")
    exit(1)
}

let app = NSApplication.shared
// use .accessory to hide from dock but still have UI, or .regular for full app behavior (better for focus)
app.setActivationPolicy(.regular) 

let delegate = AppDelegate(path: args[1])
app.delegate = delegate
app.run()
