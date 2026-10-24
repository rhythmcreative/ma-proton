import AppKit
import Foundation

// MARK: - Exact CrossOver UI Architecture
final class CrossOverAppController: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    
    // Bottle state
    var selectedBottle: String = "Default"
    
    // Toggles (matching CrossOver BottleView.nib)
    var d3dMetalCheck: NSButton!
    var msyncCheck: NSButton!
    var highResCheck: NSButton!
    var hudCheck: NSButton!
    var scalePopUp: NSPopUpButton!

    let runnerBinary = "/Users/rhythmcreative/.local/bin/ma-proton"
    let prefixPath = NSHomeDirectory() + "/.ma-proton/prefixes/default"

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupCrossOverWindow()
    }

    func setupCrossOverWindow() {
        let width: CGFloat = 900
        let height: CGFloat = 560

        let rect = NSRect(x: 0, y: 0, width: width, height: height)
        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "ma-proton"
        window.minSize = NSSize(width: 820, height: 480)
        window.isReleasedWhenClosed = false

        let rootSplit = NSSplitView(frame: rect)
        rootSplit.isVertical = true
        rootSplit.dividerStyle = .thin
        rootSplit.autoresizingMask = [.width, .height]
        window.contentView = rootSplit

        // 1. Left Sidebar: Bottles (Width: 200)
        let sidebar = buildCrossOverSidebar(width: 200, height: height)
        rootSplit.addSubview(sidebar)

        // 2. Center: IconCollectionView (Width: 440)
        let centerView = buildCrossOverIconCollectionView(width: 440, height: height)
        rootSplit.addSubview(centerView)

        // 3. Right Sidebar: Bottle Details & Tools (Width: 260)
        let inspector = buildCrossOverInspector(width: 260, height: height)
        rootSplit.addSubview(inspector)

        rootSplit.setPosition(200, ofDividerAt: 0)
        rootSplit.setPosition(640, ofDividerAt: 1)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // ==========================================
    // 1. LEFT SIDEBAR: BOTTLES
    // ==========================================
    func buildCrossOverSidebar(width: CGFloat, height: CGFloat) -> NSView {
        let view = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active

        var y = height - 42
        let title = NSTextField(labelWithString: "BOTTLES")
        title.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        title.textColor = .secondaryLabelColor
        title.frame = NSRect(x: 18, y: y, width: 120, height: 16)
        view.addSubview(title)

        let addBtn = NSButton(image: symbolImage("plus", size: 12), target: self, action: #selector(newBottleAction))
        addBtn.isBordered = false
        addBtn.frame = NSRect(x: width - 36, y: y - 2, width: 20, height: 20)
        view.addSubview(addBtn)
        y -= 36

        // Default Bottle Row
        let bottleRow = NSBox(frame: NSRect(x: 8, y: y, width: width - 16, height: 46))
        bottleRow.boxType = .custom
        bottleRow.cornerRadius = 6
        bottleRow.borderWidth = 0
        bottleRow.fillColor = NSColor.controlAccentColor.withAlphaComponent(0.18)
        view.addSubview(bottleRow)

        let icon = NSImageView(frame: NSRect(x: 10, y: 13, width: 20, height: 20))
        icon.image = symbolImage("cylinder.split.1x2.fill", size: 16, color: .controlAccentColor)
        bottleRow.addSubview(icon)

        let t = NSTextField(labelWithString: "Default")
        t.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        t.frame = NSRect(x: 36, y: 22, width: 120, height: 18)
        bottleRow.addSubview(t)

        let s = NSTextField(labelWithString: "Windows 10 64-bit")
        s.font = NSFont.systemFont(ofSize: 10)
        s.textColor = .secondaryLabelColor
        s.frame = NSRect(x: 36, y: 7, width: 120, height: 14)
        bottleRow.addSubview(s)
        y -= 52

        // Secondary Bottle Row
        let row2 = NSView(frame: NSRect(x: 8, y: y, width: width - 16, height: 40))
        let icon2 = NSImageView(frame: NSRect(x: 10, y: 10, width: 20, height: 20))
        icon2.image = symbolImage("shippingbox.fill", size: 15, color: .secondaryLabelColor)
        row2.addSubview(icon2)

        let t2 = NSTextField(labelWithString: "Steam")
        t2.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        t2.textColor = .secondaryLabelColor
        t2.frame = NSRect(x: 36, y: 20, width: 120, height: 16)
        row2.addSubview(t2)

        let s2 = NSTextField(labelWithString: "Isolated Bottle")
        s2.font = NSFont.systemFont(ofSize: 10)
        s2.textColor = .tertiaryLabelColor
        s2.frame = NSRect(x: 36, y: 5, width: 120, height: 14)
        row2.addSubview(s2)
        view.addSubview(row2)

        // Bottom Button: "Install Application into Bottle..."
        let installBtn = NSButton(title: "Install Application...", target: self, action: #selector(chooseAndRunExe))
        installBtn.bezelStyle = .rounded
        installBtn.frame = NSRect(x: 10, y: 14, width: width - 20, height: 32)
        view.addSubview(installBtn)

        return view
    }

    // ==========================================
    // 2. CENTER PANEL: EXACT CrossOver IconCollectionView
    // ==========================================
    func buildCrossOverIconCollectionView(width: CGFloat, height: CGFloat) -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        view.autoresizingMask = [.width, .height]

        var y = height - 50
        // Top Bottle Title
        let bTitle = NSTextField(labelWithString: "Default")
        bTitle.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        bTitle.frame = NSRect(x: 28, y: y, width: 300, height: 24)
        view.addSubview(bTitle)

        let bType = NSTextField(labelWithString: "Windows 10 64-bit • Ready")
        bType.font = NSFont.systemFont(ofSize: 11)
        bType.textColor = .secondaryLabelColor
        bType.frame = NSRect(x: 28, y: y - 18, width: 300, height: 16)
        view.addSubview(bType)
        y -= 40

        // Separator
        let sep = NSBox(frame: NSRect(x: 28, y: y, width: width - 56, height: 1))
        sep.boxType = .separator
        sep.autoresizingMask = [.width]
        view.addSubview(sep)
        y -= 50

        // Program Icon Grid (80x80 icons, matching CrossOver LauncherIconView)
        // Icon 1: Steam
        let steamItem = createLauncherIconItem(
            name: "Steam",
            symbolName: "gamecontroller.fill",
            color: .systemBlue,
            action: #selector(launchSteam),
            x: 40,
            y: y
        )
        view.addSubview(steamItem)

        // Icon 2: Epic Games
        let epicItem = createLauncherIconItem(
            name: "Epic Games",
            symbolName: "bolt.shield.fill",
            color: .systemPurple,
            action: #selector(launchEpic),
            x: 160,
            y: y
        )
        view.addSubview(epicItem)

        // Icon 3: Install Application / Run Command
        let runItem = createLauncherIconItem(
            name: "Run Command...",
            symbolName: "play.circle.fill",
            color: .systemGreen,
            action: #selector(chooseAndRunExe),
            x: 280,
            y: y
        )
        view.addSubview(runItem)

        return view
    }

    func createLauncherIconItem(
        name: String,
        symbolName: String,
        color: NSColor,
        action: Selector,
        x: CGFloat,
        y: CGFloat
    ) -> NSView {
        let item = NSView(frame: NSRect(x: x, y: y, width: 88, height: 88))

        // Icon Box
        let iconBox = NSBox(frame: NSRect(x: 14, y: 28, width: 60, height: 60))
        iconBox.boxType = .custom
        iconBox.cornerRadius = 14
        iconBox.borderWidth = 1
        iconBox.borderColor = .separatorColor
        iconBox.fillColor = color.withAlphaComponent(0.12)
        item.addSubview(iconBox)

        let iv = NSImageView(frame: NSRect(x: 15, y: 15, width: 30, height: 30))
        iv.image = symbolImage(symbolName, size: 24, color: color)
        iconBox.addSubview(iv)

        let label = NSTextField(labelWithString: name)
        label.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        label.alignment = .center
        label.frame = NSRect(x: 0, y: 4, width: 88, height: 18)
        item.addSubview(label)

        let btn = NSButton(frame: NSRect(x: 0, y: 0, width: 88, height: 88))
        btn.title = ""
        btn.isTransparent = true
        btn.target = self
        btn.action = action
        item.addSubview(btn)

        return item
    }

    // ==========================================
    // 3. RIGHT INSPECTOR: EXACT CrossOver BottleView
    // ==========================================
    func buildCrossOverInspector(width: CGFloat, height: CGFloat) -> NSView {
        let view = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active

        var y = height - 42

        // Section: Graphics
        let gHeader = NSTextField(labelWithString: "Graphics")
        gHeader.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        gHeader.textColor = .secondaryLabelColor
        gHeader.frame = NSRect(x: 16, y: y, width: 200, height: 16)
        view.addSubview(gHeader)
        y -= 26

        d3dMetalCheck = NSButton(checkboxWithTitle: "D3DMetal", target: nil, action: nil)
        d3dMetalCheck.state = .on
        d3dMetalCheck.frame = NSRect(x: 16, y: y, width: 220, height: 20)
        view.addSubview(d3dMetalCheck)
        y -= 24

        msyncCheck = NSButton(checkboxWithTitle: "MSync", target: nil, action: nil)
        msyncCheck.state = .on
        msyncCheck.frame = NSRect(x: 16, y: y, width: 220, height: 20)
        view.addSubview(msyncCheck)
        y -= 24

        highResCheck = NSButton(checkboxWithTitle: "High Resolution Mode", target: nil, action: nil)
        highResCheck.state = .on
        highResCheck.frame = NSRect(x: 16, y: y, width: 220, height: 20)
        view.addSubview(highResCheck)
        y -= 24

        hudCheck = NSButton(checkboxWithTitle: "Metal Performance HUD", target: nil, action: nil)
        hudCheck.frame = NSRect(x: 16, y: y, width: 220, height: 20)
        view.addSubview(hudCheck)
        y -= 34

        // Section: Bottle Details
        let dHeader = NSTextField(labelWithString: "Bottle Details")
        dHeader.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        dHeader.textColor = .secondaryLabelColor
        dHeader.frame = NSRect(x: 16, y: y, width: 200, height: 16)
        view.addSubview(dHeader)
        y -= 22

        let bType = NSTextField(labelWithString: "Bottle Type: Win 10 (64-bit)")
        bType.font = NSFont.systemFont(ofSize: 11)
        bType.frame = NSRect(x: 16, y: y, width: 220, height: 16)
        view.addSubview(bType)
        y -= 18

        let bArch = NSTextField(labelWithString: "Arch: Apple Silicon (M4 Max)")
        bArch.font = NSFont.systemFont(ofSize: 11)
        bArch.textColor = .secondaryLabelColor
        bArch.frame = NSRect(x: 16, y: y, width: 220, height: 16)
        view.addSubview(bArch)
        y -= 34

        // Actions (Matching CrossOver BottleView.nib buttons)
        let actions: [(String, String, Selector)] = [
            ("Run Command...", "play.circle", #selector(chooseAndRunExe)),
            ("Open C: Drive", "internaldrive", #selector(openDriveC)),
            ("Wine Configuration", "gearshape", #selector(openWinecfg)),
            ("Registry Editor", "pencil.and.list.clipboard", #selector(openRegedit)),
            ("Task Manager", "chart.bar.xaxis", #selector(openTaskmgr))
        ]

        for (label, sym, sel) in actions {
            let btn = NSButton(title: "  " + label, target: self, action: sel)
            btn.image = symbolImage(sym, size: 12)
            btn.imagePosition = .imageLeft
            btn.bezelStyle = .rounded
            btn.alignment = .left
            btn.frame = NSRect(x: 14, y: y, width: 232, height: 28)
            view.addSubview(btn)
            y -= 32
        }

        y -= 4
        let quitBtn = NSButton(title: "  Quit All Applications", target: self, action: #selector(killProcesses))
        quitBtn.image = symbolImage("xmark.circle.fill", size: 12, color: .systemRed)
        quitBtn.imagePosition = .imageLeft
        quitBtn.bezelStyle = .rounded
        quitBtn.contentTintColor = .systemRed
        quitBtn.frame = NSRect(x: 14, y: y, width: 232, height: 30)
        view.addSubview(quitBtn)

        return view
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

    @objc func launchSteam() {
        var args = ["steam", "--scale", highResCheck.state == .on ? "auto" : "1.0"]
        if hudCheck.state == .on { args.append("--hud") }
        runCLI(args: args)
    }

    @objc func launchEpic() {
        var args = ["epic"]
        if hudCheck.state == .on { args.append("--hud") }
        runCLI(args: args)
    }

    @objc func chooseAndRunExe() {
        let panel = NSOpenPanel()
        panel.title = "Run Command..."
        panel.allowedContentTypes = []
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            var args = ["run", url.path]
            if hudCheck.state == .on { args.append("--hud") }
            runCLI(args: args)
        }
    }

    @objc func openDriveC() {
        let url = URL(fileURLWithPath: prefixPath + "/drive_c")
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    @objc func openWinecfg() {
        runCLI(args: ["winecfg"])
    }

    @objc func openRegedit() {
        runCLI(args: ["regedit"])
    }

    @objc func openTaskmgr() {
        runCLI(args: ["taskmgr"])
    }

    @objc func killProcesses() {
        runCLI(args: ["kill"])
    }

    @objc func newBottleAction() {
        let alert = NSAlert()
        alert.messageText = "New Bottle"
        alert.informativeText = "Active bottle 'Default' is ready with Windows 10 64-bit and Apple Metal."
        alert.runModal()
    }

    func runCLI(args: [String]) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.runnerBinary)
            process.arguments = args
            try? process.run()
        }
    }
}

let app = NSApplication.shared
let delegate = CrossOverAppController()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
