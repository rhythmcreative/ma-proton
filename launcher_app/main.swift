import AppKit
import Foundation

class CrossOverLauncherApp: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    
    // Status & Controls
    var statusLabel: NSTextField!
    var d3dMetalCheck: NSButton!
    var msyncCheck: NSButton!
    var hudCheck: NSButton!
    var scalePopUp: NSPopUpButton!
    var backendPopUp: NSPopUpButton!
    
    let maProtonBin = "/Users/rhythmcreative/.local/bin/ma-proton"
    let prefixPath = NSHomeDirectory() + "/.ma-proton/prefixes/default"

    func applicationDidFinishLaunching(_ notification: Notification) {
        let width: CGFloat = 980
        let height: CGFloat = 620
        
        let rect = NSRect(x: 0, y: 0, width: width, height: height)
        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "ma-proton"
        window.titlebarAppearsTransparent = true
        window.minSize = NSSize(width: 880, height: 560)
        window.isReleasedWhenClosed = false

        let splitView = NSSplitView(frame: rect)
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.autoresizingMask = [.width, .height]
        window.contentView = splitView

        // 1. Left Sidebar (Bottles)
        let leftSidebar = buildSidebarView(width: 210, height: height)
        splitView.addSubview(leftSidebar)

        // 2. Center Panel (Installed Programs Grid)
        let centerPanel = buildCenterView(width: 510, height: height)
        splitView.addSubview(centerPanel)

        // 3. Right Inspector (Settings & Tools)
        let rightInspector = buildInspectorView(width: 260, height: height)
        splitView.addSubview(rightInspector)

        splitView.setPosition(210, ofDividerAt: 0)
        splitView.setPosition(720, ofDividerAt: 1)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // ==========================================
    // 1. LEFT SIDEBAR: BOTTLES
    // ==========================================
    func buildSidebarView(width: CGFloat, height: CGFloat) -> NSView {
        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        visualEffect.material = .sidebar
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active

        var y = height - 50
        let sectionTitle = NSTextField(labelWithString: "BOTTLES")
        sectionTitle.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        sectionTitle.textColor = .secondaryLabelColor
        sectionTitle.frame = NSRect(x: 18, y: y, width: 140, height: 16)
        visualEffect.addSubview(sectionTitle)

        let addBtn = NSButton(image: symbolImage("plus", size: 12), target: self, action: #selector(newBottleAction))
        addBtn.isBordered = false
        addBtn.frame = NSRect(x: width - 36, y: y - 2, width: 20, height: 20)
        visualEffect.addSubview(addBtn)
        y -= 35

        // Bottle Item 1: Default
        let bottleBox = NSBox(frame: NSRect(x: 10, y: y, width: width - 20, height: 48))
        bottleBox.boxType = .custom
        bottleBox.cornerRadius = 8
        bottleBox.borderWidth = 0
        bottleBox.fillColor = NSColor.controlAccentColor.withAlphaComponent(0.18)
        visualEffect.addSubview(bottleBox)

        let bottleIcon = NSImageView(frame: NSRect(x: 10, y: 14, width: 20, height: 20))
        bottleIcon.image = symbolImage("cylinder.split.1x2.fill", size: 16, color: .controlAccentColor)
        bottleBox.addSubview(bottleIcon)

        let bTitle = NSTextField(labelWithString: "Default")
        bTitle.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        bTitle.frame = NSRect(x: 36, y: 24, width: 120, height: 18)
        bottleBox.addSubview(bTitle)

        let bSub = NSTextField(labelWithString: "Windows 10 64-bit")
        bSub.font = NSFont.systemFont(ofSize: 10)
        bSub.textColor = .secondaryLabelColor
        bSub.frame = NSRect(x: 36, y: 8, width: 120, height: 14)
        bottleBox.addSubview(bSub)
        y -= 54

        // Bottle Item 2: Steam Isolated
        let b2 = createSecondaryBottleRow(name: "Gaming 64-bit", y: y, width: width)
        visualEffect.addSubview(b2)

        // Bottom Install Software Button
        let installBtn = NSButton(title: "  Install Software...", target: self, action: #selector(chooseAndRunExe))
        installBtn.image = symbolImage("arrow.down.circle.fill", size: 13)
        installBtn.imagePosition = .imageLeft
        installBtn.bezelStyle = .rounded
        installBtn.frame = NSRect(x: 12, y: 15, width: width - 24, height: 32)
        visualEffect.addSubview(installBtn)

        return visualEffect
    }

    func createSecondaryBottleRow(name: String, y: CGFloat, width: CGFloat) -> NSView {
        let row = NSView(frame: NSRect(x: 10, y: y, width: width - 20, height: 42))
        let icon = NSImageView(frame: NSRect(x: 10, y: 11, width: 20, height: 20))
        icon.image = symbolImage("shippingbox.fill", size: 15, color: .secondaryLabelColor)
        row.addSubview(icon)

        let t = NSTextField(labelWithString: name)
        t.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        t.textColor = .secondaryLabelColor
        t.frame = NSRect(x: 36, y: 20, width: 130, height: 16)
        row.addSubview(t)

        let s = NSTextField(labelWithString: "Ready")
        s.font = NSFont.systemFont(ofSize: 10)
        s.textColor = .tertiaryLabelColor
        s.frame = NSRect(x: 36, y: 6, width: 130, height: 14)
        row.addSubview(s)
        return row
    }

    // ==========================================
    // 2. CENTER PANEL: PROGRAMS GRID
    // ==========================================
    func buildCenterView(width: CGFloat, height: CGFloat) -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        view.autoresizingMask = [.width, .height]

        var y = height - 70
        // Top Hero Bottle Header
        let heroBox = NSBox(frame: NSRect(x: 25, y: y - 25, width: width - 50, height: 75))
        heroBox.boxType = .custom
        heroBox.cornerRadius = 12
        heroBox.borderWidth = 1
        heroBox.borderColor = .separatorColor
        heroBox.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.4)
        heroBox.autoresizingMask = [.width]
        view.addSubview(heroBox)

        let heroIcon = NSImageView(frame: NSRect(x: 18, y: 18, width: 40, height: 40))
        heroIcon.image = symbolImage("macmini.fill", size: 28, color: .controlAccentColor)
        heroBox.addSubview(heroIcon)

        let heroTitle = NSTextField(labelWithString: "Default (Windows 10 64-bit)")
        heroTitle.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        heroTitle.frame = NSRect(x: 70, y: 40, width: 360, height: 24)
        heroBox.addSubview(heroTitle)

        let heroSub = NSTextField(labelWithString: "Wine 11.0 (Darwin WOW64) • Apple Silicon M4 Max • Metal 3")
        heroSub.font = NSFont.systemFont(ofSize: 11)
        heroSub.textColor = .secondaryLabelColor
        heroSub.frame = NSRect(x: 70, y: 22, width: 380, height: 16)
        heroBox.addSubview(heroSub)
        y -= 105

        // Section Label
        let secLabel = NSTextField(labelWithString: "PROGRAMS & SHORTCUTS")
        secLabel.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        secLabel.textColor = .secondaryLabelColor
        secLabel.frame = NSRect(x: 25, y: y, width: 300, height: 16)
        view.addSubview(secLabel)
        y -= 135

        let cardW: CGFloat = 220
        let cardH: CGFloat = 115

        // Card 1: Valve Steam
        let steamCard = buildProgramCard(
            title: "Valve Steam",
            subtitle: "Windows Catalog • Metal Pipeline",
            symbol: "gamecontroller.fill",
            tintColor: .systemBlue,
            action: #selector(launchSteam),
            x: 25,
            y: y,
            width: cardW,
            height: cardH
        )
        view.addSubview(steamCard)

        // Card 2: Epic Games Store
        let epicCard = buildProgramCard(
            title: "Epic Games Store",
            subtitle: "Storefront & Library",
            symbol: "bolt.shield.fill",
            tintColor: .systemPurple,
            action: #selector(launchEpic),
            x: 260,
            y: y,
            width: cardW,
            height: cardH
        )
        view.addSubview(epicCard)
        y -= 130

        // Card 3: Custom EXE
        let exeCard = buildProgramCard(
            title: "Run .EXE File...",
            subtitle: "Choose any game or installer",
            symbol: "play.rectangle.fill",
            tintColor: .systemGreen,
            action: #selector(chooseAndRunExe),
            x: 25,
            y: y,
            width: cardW,
            height: cardH
        )
        view.addSubview(exeCard)

        // Card 4: C: Drive
        let cDriveCard = buildProgramCard(
            title: "Browse C: Drive",
            subtitle: "Open virtual filesystem in Finder",
            symbol: "externaldrive.fill",
            tintColor: .systemOrange,
            action: #selector(openDriveC),
            x: 260,
            y: y,
            width: cardW,
            height: cardH
        )
        view.addSubview(cDriveCard)

        // Bottom Status Label
        statusLabel = NSTextField(labelWithString: "Ready • Apple Metal and MSync active.")
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.frame = NSRect(x: 25, y: 15, width: width - 50, height: 18)
        statusLabel.autoresizingMask = [.width, .maxYMargin]
        view.addSubview(statusLabel)

        return view
    }

    func buildProgramCard(
        title: String,
        subtitle: String,
        symbol: String,
        tintColor: NSColor,
        action: Selector,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat
    ) -> NSBox {
        let box = NSBox(frame: NSRect(x: x, y: y, width: width, height: height))
        box.boxType = .custom
        box.cornerRadius = 12
        box.borderWidth = 1
        box.borderColor = .separatorColor
        box.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.4)

        // Icon Badge
        let badge = NSBox(frame: NSRect(x: 16, y: height - 52, width: 36, height: 36))
        badge.boxType = .custom
        badge.cornerRadius = 8
        badge.borderWidth = 0
        badge.fillColor = tintColor.withAlphaComponent(0.15)
        box.addSubview(badge)

        let icon = NSImageView(frame: NSRect(x: 8, y: 8, width: 20, height: 20))
        icon.image = symbolImage(symbol, size: 16, color: tintColor)
        badge.addSubview(icon)

        let t = NSTextField(labelWithString: title)
        t.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        t.frame = NSRect(x: 16, y: 36, width: width - 32, height: 18)
        box.addSubview(t)

        let s = NSTextField(labelWithString: subtitle)
        s.font = NSFont.systemFont(ofSize: 10)
        s.textColor = .secondaryLabelColor
        s.frame = NSRect(x: 16, y: 18, width: width - 32, height: 16)
        box.addSubview(s)

        let btn = NSButton(frame: NSRect(x: 0, y: 0, width: width, height: height))
        btn.title = ""
        btn.isTransparent = true
        btn.target = self
        btn.action = action
        box.addSubview(btn)

        return box
    }

    // ==========================================
    // 3. RIGHT INSPECTOR: SETTINGS & TOOLS
    // ==========================================
    func buildInspectorView(width: CGFloat, height: CGFloat) -> NSView {
        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        visualEffect.material = .sidebar
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active

        var y = height - 50
        let sec1 = NSTextField(labelWithString: "GRAPHICS & ACCELERATION")
        sec1.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        sec1.textColor = .secondaryLabelColor
        sec1.frame = NSRect(x: 16, y: y, width: 220, height: 16)
        visualEffect.addSubview(sec1)
        y -= 28

        d3dMetalCheck = NSButton(checkboxWithTitle: "D3DMetal (DirectX to Metal)", target: nil, action: nil)
        d3dMetalCheck.state = .on
        d3dMetalCheck.frame = NSRect(x: 16, y: y, width: 220, height: 20)
        visualEffect.addSubview(d3dMetalCheck)
        y -= 24

        msyncCheck = NSButton(checkboxWithTitle: "MSync (Mach Semaphores)", target: nil, action: nil)
        msyncCheck.state = .on
        msyncCheck.frame = NSRect(x: 16, y: y, width: 220, height: 20)
        visualEffect.addSubview(msyncCheck)
        y -= 24

        hudCheck = NSButton(checkboxWithTitle: "Metal Performance HUD", target: nil, action: nil)
        hudCheck.frame = NSRect(x: 16, y: y, width: 220, height: 20)
        visualEffect.addSubview(hudCheck)
        y -= 38

        let sec2 = NSTextField(labelWithString: "DISPLAY & RESOLUTION")
        sec2.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        sec2.textColor = .secondaryLabelColor
        sec2.frame = NSRect(x: 16, y: y, width: 220, height: 16)
        visualEffect.addSubview(sec2)
        y -= 26

        let scaleLbl = NSTextField(labelWithString: "Screen Scaling:")
        scaleLbl.font = NSFont.systemFont(ofSize: 11)
        scaleLbl.frame = NSRect(x: 16, y: y, width: 120, height: 16)
        visualEffect.addSubview(scaleLbl)
        y -= 24

        scalePopUp = NSPopUpButton(frame: NSRect(x: 14, y: y, width: 232, height: 24))
        scalePopUp.addItems(withTitles: ["Auto (Adaptive to Monitor)", "1.50x (Scaled)", "1.75x (QHD 1440p)", "2.00x (Retina 4K)", "2.25x (Large)"])
        visualEffect.addSubview(scalePopUp)
        y -= 34

        let backLbl = NSTextField(labelWithString: "Graphics Engine:")
        backLbl.font = NSFont.systemFont(ofSize: 11)
        backLbl.frame = NSRect(x: 16, y: y, width: 120, height: 16)
        visualEffect.addSubview(backLbl)
        y -= 24

        backendPopUp = NSPopUpButton(frame: NSRect(x: 14, y: y, width: 232, height: 24))
        backendPopUp.addItems(withTitles: ["Apple D3DMetal (GPTK)", "DXMT (DirectX 11 to Metal)", "DXVK (Vulkan over MoltenVK)", "WineD3D (OpenGL Fallback)"])
        visualEffect.addSubview(backendPopUp)
        y -= 44

        // Section: Tools
        let sec3 = NSTextField(labelWithString: "BOTTLE CONTROL")
        sec3.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        sec3.textColor = .secondaryLabelColor
        sec3.frame = NSRect(x: 16, y: y, width: 220, height: 16)
        visualEffect.addSubview(sec3)
        y -= 30

        let tools: [(String, String, Selector)] = [
            ("Wine Configuration", "gearshape.fill", #selector(openWinecfg)),
            ("Registry Editor", "pencil.and.list.clipboard", #selector(openRegedit)),
            ("Task Manager", "chart.bar.xaxis", #selector(openTaskmgr)),
            ("Command Prompt", "terminal.fill", #selector(openCmd))
        ]

        for (title, symbol, sel) in tools {
            let b = NSButton(title: "  " + title, target: self, action: sel)
            b.image = symbolImage(symbol, size: 12, color: .controlAccentColor)
            b.imagePosition = .imageLeft
            b.bezelStyle = .rounded
            b.alignment = .left
            b.frame = NSRect(x: 14, y: y, width: 232, height: 28)
            visualEffect.addSubview(b)
            y -= 32
        }

        y -= 6
        let killBtn = NSButton(title: "  Stop All Bottle Processes", target: self, action: #selector(killBottleProcesses))
        killBtn.image = symbolImage("xmark.octagon.fill", size: 12, color: .systemRed)
        killBtn.imagePosition = .imageLeft
        killBtn.bezelStyle = .rounded
        killBtn.contentTintColor = .systemRed
        killBtn.frame = NSRect(x: 14, y: y, width: 232, height: 30)
        visualEffect.addSubview(killBtn)

        return visualEffect
    }

    // ==========================================
    // HELPERS & EXECUTION
    // ==========================================
    func symbolImage(_ name: String, size: CGFloat, color: NSColor? = nil) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: size, weight: .medium)
        if let img = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
            img.isTemplate = (color == nil)
            return img
        }
        return NSImage()
    }

    func getScaleParam() -> String {
        switch scalePopUp.titleOfSelectedItem ?? "" {
        case "1.50x (Scaled)": return "1.5"
        case "1.75x (QHD 1440p)": return "1.75"
        case "2.00x (Retina 4K)": return "2.0"
        case "2.25x (Large)": return "2.25"
        default: return "auto"
        }
    }

    func getBackendParam() -> String {
        let sel = backendPopUp.titleOfSelectedItem ?? ""
        if sel.contains("DXMT") { return "dxmt" }
        if sel.contains("DXVK") { return "dxvk" }
        if sel.contains("WineD3D") { return "wined3d" }
        return "gptk"
    }

    @objc func launchSteam() {
        statusLabel.stringValue = "Launching Windows Steam with Metal acceleration..."
        var args = ["steam", "--scale", getScaleParam(), "--backend", getBackendParam()]
        if hudCheck.state == .on { args.append("--hud") }
        runCLI(args: args)
    }

    @objc func launchEpic() {
        statusLabel.stringValue = "Launching Epic Games Store..."
        var args = ["epic", "--backend", getBackendParam()]
        if hudCheck.state == .on { args.append("--hud") }
        runCLI(args: args)
    }

    @objc func chooseAndRunExe() {
        let panel = NSOpenPanel()
        panel.title = "Select Windows Executable (.EXE)"
        panel.allowedContentTypes = []
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            statusLabel.stringValue = "Running: \(url.lastPathComponent)..."
            var args = ["run", url.path, "--backend", getBackendParam()]
            if hudCheck.state == .on { args.append("--hud") }
            runCLI(args: args)
        }
    }

    @objc func openDriveC() {
        let url = URL(fileURLWithPath: prefixPath + "/drive_c")
        NSWorkspace.shared.activateFileViewerSelecting([url])
        statusLabel.stringValue = "Opened virtual C: Drive in Finder."
    }

    @objc func openWinecfg() {
        statusLabel.stringValue = "Opening Wine Configuration..."
        runCLI(args: ["winecfg"])
    }

    @objc func openRegedit() {
        statusLabel.stringValue = "Opening Registry Editor..."
        runCLI(args: ["regedit"])
    }

    @objc func openTaskmgr() {
        statusLabel.stringValue = "Opening Task Manager..."
        runCLI(args: ["taskmgr"])
    }

    @objc func openCmd() {
        statusLabel.stringValue = "Opening Command Prompt..."
        runCLI(args: ["cmd"])
    }

    @objc func killBottleProcesses() {
        statusLabel.stringValue = "Stopping all Wine processes..."
        runCLI(args: ["kill"])
    }

    @objc func newBottleAction() {
        let alert = NSAlert()
        alert.messageText = "New ma-proton Bottle"
        alert.informativeText = "Active bottle 'Default' is configured with Windows 10 64-bit and Apple Metal 3 acceleration."
        alert.runModal()
    }

    func runCLI(args: [String]) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.maProtonBin)
            process.arguments = args

            do {
                try process.run()
                DispatchQueue.main.async {
                    self.statusLabel.stringValue = "Running: ma-proton \(args.joined(separator: " "))"
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusLabel.stringValue = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

let app = NSApplication.shared
let delegate = CrossOverLauncherApp()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
