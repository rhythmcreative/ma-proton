import AppKit
import Foundation

// MARK: - Main Application Controller
final class AppDelegate: NSObject, NSApplicationDelegate, NSToolbarDelegate {
    var window: NSWindow!
    
    // UI References
    var statusText: NSTextField!
    var scalePicker: NSPopUpButton!
    var enginePicker: NSPopUpButton!
    var hudCheckbox: NSButton!
    var msyncCheckbox: NSButton!
    var d3dMetalCheckbox: NSButton!
    
    let runnerBinary = "/Users/rhythmcreative/.local/bin/ma-proton"
    let prefixPath = NSHomeDirectory() + "/.ma-proton/prefixes/default"

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindow()
    }

    func setupWindow() {
        let width: CGFloat = 860
        let height: CGFloat = 580

        let contentRect = NSRect(x: 0, y: 0, width: width, height: height)
        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "ma-proton"
        window.minSize = NSSize(width: 800, height: 520)
        window.isReleasedWhenClosed = false

        // Setup unified toolbar
        let toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        window.toolbar = toolbar
        window.toolbarStyle = .unified

        // Root View with Sidebar and Main Content
        let splitView = NSSplitView(frame: contentRect)
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.autoresizingMask = [.width, .height]
        window.contentView = splitView

        // 1. Sidebar (Source List)
        let sidebar = createSidebar(width: 220, height: height)
        splitView.addSubview(sidebar)

        // 2. Main Detail View
        let mainDetail = createMainDetail(width: 640, height: height)
        splitView.addSubview(mainDetail)

        splitView.setPosition(210, ofDividerAt: 0)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Toolbar Delegate
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            NSToolbarItem.Identifier("runExe"),
            NSToolbarItem.Identifier("browseC"),
            .flexibleSpace,
            NSToolbarItem.Identifier("stopAll")
        ]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)

        switch itemIdentifier.rawValue {
        case "runExe":
            item.label = "Run File"
            item.paletteLabel = "Run Executable"
            item.toolTip = "Run any Windows executable (.exe)"
            item.image = NSImage(systemSymbolName: "play.circle.fill", accessibilityDescription: "Run")
            item.target = self
            item.action = #selector(chooseAndRunExe)
        case "browseC":
            item.label = "C: Drive"
            item.paletteLabel = "Browse C: Drive"
            item.toolTip = "Open virtual Windows disk in Finder"
            item.image = NSImage(systemSymbolName: "externaldrive.fill", accessibilityDescription: "Drive")
            item.target = self
            item.action = #selector(openDriveC)
        case "stopAll":
            item.label = "Stop All"
            item.paletteLabel = "Stop Processes"
            item.toolTip = "Terminate all active Wine and game processes"
            item.image = NSImage(systemSymbolName: "stop.circle.fill", accessibilityDescription: "Stop")
            item.target = self
            item.action = #selector(killProcesses)
        default:
            return nil
        }
        return item
    }

    // MARK: - Sidebar Construction
    func createSidebar(width: CGFloat, height: CGFloat) -> NSView {
        let view = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active

        var currentY = height - 44

        let header = NSTextField(labelWithString: "BOTTLES")
        header.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        header.textColor = .secondaryLabelColor
        header.frame = NSRect(x: 18, y: currentY, width: 140, height: 16)
        view.addSubview(header)
        currentY -= 36

        // Primary Active Bottle Row
        let activeRow = NSBox(frame: NSRect(x: 8, y: currentY, width: width - 16, height: 48))
        activeRow.boxType = .custom
        activeRow.cornerRadius = 6
        activeRow.borderWidth = 0
        activeRow.fillColor = NSColor.controlAccentColor.withAlphaComponent(0.18)
        view.addSubview(activeRow)

        let bottleIcon = NSImageView(frame: NSRect(x: 12, y: 15, width: 18, height: 18))
        bottleIcon.image = NSImage(systemSymbolName: "shippingbox.fill", accessibilityDescription: nil)
        bottleIcon.contentTintColor = .controlAccentColor
        activeRow.addSubview(bottleIcon)

        let bName = NSTextField(labelWithString: "Default")
        bName.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        bName.frame = NSRect(x: 38, y: 24, width: 130, height: 18)
        activeRow.addSubview(bName)

        let bMeta = NSTextField(labelWithString: "Windows 10 (64-bit)")
        bMeta.font = NSFont.systemFont(ofSize: 10)
        bMeta.textColor = .secondaryLabelColor
        bMeta.frame = NSRect(x: 38, y: 8, width: 130, height: 14)
        activeRow.addSubview(bMeta)
        currentY -= 54

        // Secondary Bottle Row
        let row2 = NSView(frame: NSRect(x: 8, y: currentY, width: width - 16, height: 42))
        let icon2 = NSImageView(frame: NSRect(x: 12, y: 12, width: 18, height: 18))
        icon2.image = NSImage(systemSymbolName: "shippingbox", accessibilityDescription: nil)
        icon2.contentTintColor = .secondaryLabelColor
        row2.addSubview(icon2)

        let t2 = NSTextField(labelWithString: "Gaming Environment")
        t2.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        t2.textColor = .secondaryLabelColor
        t2.frame = NSRect(x: 38, y: 20, width: 140, height: 16)
        row2.addSubview(t2)

        let m2 = NSTextField(labelWithString: "Isolated Prefix")
        m2.font = NSFont.systemFont(ofSize: 10)
        m2.textColor = .tertiaryLabelColor
        m2.frame = NSRect(x: 38, y: 5, width: 140, height: 14)
        row2.addSubview(m2)
        view.addSubview(row2)

        // Bottom Add Bottle Button
        let addBtn = NSButton(title: "New Bottle...", target: self, action: #selector(newBottleAction))
        addBtn.bezelStyle = .rounded
        addBtn.frame = NSRect(x: 12, y: 14, width: width - 24, height: 30)
        view.addSubview(addBtn)

        return view
    }

    // MARK: - Main Content View
    func createMainDetail(width: CGFloat, height: CGFloat) -> NSView {
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]
        scrollView.borderType = .noBorder

        let content = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 680))
        content.autoresizingMask = [.width]
        scrollView.documentView = content

        var currentY: CGFloat = 630

        // 1. Bottle Info Header Banner
        let headerBox = NSBox(frame: NSRect(x: 24, y: currentY - 30, width: width - 48, height: 68))
        headerBox.boxType = .custom
        headerBox.cornerRadius = 8
        headerBox.borderWidth = 1
        headerBox.borderColor = .separatorColor
        headerBox.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.4)
        headerBox.autoresizingMask = [.width]
        content.addSubview(headerBox)

        let hTitle = NSTextField(labelWithString: "Default Bottle")
        hTitle.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        hTitle.frame = NSRect(x: 16, y: 38, width: 350, height: 20)
        headerBox.addSubview(hTitle)

        let hDesc = NSTextField(labelWithString: "Wine 11.0 (Darwin New WOW64) • Apple Silicon M4 Max • Apple Metal 3")
        hDesc.font = NSFont.systemFont(ofSize: 11)
        hDesc.textColor = .secondaryLabelColor
        hDesc.frame = NSRect(x: 16, y: 16, width: 450, height: 16)
        headerBox.addSubview(hDesc)
        currentY -= 95

        // 2. Installed Applications Section
        let appSection = NSTextField(labelWithString: "APPLICATIONS")
        appSection.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        appSection.textColor = .secondaryLabelColor
        appSection.frame = NSRect(x: 24, y: currentY, width: 300, height: 16)
        content.addSubview(appSection)
        currentY -= 82

        // App Card 1: Valve Steam
        let steamCard = createAppCard(
            title: "Valve Steam",
            publisher: "Valve Corporation",
            description: "Windows Steam client with full catalog unlock and Metal acceleration.",
            buttonText: "Launch Steam",
            symbolName: "gamecontroller.fill",
            tintColor: .systemBlue,
            action: #selector(launchSteam),
            y: currentY,
            width: width - 48,
            parent: content
        )
        currentY -= 82

        // App Card 2: Epic Games Store
        let epicCard = createAppCard(
            title: "Epic Games Launcher",
            publisher: "Epic Games, Inc.",
            description: "Windows Epic Games Store and library runner.",
            buttonText: "Launch Epic",
            symbolName: "bolt.shield.fill",
            tintColor: .systemPurple,
            action: #selector(launchEpic),
            y: currentY,
            width: width - 48,
            parent: content
        )
        currentY -= 82

        // App Card 3: Custom Executable
        let customCard = createAppCard(
            title: "Run Custom Executable",
            publisher: "Standalone Windows File",
            description: "Launch any .exe installer, game binary, or portable utility.",
            buttonText: "Select File...",
            symbolName: "play.rectangle.fill",
            tintColor: .systemGreen,
            action: #selector(chooseAndRunExe),
            y: currentY,
            width: width - 48,
            parent: content
        )
        currentY -= 95

        // 3. Settings & Maintenance Section
        let settingsSection = NSTextField(labelWithString: "SETTINGS & BOTTLE CONTROL")
        settingsSection.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        settingsSection.textColor = .secondaryLabelColor
        settingsSection.frame = NSRect(x: 24, y: currentY, width: 300, height: 16)
        content.addSubview(settingsSection)
        currentY -= 90

        let optBox = NSBox(frame: NSRect(x: 24, y: currentY, width: width - 48, height: 80))
        optBox.boxType = .custom
        optBox.cornerRadius = 8
        optBox.borderWidth = 1
        optBox.borderColor = .separatorColor
        optBox.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.4)
        optBox.autoresizingMask = [.width]
        content.addSubview(optBox)

        // Options Row 1
        d3dMetalCheckbox = NSButton(checkboxWithTitle: "D3DMetal (DirectX 11/12)", target: nil, action: nil)
        d3dMetalCheckbox.state = .on
        d3dMetalCheckbox.frame = NSRect(x: 16, y: 46, width: 200, height: 20)
        optBox.addSubview(d3dMetalCheckbox)

        msyncCheckbox = NSButton(checkboxWithTitle: "MSync Fast Synchronization", target: nil, action: nil)
        msyncCheckbox.state = .on
        msyncCheckbox.frame = NSRect(x: 230, y: 46, width: 200, height: 20)
        optBox.addSubview(msyncCheckbox)

        hudCheckbox = NSButton(checkboxWithTitle: "Metal Performance HUD", target: nil, action: nil)
        hudCheckbox.frame = NSRect(x: 440, y: 46, width: 170, height: 20)
        optBox.addSubview(hudCheckbox)

        // Options Row 2 (Scale & Backend)
        let sLbl = NSTextField(labelWithString: "Scaling:")
        sLbl.font = NSFont.systemFont(ofSize: 11)
        sLbl.frame = NSRect(x: 16, y: 15, width: 55, height: 18)
        optBox.addSubview(sLbl)

        scalePicker = NSPopUpButton(frame: NSRect(x: 70, y: 12, width: 160, height: 24))
        scalePicker.addItems(withTitles: ["Auto (Adaptive to Screen)", "1.50x (Scaled)", "1.75x (QHD 1440p)", "2.00x (Retina 4K)", "2.25x (Large)"])
        optBox.addSubview(scalePicker)

        let eLbl = NSTextField(labelWithString: "Engine:")
        eLbl.font = NSFont.systemFont(ofSize: 11)
        eLbl.frame = NSRect(x: 250, y: 15, width: 55, height: 18)
        optBox.addSubview(eLbl)

        enginePicker = NSPopUpButton(frame: NSRect(x: 305, y: 12, width: 180, height: 24))
        enginePicker.addItems(withTitles: ["Apple D3DMetal (GPTK)", "DXMT (DirectX 11)", "DXVK (Vulkan/MoltenVK)", "WineD3D (Fallback)"])
        optBox.addSubview(enginePicker)
        currentY -= 50

        // 4. Wine Utility Buttons Row
        let tools = [
            ("Winecfg", #selector(openWinecfg)),
            ("Regedit", #selector(openRegedit)),
            ("Task Manager", #selector(openTaskmgr)),
            ("Command Prompt", #selector(openCmd))
        ]

        var btnX: CGFloat = 24
        for (label, sel) in tools {
            let b = NSButton(title: label, target: self, action: sel)
            b.bezelStyle = .rounded
            b.frame = NSRect(x: btnX, y: currentY, width: 130, height: 28)
            content.addSubview(b)
            btnX += 140
        }
        currentY -= 35

        // Status Label at bottom
        statusText = NSTextField(labelWithString: "Ready. Select an application to launch.")
        statusText.font = NSFont.systemFont(ofSize: 11)
        statusText.textColor = .secondaryLabelColor
        statusText.frame = NSRect(x: 24, y: currentY, width: width - 48, height: 18)
        statusText.autoresizingMask = [.width]
        content.addSubview(statusText)

        return scrollView
    }

    // MARK: - App Card Component
    func createAppCard(
        title: String,
        publisher: String,
        description: String,
        buttonText: String,
        symbolName: String,
        tintColor: NSColor,
        action: Selector,
        y: CGFloat,
        width: CGFloat,
        parent: NSView
    ) -> NSBox {
        let card = NSBox(frame: NSRect(x: 24, y: y, width: width, height: 72))
        card.boxType = .custom
        card.cornerRadius = 8
        card.borderWidth = 1
        card.borderColor = .separatorColor
        card.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.4)
        card.autoresizingMask = [.width]
        parent.addSubview(card)

        // Leading App Icon
        let iconView = NSImageView(frame: NSRect(x: 16, y: 16, width: 38, height: 38))
        iconView.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        iconView.contentTintColor = tintColor
        card.addSubview(iconView)

        // Labels
        let t = NSTextField(labelWithString: title)
        t.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        t.frame = NSRect(x: 64, y: 44, width: width - 230, height: 18)
        card.addSubview(t)

        let p = NSTextField(labelWithString: publisher)
        p.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        p.textColor = .secondaryLabelColor
        p.frame = NSRect(x: 64, y: 28, width: width - 230, height: 14)
        card.addSubview(p)

        let d = NSTextField(labelWithString: description)
        d.font = NSFont.systemFont(ofSize: 11)
        d.textColor = .secondaryLabelColor
        d.frame = NSRect(x: 64, y: 10, width: width - 230, height: 16)
        card.addSubview(d)

        // Action Button
        let btn = NSButton(title: buttonText, target: self, action: action)
        btn.bezelStyle = .rounded
        btn.frame = NSRect(x: width - 146, y: 20, width: 130, height: 32)
        btn.autoresizingMask = [.minXMargin]
        card.addSubview(btn)

        return card
    }

    // MARK: - Actions
    func getScaleParam() -> String {
        switch scalePicker.titleOfSelectedItem ?? "" {
        case "1.50x (Scaled)": return "1.5"
        case "1.75x (QHD 1440p)": return "1.75"
        case "2.00x (Retina 4K)": return "2.0"
        case "2.25x (Large)": return "2.25"
        default: return "auto"
        }
    }

    func getEngineParam() -> String {
        let sel = enginePicker.titleOfSelectedItem ?? ""
        if sel.contains("DXMT") { return "dxmt" }
        if sel.contains("DXVK") { return "dxvk" }
        if sel.contains("WineD3D") { return "wined3d" }
        return "gptk"
    }

    @objc func launchSteam() {
        statusText.stringValue = "Launching Steam for Windows..."
        var args = ["steam", "--scale", getScaleParam(), "--backend", getEngineParam()]
        if hudCheckbox.state == .on { args.append("--hud") }
        runCLI(args: args)
    }

    @objc func launchEpic() {
        statusText.stringValue = "Launching Epic Games Launcher..."
        var args = ["epic", "--backend", getEngineParam()]
        if hudCheckbox.state == .on { args.append("--hud") }
        runCLI(args: args)
    }

    @objc func chooseAndRunExe() {
        let panel = NSOpenPanel()
        panel.title = "Select Windows Executable (.exe)"
        panel.allowedContentTypes = []
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            statusText.stringValue = "Running: \(url.lastPathComponent)..."
            var args = ["run", url.path, "--backend", getEngineParam()]
            if hudCheckbox.state == .on { args.append("--hud") }
            runCLI(args: args)
        }
    }

    @objc func openDriveC() {
        let url = URL(fileURLWithPath: prefixPath + "/drive_c")
        NSWorkspace.shared.activateFileViewerSelecting([url])
        statusText.stringValue = "Opened C: Drive in Finder."
    }

    @objc func openWinecfg() {
        statusText.stringValue = "Opening Wine Configuration..."
        runCLI(args: ["winecfg"])
    }

    @objc func openRegedit() {
        statusText.stringValue = "Opening Registry Editor..."
        runCLI(args: ["regedit"])
    }

    @objc func openTaskmgr() {
        statusText.stringValue = "Opening Task Manager..."
        runCLI(args: ["taskmgr"])
    }

    @objc func openCmd() {
        statusText.stringValue = "Opening Command Prompt..."
        runCLI(args: ["cmd"])
    }

    @objc func killProcesses() {
        statusText.stringValue = "Stopping all active bottle processes..."
        runCLI(args: ["kill"])
    }

    @objc func newBottleAction() {
        let alert = NSAlert()
        alert.messageText = "New Bottle"
        alert.informativeText = "Active bottle 'Default' is operational with Windows 10 (64-bit) and Apple Metal."
        alert.runModal()
    }

    func runCLI(args: [String]) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.runnerBinary)
            process.arguments = args

            do {
                try process.run()
                DispatchQueue.main.async {
                    self.statusText.stringValue = "Active: ma-proton \(args.joined(separator: " "))"
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusText.stringValue = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
