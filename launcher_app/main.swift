import AppKit
import Foundation

class LauncherAppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var statusLabel: NSTextField!
    var hudCheckbox: NSButton!
    var scalePopUp: NSPopUpButton!
    var backendPopUp: NSPopUpButton!
    let maProtonBin = "/Users/rhythmcreative/.local/bin/ma-proton"

    func applicationDidFinishLaunching(_ notification: Notification) {
        let windowWidth: CGFloat = 680
        let windowHeight: CGFloat = 520
        
        let rect = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)
        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "ma-proton Launcher"
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false

        let contentView = NSView(frame: rect)
        contentView.wantsLayer = true
        window.contentView = contentView

        var currentY: CGFloat = windowHeight - 50

        // 1. Header Title
        let titleLabel = NSTextField(labelWithString: "🚀 ma-proton Launcher")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 22)
        titleLabel.frame = NSRect(x: 30, y: currentY, width: 620, height: 30)
        contentView.addSubview(titleLabel)
        currentY -= 25

        let subtitleLabel = NSTextField(labelWithString: "Motor de traducción Proton para macOS • Apple Silicon & Metal")
        subtitleLabel.font = NSFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.frame = NSRect(x: 30, y: currentY, width: 620, height: 20)
        contentView.addSubview(subtitleLabel)
        currentY -= 45

        // 2. Steam Card Box
        let steamBox = createCardBox(
            title: "🎮 Valve Steam (Windows)",
            description: "Desbloquea el catálogo completo de Windows en tu Mac.",
            primaryTitle: "Lanzar Steam",
            primaryAction: #selector(launchSteam),
            secondaryTitle: "Reinstalar Steam",
            secondaryAction: #selector(reinstallSteam),
            y: currentY,
            parent: contentView
        )
        currentY -= 105

        // 3. Epic Games Card Box
        let epicBox = createCardBox(
            title: "⚡ Epic Games Store",
            description: "Instala y ejecuta tus juegos de Epic Games con Metal.",
            primaryTitle: "Lanzar Epic Games",
            primaryAction: #selector(launchEpic),
            secondaryTitle: "Instalar Epic Games",
            secondaryAction: #selector(installEpic),
            y: currentY,
            parent: contentView
        )
        currentY -= 105

        // 4. Custom Game Card Box
        let customBox = createSingleActionBox(
            title: "📂 Ejecutar Juego o Archivo .EXE",
            description: "Abre cualquier juego, instalador o ejecutable portable.",
            buttonTitle: "Seleccionar Archivo .EXE...",
            action: #selector(chooseAndRunExe),
            y: currentY,
            parent: contentView
        )
        currentY -= 80

        // 5. Settings Bar (Scale, HUD, Backend)
        let settingsBox = NSBox(frame: NSRect(x: 30, y: currentY, width: 620, height: 65))
        settingsBox.title = "Opciones Rápidas"
        settingsBox.titleFont = NSFont.boldSystemFont(ofSize: 11)
        contentView.addSubview(settingsBox)

        let settingsView = NSView(frame: settingsBox.bounds)
        settingsBox.contentView = settingsView

        // Scale PopUp
        let scaleLabel = NSTextField(labelWithString: "Escala:")
        scaleLabel.frame = NSRect(x: 15, y: 12, width: 50, height: 20)
        settingsView.addSubview(scaleLabel)

        scalePopUp = NSPopUpButton(frame: NSRect(x: 65, y: 10, width: 110, height: 24))
        scalePopUp.addItems(withTitles: ["Auto (Recom)", "1.5x", "1.75x", "2.0x (Grande)", "2.25x"])
        settingsView.addSubview(scalePopUp)

        // Backend PopUp
        let backendLabel = NSTextField(labelWithString: "Backend:")
        backendLabel.frame = NSRect(x: 190, y: 12, width: 60, height: 20)
        settingsView.addSubview(backendLabel)

        backendPopUp = NSPopUpButton(frame: NSRect(x: 250, y: 10, width: 120, height: 24))
        backendPopUp.addItems(withTitles: ["gptk (Metal)", "dxmt (D3D11)", "dxvk (Vulkan)", "wined3d"])
        settingsView.addSubview(backendPopUp)

        // Metal HUD Checkbox
        hudCheckbox = NSButton(checkboxWithTitle: "Metal HUD", target: nil, action: nil)
        hudCheckbox.frame = NSRect(x: 385, y: 12, width: 95, height: 20)
        settingsView.addSubview(hudCheckbox)

        // Kill Wine Button
        let killBtn = NSButton(title: "🛑 Detener Todo", target: self, action: #selector(killWineProcesses))
        killBtn.bezelStyle = .rounded
        killBtn.frame = NSRect(x: 485, y: 8, width: 115, height: 26)
        settingsView.addSubview(killBtn)

        currentY -= 40

        // 6. Status Bar
        statusLabel = NSTextField(labelWithString: "Listo. Selecciona una acción para comenzar.")
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.frame = NSRect(x: 35, y: 15, width: 610, height: 20)
        contentView.addSubview(statusLabel)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func createCardBox(
        title: String,
        description: String,
        primaryTitle: String,
        primaryAction: Selector,
        secondaryTitle: String,
        secondaryAction: Selector,
        y: CGFloat,
        parent: NSView
    ) -> NSBox {
        let box = NSBox(frame: NSRect(x: 30, y: y, width: 620, height: 95))
        box.boxType = .custom
        box.borderColor = .separatorColor
        box.borderWidth = 1.0
        box.cornerRadius = 8
        box.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.4)
        parent.addSubview(box)

        let tLabel = NSTextField(labelWithString: title)
        tLabel.font = NSFont.boldSystemFont(ofSize: 15)
        tLabel.frame = NSRect(x: 18, y: 58, width: 350, height: 22)
        box.addSubview(tLabel)

        let dLabel = NSTextField(labelWithString: description)
        dLabel.font = NSFont.systemFont(ofSize: 12)
        dLabel.textColor = .secondaryLabelColor
        dLabel.frame = NSRect(x: 18, y: 32, width: 350, height: 20)
        box.addSubview(dLabel)

        let primaryBtn = NSButton(title: primaryTitle, target: self, action: primaryAction)
        primaryBtn.bezelStyle = .rounded
        primaryBtn.keyEquivalent = "\r"
        primaryBtn.frame = NSRect(x: 460, y: 48, width: 140, height: 32)
        box.addSubview(primaryBtn)

        let secondaryBtn = NSButton(title: secondaryTitle, target: self, action: secondaryAction)
        secondaryBtn.bezelStyle = .rounded
        secondaryBtn.frame = NSRect(x: 460, y: 15, width: 140, height: 28)
        box.addSubview(secondaryBtn)

        return box
    }

    func createSingleActionBox(
        title: String,
        description: String,
        buttonTitle: String,
        action: Selector,
        y: CGFloat,
        parent: NSView
    ) -> NSBox {
        let box = NSBox(frame: NSRect(x: 30, y: y, width: 620, height: 70))
        box.boxType = .custom
        box.borderColor = .separatorColor
        box.borderWidth = 1.0
        box.cornerRadius = 8
        box.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.4)
        parent.addSubview(box)

        let tLabel = NSTextField(labelWithString: title)
        tLabel.font = NSFont.boldSystemFont(ofSize: 14)
        tLabel.frame = NSRect(x: 18, y: 38, width: 360, height: 20)
        box.addSubview(tLabel)

        let dLabel = NSTextField(labelWithString: description)
        dLabel.font = NSFont.systemFont(ofSize: 12)
        dLabel.textColor = .secondaryLabelColor
        dLabel.frame = NSRect(x: 18, y: 15, width: 360, height: 18)
        box.addSubview(dLabel)

        let btn = NSButton(title: buttonTitle, target: self, action: action)
        btn.bezelStyle = .rounded
        btn.frame = NSRect(x: 410, y: 18, width: 190, height: 32)
        box.addSubview(btn)

        return box
    }

    func getScaleParam() -> String {
        switch scalePopUp.titleOfSelectedItem ?? "" {
        case "1.5x": return "1.5"
        case "1.75x": return "1.75"
        case "2.0x (Grande)": return "2.0"
        case "2.25x": return "2.25"
        default: return "auto"
        }
    }

    func getBackendParam() -> String {
        let sel = backendPopUp.titleOfSelectedItem ?? ""
        if sel.contains("dxmt") { return "dxmt" }
        if sel.contains("dxvk") { return "dxvk" }
        if sel.contains("wined3d") { return "wined3d" }
        return "gptk"
    }

    @objc func launchSteam() {
        statusLabel.stringValue = "Iniciando Steam para Windows..."
        var args = ["steam", "--scale", getScaleParam(), "--backend", getBackendParam()]
        if hudCheckbox.state == .on { args.append("--hud") }
        runCommandInBackground(args: args)
    }

    @objc func reinstallSteam() {
        statusLabel.stringValue = "Descargando e instalando Steam..."
        runCommandInBackground(args: ["steam", "--scale", getScaleParam()])
    }

    @objc func launchEpic() {
        statusLabel.stringValue = "Iniciando Epic Games Store..."
        var args = ["epic", "--backend", getBackendParam()]
        if hudCheckbox.state == .on { args.append("--hud") }
        runCommandInBackground(args: args)
    }

    @objc func installEpic() {
        statusLabel.stringValue = "Descargando e instalando Epic Games Store..."
        runCommandInBackground(args: ["epic"])
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
            var args = ["run", path, "--backend", getBackendParam()]
            if hudCheckbox.state == .on { args.append("--hud") }
            runCommandInBackground(args: args)
        }
    }

    @objc func killWineProcesses() {
        statusLabel.stringValue = "Deteniendo todos los procesos de Wine..."
        runCommandInBackground(args: ["kill"])
    }

    func runCommandInBackground(args: [String]) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.maProtonBin)
            process.arguments = args

            do {
                try process.run()
                DispatchQueue.main.async {
                    self.statusLabel.stringValue = "Comando iniciado: \(args.joined(separator: " "))"
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusLabel.stringValue = "Error al iniciar: \(error.localizedDescription)"
                }
            }
        }
    }
}

let app = NSApplication.shared
let delegate = LauncherAppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
