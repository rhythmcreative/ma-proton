import AppKit
import Foundation

class CrossOverStyleLauncherDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    
    // UI elements
    var bottleTableView: NSTableView!
    var bottleList: [String] = ["Default (Steam)", "Epic Games", "Gaming 64-bit"]
    var currentBottleIndex: Int = 0
    
    // Status & Settings controls
    var statusLabel: NSTextField!
    var d3dMetalSwitch: NSButton!
    var msyncSwitch: NSButton!
    var hudSwitch: NSButton!
    var scalePopUp: NSPopUpButton!
    var backendPopUp: NSPopUpButton!
    
    let maProtonBin = "/Users/rhythmcreative/.local/bin/ma-proton"
    let defaultPrefix = PathHelper.prefixPath()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let windowWidth: CGFloat = 980
        let windowHeight: CGFloat = 620
        
        let rect = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)
        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "ma-proton (CrossOver Edition)"
        window.minSize = NSSize(width: 880, height: 540)
        window.isReleasedWhenClosed = false

        let rootSplitView = NSSplitView(frame: rect)
        rootSplitView.isVertical = true
        rootSplitView.dividerStyle = .thin
        rootSplitView.autoresizingMask = [.width, .height]
        window.contentView = rootSplitView

        // 1. LEFT SIDEBAR (Bottles / Prefijos)
        let leftSidebar = buildLeftSidebar(width: 220, height: windowHeight)
        rootSplitView.addSubview(leftSidebar)

        // 2. CENTER PANEL (Installed Apps Grid & Launchers)
        let centerPanel = buildCenterPanel(width: 500, height: windowHeight)
        rootSplitView.addSubview(centerPanel)

        // 3. RIGHT SIDEBAR (Bottle Settings & Tools Inspector)
        let rightInspector = buildRightInspector(width: 260, height: windowHeight)
        rootSplitView.addSubview(rightInspector)

        // Set split positions
        rootSplitView.setPosition(220, ofDividerAt: 0)
        rootSplitView.setPosition(720, ofDividerAt: 1)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // ==========================================
    // 1. LEFT SIDEBAR: BOTTLES LIST
    // ==========================================
    func buildLeftSidebar(width: CGFloat, height: CGFloat) -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.6).cgColor

        var y: CGFloat = height - 40
        let headerLabel = NSTextField(labelWithString: "BOTELLAS")
        headerLabel.font = NSFont.boldSystemFont(ofSize: 11)
        headerLabel.textColor = .secondaryLabelColor
        headerLabel.frame = NSRect(x: 18, y: y, width: 140, height: 18)
        view.addSubview(headerLabel)

        let addBottleBtn = NSButton(title: "+", target: self, action: #selector(newBottleAction))
        addBottleBtn.bezelStyle = .roundRect
        addBottleBtn.frame = NSRect(x: width - 38, y: y - 2, width: 24, height: 22)
        view.addSubview(addBottleBtn)
        y -= 25

        // Scrollview with list
        let scrollView = NSScrollView(frame: NSRect(x: 10, y: 55, width: width - 20, height: y - 55))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        bottleTableView = NSTableView(frame: scrollView.bounds)
        bottleTableView.headerView = nil
        bottleTableView.backgroundColor = .clear
        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("bottleCol"))
        col.width = width - 30
        bottleTableView.addTableColumn(col)
        bottleTableView.delegate = self
        bottleTableView.dataSource = self
        bottleTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)

        scrollView.documentView = bottleTableView
        view.addSubview(scrollView)

        // Bottom "Instalar aplicación de Windows" button
        let installAppBtn = NSButton(title: "➕ Instalar Aplicación...", target: self, action: #selector(chooseAndRunExe))
        installAppBtn.bezelStyle = .rounded
        installAppBtn.frame = NSRect(x: 12, y: 15, width: width - 24, height: 32)
        view.addSubview(installAppBtn)

        return view
    }

    // ==========================================
    // 2. CENTER PANEL: PROGRAMS & SHORTCUTS GRID
    // ==========================================
    func buildCenterPanel(width: CGFloat, height: CGFloat) -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        view.autoresizingMask = [.width, .height]

        var y: CGFloat = height - 55
        let iconLabel = NSTextField(labelWithString: "🍾")
        iconLabel.font = NSFont.systemFont(ofSize: 28)
        iconLabel.frame = NSRect(x: 25, y: y - 5, width: 40, height: 40)
        view.addSubview(iconLabel)

        let titleLabel = NSTextField(labelWithString: "Default (Windows 10 64-bit)")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 20)
        titleLabel.frame = NSRect(x: 70, y: y + 5, width: 400, height: 26)
        view.addSubview(titleLabel)

        let archLabel = NSTextField(labelWithString: "Wine 11.0 • Apple Silicon M4 Max • Metal Activo")
        archLabel.font = NSFont.systemFont(ofSize: 12)
        archLabel.textColor = .secondaryLabelColor
        archLabel.frame = NSRect(x: 70, y: y - 16, width: 400, height: 18)
        view.addSubview(archLabel)
        y -= 65

        // Separator line
        let sep = NSBox(frame: NSRect(x: 25, y: y, width: width - 50, height: 1))
        sep.boxType = .separator
        sep.autoresizingMask = [.width]
        view.addSubview(sep)
        y -= 35

        let sectionLabel = NSTextField(labelWithString: "PROGRAMAS DISPONIBLES")
        sectionLabel.font = NSFont.boldSystemFont(ofSize: 11)
        sectionLabel.textColor = .secondaryLabelColor
        sectionLabel.frame = NSRect(x: 25, y: y, width: 250, height: 16)
        view.addSubview(sectionLabel)
        y -= 135

        // Program Card 1: Steam
        let steamCard = createProgramCard(
            title: "Valve Steam",
            subtitle: "Catálogo de Windows desbloqueado",
            iconEmoji: "🎮",
            action: #selector(launchSteam),
            x: 25,
            y: y,
            width: 210,
            height: 120
        )
        view.addSubview(steamCard)

        // Program Card 2: Epic Games
        let epicCard = createProgramCard(
            title: "Epic Games Store",
            subtitle: "Tienda y juegos de Epic Games",
            iconEmoji: "⚡",
            action: #selector(launchEpic),
            x: 255,
            y: y,
            width: 210,
            height: 120
        )
        view.addSubview(epicCard)
        y -= 135

        // Program Card 3: Run Custom EXE
        let exeCard = createProgramCard(
            title: "Ejecutar .EXE",
            subtitle: "Abrir juego o instalador portable",
            iconEmoji: "📂",
            action: #selector(chooseAndRunExe),
            x: 25,
            y: y,
            width: 210,
            height: 120
        )
        view.addSubview(exeCard)

        // Program Card 4: Open Drive C:
        let driveCard = createProgramCard(
            title: "Disco C: en Finder",
            subtitle: "Explorar carpetas de Windows",
            iconEmoji: "💽",
            action: #selector(openDriveC),
            x: 255,
            y: y,
            width: 210,
            height: 120
        )
        view.addSubview(driveCard)

        // Bottom status message
        statusLabel = NSTextField(labelWithString: "Listo para ejecutar aplicaciones de Windows en macOS.")
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.frame = NSRect(x: 25, y: 15, width: width - 50, height: 20)
        statusLabel.autoresizingMask = [.width, .maxYMargin]
        view.addSubview(statusLabel)

        return view
    }

    func createProgramCard(
        title: String,
        subtitle: String,
        iconEmoji: String,
        action: Selector,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat
    ) -> NSBox {
        let box = NSBox(frame: NSRect(x: x, y: y, width: width, height: height))
        box.boxType = .custom
        box.borderColor = .separatorColor
        box.borderWidth = 1.0
        box.cornerRadius = 10
        box.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.5)

        let emoji = NSTextField(labelWithString: iconEmoji)
        emoji.font = NSFont.systemFont(ofSize: 34)
        emoji.frame = NSRect(x: 18, y: height - 52, width: 44, height: 40)
        box.addSubview(emoji)

        let tLabel = NSTextField(labelWithString: title)
        tLabel.font = NSFont.boldSystemFont(ofSize: 14)
        tLabel.frame = NSRect(x: 18, y: 38, width: width - 36, height: 20)
        box.addSubview(tLabel)

        let sLabel = NSTextField(labelWithString: subtitle)
        sLabel.font = NSFont.systemFont(ofSize: 11)
        sLabel.textColor = .secondaryLabelColor
        sLabel.frame = NSRect(x: 18, y: 18, width: width - 36, height: 18)
        box.addSubview(sLabel)

        // Overlay transparent button
        let button = NSButton(frame: NSRect(x: 0, y: 0, width: width, height: height))
        button.title = ""
        button.isTransparent = true
        button.target = self
        button.action = action
        box.addSubview(button)

        return box
    }

    // ==========================================
    // 3. RIGHT INSPECTOR: CROSSOVER OPTIONS & TOOLS
    // ==========================================
    func buildRightInspector(width: CGFloat, height: CGFloat) -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.4).cgColor

        var y: CGFloat = height - 40
        let headerLabel = NSTextField(labelWithString: "CONFIGURACIÓN")
        headerLabel.font = NSFont.boldSystemFont(ofSize: 11)
        headerLabel.textColor = .secondaryLabelColor
        headerLabel.frame = NSRect(x: 16, y: y, width: 200, height: 18)
        view.addSubview(headerLabel)
        y -= 30

        // Switches Section (Like CrossOver)
        d3dMetalSwitch = NSButton(checkboxWithTitle: "D3DMetal (DirectX a Metal)", target: nil, action: nil)
        d3dMetalSwitch.state = .on
        d3dMetalSwitch.frame = NSRect(x: 16, y: y, width: 220, height: 20)
        view.addSubview(d3dMetalSwitch)
        y -= 26

        msyncSwitch = NSButton(checkboxWithTitle: "MSync (Semáforos Mach)", target: nil, action: nil)
        msyncSwitch.state = .on
        msyncSwitch.frame = NSRect(x: 16, y: y, width: 220, height: 20)
        view.addSubview(msyncSwitch)
        y -= 26

        hudSwitch = NSButton(checkboxWithTitle: "Metal Performance HUD", target: nil, action: nil)
        hudSwitch.frame = NSRect(x: 16, y: y, width: 220, height: 20)
        view.addSubview(hudSwitch)
        y -= 35

        // Scale & Backend Selectors
        let scaleLbl = NSTextField(labelWithString: "Escala de Pantalla:")
        scaleLbl.font = NSFont.systemFont(ofSize: 11)
        scaleLbl.frame = NSRect(x: 16, y: y, width: 120, height: 18)
        view.addSubview(scaleLbl)
        y -= 24

        scalePopUp = NSPopUpButton(frame: NSRect(x: 14, y: y, width: 230, height: 24))
        scalePopUp.addItems(withTitles: ["Auto (Adaptable)", "1.5x", "1.75x", "2.0x (Grande)", "2.25x"])
        view.addSubview(scalePopUp)
        y -= 35

        let backLbl = NSTextField(labelWithString: "Backend Gráfico:")
        backLbl.font = NSFont.systemFont(ofSize: 11)
        backLbl.frame = NSRect(x: 16, y: y, width: 120, height: 18)
        view.addSubview(backLbl)
        y -= 24

        backendPopUp = NSPopUpButton(frame: NSRect(x: 14, y: y, width: 230, height: 24))
        backendPopUp.addItems(withTitles: ["gptk (Apple D3DMetal)", "dxmt (DirectX 11)", "dxvk (Vulkan/MoltenVK)", "wined3d"])
        view.addSubview(backendPopUp)
        y -= 45

        // Tools Section (Like CrossOver Control Panel)
        let toolsLabel = NSTextField(labelWithString: "HERRAMIENTAS DE BOTELLA")
        toolsLabel.font = NSFont.boldSystemFont(ofSize: 11)
        toolsLabel.textColor = .secondaryLabelColor
        toolsLabel.frame = NSRect(x: 16, y: y, width: 200, height: 18)
        view.addSubview(toolsLabel)
        y -= 32

        let tools = [
            ("⚙️ Configuración de Wine", #selector(openWinecfg)),
            ("📝 Editor del Registro", #selector(openRegedit)),
            ("📊 Administrador de Tareas", #selector(openTaskmgr)),
            ("💻 Símbolo del Sistema (cmd)", #selector(openCmd)),
            ("🛑 Detener Botella (Kill)", #selector(killProcesses))
        ]

        for (title, selector) in tools {
            let btn = NSButton(title: title, target: self, action: selector)
            btn.bezelStyle = .rounded
            btn.alignment = .left
            btn.frame = NSRect(x: 14, y: y, width: 230, height: 28)
            view.addSubview(btn)
            y -= 34
        }

        return view
    }

    // ==========================================
    // ACTIONS & PROCESS EXECUTION
    // ==========================================
    func getSelectedScale() -> String {
        switch scalePopUp.titleOfSelectedItem ?? "" {
        case "1.5x": return "1.5"
        case "1.75x": return "1.75"
        case "2.0x (Grande)": return "2.0"
        case "2.25x": return "2.25"
        default: return "auto"
        }
    }

    func getSelectedBackend() -> String {
        let sel = backendPopUp.titleOfSelectedItem ?? ""
        if sel.contains("dxmt") { return "dxmt" }
        if sel.contains("dxvk") { return "dxvk" }
        if sel.contains("wined3d") { return "wined3d" }
        return "gptk"
    }

    @objc func launchSteam() {
        statusLabel.stringValue = "Iniciando Steam para Windows con aceleración Metal..."
        var args = ["steam", "--scale", getSelectedScale(), "--backend", getSelectedBackend()]
        if hudSwitch.state == .on { args.append("--hud") }
        runCommand(args: args)
    }

    @objc func launchEpic() {
        statusLabel.stringValue = "Iniciando Epic Games Store..."
        var args = ["epic", "--backend", getSelectedBackend()]
        if hudSwitch.state == .on { args.append("--hud") }
        runCommand(args: args)
    }

    @objc func chooseAndRunExe() {
        let panel = NSOpenPanel()
        panel.title = "Selecciona un archivo .EXE de Windows"
        panel.allowedContentTypes = []
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            let path = url.path
            statusLabel.stringValue = "Ejecutando: \(url.lastPathComponent)..."
            var args = ["run", path, "--backend", getSelectedBackend()]
            if hudSwitch.state == .on { args.append("--hud") }
            runCommand(args: args)
        }
    }

    @objc func openDriveC() {
        let cPath = defaultPrefix + "/drive_c"
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: cPath)
        statusLabel.stringValue = "Abierto disco C: en el Finder."
    }

    @objc func openWinecfg() {
        statusLabel.stringValue = "Abriendo Winecfg..."
        runCommand(args: ["winecfg"])
    }

    @objc func openRegedit() {
        statusLabel.stringValue = "Abriendo Editor del Registro..."
        runCommand(args: ["regedit"])
    }

    @objc func openTaskmgr() {
        statusLabel.stringValue = "Abriendo Administrador de Tareas..."
        runCommand(args: ["taskmgr"])
    }

    @objc func openCmd() {
        statusLabel.stringValue = "Abriendo Consola de Windows (cmd.exe)..."
        runCommand(args: ["cmd"])
    }

    @objc func killProcesses() {
        statusLabel.stringValue = "Deteniendo todos los procesos de la botella..."
        runCommand(args: ["kill"])
    }

    @objc func newBottleAction() {
        let alert = NSAlert()
        alert.messageText = "Nueva Botella de ma-proton"
        alert.informativeText = "Se ha creado la botella Default con Windows 10 64-bit y compatibilidad Metal nativa."
        alert.runModal()
    }

    func runCommand(args: [String]) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.maProtonBin)
            process.arguments = args

            do {
                try process.run()
                DispatchQueue.main.async {
                    self.statusLabel.stringValue = "Ejecutando: ma-proton \(args.joined(separator: " "))"
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusLabel.stringValue = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

// TableView Delegate & DataSource for Bottles List
extension CrossOverStyleLauncherDelegate: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return bottleList.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = NSTableCellView()
        let name = bottleList[row]

        let icon = NSTextField(labelWithString: "🍾")
        icon.font = NSFont.systemFont(ofSize: 16)
        icon.frame = NSRect(x: 5, y: 6, width: 24, height: 20)
        cell.addSubview(icon)

        let label = NSTextField(labelWithString: name)
        label.font = (row == currentBottleIndex) ? NSFont.boldSystemFont(ofSize: 13) : NSFont.systemFont(ofSize: 13)
        label.frame = NSRect(x: 32, y: 6, width: 150, height: 20)
        cell.addSubview(label)

        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        currentBottleIndex = bottleTableView.selectedRow
        bottleTableView.reloadData()
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 34
    }
}

struct PathHelper {
    static func prefixPath() -> String {
        return NSHomeDirectory() + "/.ma-proton/prefixes/default"
    }
}

let app = NSApplication.shared
let delegate = CrossOverStyleLauncherDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
