import AppKit
import WebKit

final class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKNavigationDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    
    let runnerBinary = "/Users/rhythmcreative/.local/bin/ma-proton"
    let prefixPath = NSHomeDirectory() + "/.ma-proton/prefixes/default"

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindow()
    }

    func setupWindow() {
        let width: CGFloat = 960
        let height: CGFloat = 660

        let rect = NSRect(x: 0, y: 0, width: width, height: height)
        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "ma-proton"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.minSize = NSSize(width: 860, height: 580)
        window.isReleasedWhenClosed = false

        // WebKit Configuration
        let config = WKWebViewConfiguration()
        let userContent = WKUserContentController()
        userContent.add(self, name: "maProton")
        config.userContentController = userContent
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        webView = WKWebView(frame: rect, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground") // Transparent native background

        window.contentView = webView

        loadAppUI()

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - IPC Message Handler (JS to Swift)
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let data = message.body as? [String: Any],
              let action = data["action"] as? String else { return }

        let scale = data["scale"] as? String ?? "auto"
        let backend = data["backend"] as? String ?? "gptk"
        let hud = data["hud"] as? Bool ?? false

        switch action {
        case "launch_steam":
            var args = ["steam", "--scale", scale, "--backend", backend]
            if hud { args.append("--hud") }
            runCLI(args: args, taskName: "Launching Windows Steam...")

        case "launch_epic":
            var args = ["epic", "--backend", backend]
            if hud { args.append("--hud") }
            runCLI(args: args, taskName: "Launching Epic Games Store...")

        case "choose_exe":
            selectAndRunCustomExe(backend: backend, hud: hud)

        case "open_drive_c":
            let url = URL(fileURLWithPath: prefixPath + "/drive_c")
            NSWorkspace.shared.activateFileViewerSelecting([url])
            sendNotificationToUI("Opened virtual C: drive in Finder.")

        case "run_wine_tool":
            if let tool = data["tool"] as? String {
                runCLI(args: [tool], taskName: "Opening \(tool)...")
            }

        case "kill_all":
            runCLI(args: ["kill"], taskName: "Stopping all Wine processes...")

        default:
            break
        }
    }

    func selectAndRunCustomExe(backend: String, hud: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let panel = NSOpenPanel()
            panel.title = "Select Windows Executable (.exe)"
            panel.allowedContentTypes = []
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true

            if panel.runModal() == .OK, let url = panel.url {
                var args = ["run", url.path, "--backend", backend]
                if hud { args.append("--hud") }
                self.runCLI(args: args, taskName: "Running: \(url.lastPathComponent)...")
            }
        }
    }

    func runCLI(args: [String], taskName: String) {
        sendNotificationToUI(taskName)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.runnerBinary)
            process.arguments = args

            do {
                try process.run()
                DispatchQueue.main.async {
                    self.sendNotificationToUI("Active: \(args.joined(separator: " "))")
                }
            } catch {
                DispatchQueue.main.async {
                    self.sendNotificationToUI("Error: \(error.localizedDescription)")
                }
            }
        }
    }

    func sendNotificationToUI(_ message: String) {
        let escaped = message.replacingOccurrences(of: "'", with: "\\'")
        let js = "window.showStatus('\(escaped)');"
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    // MARK: - HTML/CSS UI
    func loadAppUI() {
        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>ma-proton</title>
            <style>
                :root {
                    --bg-base: #111419;
                    --bg-surface: #181c24;
                    --bg-card: #1e232d;
                    --bg-card-hover: #262c38;
                    --border: #2c3340;
                    --border-focus: #0071e3;
                    --accent: #0071e3;
                    --accent-purple: #7852ff;
                    --accent-green: #30d158;
                    --accent-orange: #ff9f0a;
                    --accent-red: #ff453a;
                    --text-primary: #f5f5f7;
                    --text-secondary: #86868b;
                    --text-muted: #555b68;
                }

                * {
                    box-sizing: border-box;
                    margin: 0;
                    padding: 0;
                    user-select: none;
                    -webkit-user-select: none;
                }

                body {
                    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", sans-serif;
                    background-color: var(--bg-base);
                    color: var(--text-primary);
                    height: 100vh;
                    overflow: hidden;
                    display: flex;
                    flex-direction: column;
                }

                /* Window Dragging Header */
                .titlebar-drag-region {
                    height: 48px;
                    -webkit-app-region: drag;
                    display: flex;
                    align-items: center;
                    padding-left: 80px;
                    padding-right: 24px;
                    border-bottom: 1px solid var(--border);
                    background: rgba(24, 28, 36, 0.7);
                    backdrop-filter: blur(20px);
                    -webkit-backdrop-filter: blur(20px);
                }

                .brand-title {
                    font-size: 13px;
                    font-weight: 600;
                    letter-spacing: 0.3px;
                    display: flex;
                    align-items: center;
                    gap: 10px;
                }

                .brand-tag {
                    font-size: 10px;
                    font-weight: 700;
                    text-transform: uppercase;
                    background: rgba(0, 113, 227, 0.2);
                    color: #2997ff;
                    padding: 2px 7px;
                    border-radius: 4px;
                    border: 1px solid rgba(41, 151, 255, 0.3);
                }

                .system-info {
                    margin-left: auto;
                    font-size: 11px;
                    color: var(--text-secondary);
                    display: flex;
                    align-items: center;
                    gap: 12px;
                    -webkit-app-region: no-drag;
                }

                .status-dot {
                    width: 7px;
                    height: 7px;
                    border-radius: 50%;
                    background: var(--accent-green);
                    box-shadow: 0 0 8px rgba(48, 209, 88, 0.6);
                }

                /* Layout */
                .app-body {
                    flex: 1;
                    display: flex;
                    overflow: hidden;
                }

                /* Sidebar */
                .sidebar {
                    width: 220px;
                    background: rgba(18, 21, 27, 0.5);
                    border-right: 1px solid var(--border);
                    display: flex;
                    flex-direction: column;
                    padding: 18px 12px;
                }

                .sidebar-section-title {
                    font-size: 10px;
                    font-weight: 700;
                    letter-spacing: 0.8px;
                    text-transform: uppercase;
                    color: var(--text-muted);
                    padding: 0 10px 10px;
                }

                .bottle-item {
                    display: flex;
                    align-items: center;
                    gap: 12px;
                    padding: 10px 12px;
                    border-radius: 8px;
                    cursor: pointer;
                    background: rgba(0, 113, 227, 0.15);
                    border: 1px solid rgba(0, 113, 227, 0.3);
                    margin-bottom: 6px;
                }

                .bottle-icon {
                    width: 24px;
                    height: 24px;
                    fill: #2997ff;
                }

                .bottle-details {
                    display: flex;
                    flex-direction: column;
                    gap: 2px;
                }

                .bottle-name {
                    font-size: 13px;
                    font-weight: 600;
                }

                .bottle-sub {
                    font-size: 10px;
                    color: var(--text-secondary);
                }

                /* Main Content Area */
                .main-view {
                    flex: 1;
                    overflow-y: auto;
                    padding: 26px 32px;
                    display: flex;
                    flex-direction: column;
                    gap: 28px;
                }

                .section-header {
                    display: flex;
                    align-items: baseline;
                    justify-content: space-between;
                }

                .section-title {
                    font-size: 11px;
                    font-weight: 700;
                    letter-spacing: 0.7px;
                    text-transform: uppercase;
                    color: var(--text-muted);
                }

                /* App Grid */
                .apps-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
                    gap: 16px;
                }

                .app-card {
                    background: var(--bg-card);
                    border: 1px solid var(--border);
                    border-radius: 12px;
                    padding: 18px;
                    display: flex;
                    flex-direction: column;
                    gap: 14px;
                    cursor: pointer;
                    transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
                }

                .app-card:hover {
                    background: var(--bg-card-hover);
                    border-color: #3e4758;
                    transform: translateY(-2px);
                    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
                }

                .app-card-top {
                    display: flex;
                    align-items: center;
                    gap: 14px;
                }

                .app-card-icon {
                    width: 44px;
                    height: 44px;
                    border-radius: 10px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    flex-shrink: 0;
                }

                .app-card-icon svg {
                    width: 26px;
                    height: 26px;
                }

                .app-card-meta {
                    display: flex;
                    flex-direction: column;
                    gap: 3px;
                }

                .app-card-title {
                    font-size: 14px;
                    font-weight: 600;
                    color: var(--text-primary);
                }

                .app-card-subtitle {
                    font-size: 11px;
                    color: var(--text-secondary);
                }

                .app-card-desc {
                    font-size: 12px;
                    color: var(--text-secondary);
                    line-height: 1.4;
                }

                .app-card-btn {
                    margin-top: auto;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    gap: 8px;
                    background: rgba(255, 255, 255, 0.08);
                    border: 1px solid rgba(255, 255, 255, 0.12);
                    color: var(--text-primary);
                    padding: 8px 14px;
                    border-radius: 6px;
                    font-size: 12px;
                    font-weight: 600;
                    transition: background 0.15s ease;
                }

                .app-card:hover .app-card-btn {
                    background: var(--accent);
                    border-color: var(--accent);
                    color: #fff;
                }

                /* Control Panel Box */
                .control-panel {
                    background: var(--bg-surface);
                    border: 1px solid var(--border);
                    border-radius: 12px;
                    padding: 20px;
                    display: flex;
                    flex-direction: column;
                    gap: 18px;
                }

                .controls-row {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                    gap: 16px;
                }

                .control-group {
                    display: flex;
                    flex-direction: column;
                    gap: 8px;
                }

                .control-label {
                    font-size: 12px;
                    font-weight: 600;
                    color: var(--text-secondary);
                }

                .pills-group {
                    display: flex;
                    background: rgba(0, 0, 0, 0.3);
                    border: 1px solid var(--border);
                    border-radius: 8px;
                    padding: 3px;
                    gap: 3px;
                }

                .pill-btn {
                    flex: 1;
                    background: transparent;
                    border: none;
                    color: var(--text-secondary);
                    padding: 6px 10px;
                    border-radius: 6px;
                    font-size: 11px;
                    font-weight: 500;
                    cursor: pointer;
                    text-align: center;
                    transition: all 0.15s ease;
                }

                .pill-btn.active {
                    background: var(--bg-card-hover);
                    color: #fff;
                    font-weight: 600;
                    box-shadow: 0 1px 4px rgba(0, 0, 0, 0.4);
                }

                /* Toggles */
                .toggles-group {
                    display: flex;
                    flex-wrap: wrap;
                    gap: 20px;
                    padding-top: 6px;
                    border-top: 1px solid rgba(255, 255, 255, 0.06);
                }

                .switch-container {
                    display: flex;
                    align-items: center;
                    gap: 10px;
                    cursor: pointer;
                }

                .switch-input {
                    appearance: none;
                    -webkit-appearance: none;
                    width: 36px;
                    height: 20px;
                    border-radius: 12px;
                    background: #333842;
                    position: relative;
                    outline: none;
                    cursor: pointer;
                    transition: background 0.2s ease;
                }

                .switch-input::after {
                    content: '';
                    position: absolute;
                    width: 16px;
                    height: 16px;
                    border-radius: 50%;
                    background: #fff;
                    top: 2px;
                    left: 2px;
                    transition: transform 0.2s ease;
                }

                .switch-input:checked {
                    background: var(--accent);
                }

                .switch-input:checked::after {
                    transform: translateX(16px);
                }

                .switch-text {
                    font-size: 12px;
                    color: var(--text-primary);
                }

                /* Tools Bar */
                .tools-grid {
                    display: flex;
                    flex-wrap: wrap;
                    gap: 10px;
                }

                .tool-btn {
                    background: rgba(255, 255, 255, 0.05);
                    border: 1px solid var(--border);
                    color: var(--text-primary);
                    padding: 8px 14px;
                    border-radius: 7px;
                    font-size: 11px;
                    font-weight: 500;
                    cursor: pointer;
                    display: flex;
                    align-items: center;
                    gap: 8px;
                    transition: all 0.15s ease;
                }

                .tool-btn:hover {
                    background: rgba(255, 255, 255, 0.1);
                    border-color: #4a5468;
                }

                .tool-btn.danger {
                    color: var(--accent-red);
                    border-color: rgba(255, 69, 58, 0.3);
                    background: rgba(255, 69, 58, 0.08);
                }

                .tool-btn.danger:hover {
                    background: var(--accent-red);
                    color: #fff;
                }

                /* Bottom Status Bar */
                .status-bar {
                    height: 32px;
                    border-top: 1px solid var(--border);
                    background: rgba(18, 21, 27, 0.6);
                    padding: 0 24px;
                    display: flex;
                    align-items: center;
                    font-size: 11px;
                    color: var(--text-secondary);
                }
            </style>
        </head>
        <body>
            <div class="titlebar-drag-region">
                <div class="brand-title">
                    <span>ma-proton</span>
                    <span class="brand-tag">Metal 3 Native</span>
                </div>
                <div class="system-info">
                    <div class="status-dot"></div>
                    <span>Apple Silicon M4 Max</span>
                    <span>•</span>
                    <span>MSync Active</span>
                </div>
            </div>

            <div class="app-body">
                <div class="sidebar">
                    <div class="sidebar-section-title">Bottles</div>
                    <div class="bottle-item">
                        <svg class="bottle-icon" viewBox="0 0 24 24">
                            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14.5v-9l6 4.5-6 4.5z"/>
                        </svg>
                        <div class="bottle-details">
                            <div class="bottle-name">Default</div>
                            <div class="bottle-sub">Windows 10 64-bit</div>
                        </div>
                    </div>
                </div>

                <div class="main-view">
                    <div>
                        <div class="section-header">
                            <div class="section-title">Applications</div>
                        </div>
                        <div class="apps-grid" style="margin-top: 14px;">
                            <!-- Steam Card -->
                            <div class="app-card" onclick="triggerAction('launch_steam')">
                                <div class="app-card-top">
                                    <div class="app-card-icon" style="background: rgba(0, 113, 227, 0.15);">
                                        <svg viewBox="0 0 24 24" fill="#2997ff">
                                            <path d="M12 2a10 10 0 0 0-10 10c0 4.76 3.32 8.74 7.78 9.73l2.84-4.14a3 3 0 0 1-.62-1.79 3 3 0 0 1 .49-1.63L8.9 11.75a4.5 4.5 0 0 1 7.6-3.25 4.5 4.5 0 0 1 1.05 4.9l-2.73 1.9a3 3 0 0 1-2.82 2.7l-2.6 3.8A10 10 0 0 0 12 22a10 10 0 0 0 10-10A10 10 0 0 0 12 2z"/>
                                        </svg>
                                    </div>
                                    <div class="app-card-meta">
                                        <div class="app-card-title">Valve Steam</div>
                                        <div class="app-card-subtitle">Windows Gaming Client</div>
                                    </div>
                                </div>
                                <div class="app-card-desc">
                                    Full Windows store and library unlocked with Direct3D to Metal translation.
                                </div>
                                <div class="app-card-btn">Launch Steam</div>
                            </div>

                            <!-- Epic Games Card -->
                            <div class="app-card" onclick="triggerAction('launch_epic')">
                                <div class="app-card-top">
                                    <div class="app-card-icon" style="background: rgba(120, 82, 255, 0.15);">
                                        <svg viewBox="0 0 24 24" fill="#a78bfa">
                                            <path d="M12 2L4 6v12l8 4 8-4V6l-8-4zm0 2.5l5.5 2.75v8.5L12 18.5l-5.5-2.75v-8.5L12 4.5z"/>
                                        </svg>
                                    </div>
                                    <div class="app-card-meta">
                                        <div class="app-card-title">Epic Games Store</div>
                                        <div class="app-card-subtitle">Launcher & Library</div>
                                    </div>
                                </div>
                                <div class="app-card-desc">
                                    Windows Epic Games Storefront and Unreal game engine titles.
                                </div>
                                <div class="app-card-btn">Launch Epic Games</div>
                            </div>

                            <!-- Standalone EXE Card -->
                            <div class="app-card" onclick="triggerAction('choose_exe')">
                                <div class="app-card-top">
                                    <div class="app-card-icon" style="background: rgba(48, 209, 88, 0.15);">
                                        <svg viewBox="0 0 24 24" fill="#30d158">
                                            <path d="M8 5v14l11-7z"/>
                                        </svg>
                                    </div>
                                    <div class="app-card-meta">
                                        <div class="app-card-title">Run .EXE Binary</div>
                                        <div class="app-card-subtitle">Custom Game or Installer</div>
                                    </div>
                                </div>
                                <div class="app-card-desc">
                                    Execute any portable Windows game, setup installer, or utility.
                                </div>
                                <div class="app-card-btn">Select Executable...</div>
                            </div>

                            <!-- Drive C: Card -->
                            <div class="app-card" onclick="triggerAction('open_drive_c')">
                                <div class="app-card-top">
                                    <div class="app-card-icon" style="background: rgba(255, 159, 10, 0.15);">
                                        <svg viewBox="0 0 24 24" fill="#ff9f0a">
                                            <path d="M4 6h16v12H4z M2 4v16h20V4H2zm6 8h2v2H8v-2z"/>
                                        </svg>
                                    </div>
                                    <div class="app-card-meta">
                                        <div class="app-card-title">Virtual C: Drive</div>
                                        <div class="app-card-subtitle">Windows Filesystem</div>
                                    </div>
                                </div>
                                <div class="app-card-desc">
                                    Browse Program Files, save files, and game directories in Finder.
                                </div>
                                <div class="app-card-btn">Open in Finder</div>
                            </div>
                        </div>
                    </div>

                    <!-- Bottle Configuration Box -->
                    <div class="control-panel">
                        <div class="controls-row">
                            <div class="control-group">
                                <div class="control-label">Screen Scaling</div>
                                <div class="pills-group" id="scaleGroup">
                                    <button class="pill-btn active" onclick="setScale('auto', this)">Auto</button>
                                    <button class="pill-btn" onclick="setScale('1.5', this)">1.50x</button>
                                    <button class="pill-btn" onclick="setScale('1.75', this)">1.75x</button>
                                    <button class="pill-btn" onclick="setScale('2.0', this)">2.00x</button>
                                </div>
                            </div>

                            <div class="control-group">
                                <div class="control-label">Graphics Engine</div>
                                <div class="pills-group" id="backendGroup">
                                    <button class="pill-btn active" onclick="setBackend('gptk', this)">D3DMetal</button>
                                    <button class="pill-btn" onclick="setBackend('dxmt', this)">DXMT</button>
                                    <button class="pill-btn" onclick="setBackend('dxvk', this)">DXVK</button>
                                </div>
                            </div>
                        </div>

                        <div class="toggles-group">
                            <label class="switch-container">
                                <input type="checkbox" class="switch-input" id="msyncCheck" checked>
                                <span class="switch-text">MSync Fast Synchronization</span>
                            </label>
                            <label class="switch-container">
                                <input type="checkbox" class="switch-input" id="hudCheck">
                                <span class="switch-text">Metal Performance HUD</span>
                            </label>
                        </div>
                    </div>

                    <!-- Maintenance Tools -->
                    <div>
                        <div class="section-title" style="margin-bottom: 12px;">Bottle Maintenance</div>
                        <div class="tools-grid">
                            <button class="tool-btn" onclick="triggerWineTool('winecfg')">Wine Configuration</button>
                            <button class="tool-btn" onclick="triggerWineTool('regedit')">Registry Editor</button>
                            <button class="tool-btn" onclick="triggerWineTool('taskmgr')">Task Manager</button>
                            <button class="tool-btn" onclick="triggerWineTool('cmd')">Command Prompt</button>
                            <button class="tool-btn danger" onclick="triggerAction('kill_all')">Stop All Processes</button>
                        </div>
                    </div>
                </div>
            </div>

            <div class="status-bar" id="statusBar">
                Ready • ma-proton translation engine initialized.
            </div>

            <script>
                let currentScale = 'auto';
                let currentBackend = 'gptk';

                function setScale(val, btn) {
                    currentScale = val;
                    document.querySelectorAll('#scaleGroup .pill-btn').forEach(b => b.classList.remove('active'));
                    btn.classList.add('active');
                }

                function setBackend(val, btn) {
                    currentBackend = val;
                    document.querySelectorAll('#backendGroup .pill-btn').forEach(b => b.classList.remove('active'));
                    btn.classList.add('active');
                }

                function triggerAction(actionName) {
                    const hud = document.getElementById('hudCheck').checked;
                    window.webkit.messageHandlers.maProton.postMessage({
                        action: actionName,
                        scale: currentScale,
                        backend: currentBackend,
                        hud: hud
                    });
                }

                function triggerWineTool(toolName) {
                    window.webkit.messageHandlers.maProton.postMessage({
                        action: 'run_wine_tool',
                        tool: toolName
                    });
                }

                window.showStatus = function(msg) {
                    document.getElementById('statusBar').innerText = msg;
                };
            </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
