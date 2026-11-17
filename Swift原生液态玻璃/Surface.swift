import AppKit
import MetalKit
import QuartzCore

private struct Uniforms {
    var drawableSize: SIMD2<Float>
    var logicalSize: SIMD2<Float>
    var phase: Float
    var scene: Float
}

@MainActor
private final class BackgroundRenderer {
    let device: MTLDevice
    let queue: MTLCommandQueue
    let pipeline: MTLRenderPipelineState

    init() throws {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue(),
              let source = Bundle.main.url(forResource: "Background", withExtension: "metal") else {
            throw CocoaError(.featureUnsupported)
        }
        self.device = device
        self.queue = queue
        let library = try device.makeLibrary(source: String(contentsOf: source, encoding: .utf8), options: nil)
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "fullscreen")
        descriptor.fragmentFunction = library.makeFunction(name: "background")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func encode(pass: MTLRenderPassDescriptor, command: MTLCommandBuffer, uniforms: Uniforms) throws {
        guard let encoder = command.makeRenderCommandEncoder(descriptor: pass) else {
            throw CocoaError(.featureUnsupported)
        }
        var uniforms = uniforms
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
    }

    func snapshot(width: Int, height: Int, phase: Float, scene: Int) throws -> NSBitmapImageRep {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
            width: width, height: height, mipmapped: false)
        descriptor.usage = .renderTarget
        descriptor.storageMode = .shared
        guard let texture = device.makeTexture(descriptor: descriptor), let command = queue.makeCommandBuffer() else {
            throw CocoaError(.featureUnsupported)
        }
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = texture
        pass.colorAttachments[0].loadAction = .dontCare
        pass.colorAttachments[0].storeAction = .store
        try encode(pass: pass, command: command, uniforms: Uniforms(drawableSize: SIMD2(Float(width), Float(height)),
            logicalSize: SIMD2(1180, 820), phase: phase, scene: Float(scene)))
        command.commit()
        command.waitUntilCompleted()
        if let error = command.error { throw error }
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        texture.getBytes(&bytes, bytesPerRow: width * 4,
            from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
                    .union(.byteOrder32Little), provider: provider, decode: nil,
                shouldInterpolate: false, intent: .defaultIntent) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return NSBitmapImageRep(cgImage: image)
    }
}

@MainActor
private final class BackgroundView: MTKView {
    let renderer: BackgroundRenderer
    var phase: Float = 0
    var scene = 0
    var lastTime = CACurrentMediaTime()
    var advancing = true
    private(set) var renderFailure: Error?

    init(renderer: BackgroundRenderer) {
        self.renderer = renderer
        super.init(frame: .zero, device: renderer.device)
        colorPixelFormat = .bgra8Unorm
        colorspace = CGColorSpace(name: CGColorSpace.sRGB)
        preferredFramesPerSecond = 60
        enableSetNeedsDisplay = false
        isPaused = true
        setAccessibilityElement(false)
    }
    required init(coder: NSCoder) { fatalError("init(coder:) is unsupported") }

    override func draw(_ dirtyRect: NSRect) {
        guard let pass = currentRenderPassDescriptor, let drawable = currentDrawable,
              let command = renderer.queue.makeCommandBuffer() else { return }
        let now = CACurrentMediaTime()
        if advancing { phase += Float(min(max(now - lastTime, 0), 0.05)) }
        lastTime = now
        do {
            try renderer.encode(pass: pass, command: command, uniforms: Uniforms(
                drawableSize: SIMD2(Float(drawableSize.width), Float(drawableSize.height)),
                logicalSize: SIMD2(Float(bounds.width), Float(bounds.height)), phase: phase, scene: Float(scene)))
            command.present(drawable)
            command.commit()
        } catch {
            renderFailure = error
            isPaused = true
            NSLog("Background rendering failed: %@", error.localizedDescription)
        }
    }
}

@MainActor
private final class ToolButton: NSButton {
    private var hovered = false
    override var acceptsFirstResponder: Bool { true }
    override func becomeFirstResponder() -> Bool { needsDisplay = true; return true }
    override func resignFirstResponder() -> Bool { needsDisplay = true; return true }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 || event.keyCode == 36 { performClick(nil) }
        else { super.keyDown(with: event) }
    }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self, userInfo: nil))
    }
    override func mouseEntered(with event: NSEvent) { hovered = true; needsDisplay = true }
    override func mouseExited(with event: NSEvent) { hovered = false; needsDisplay = true }
    override func draw(_ dirtyRect: NSRect) {
        let focused = window?.firstResponder === self
        NSColor.white.withAlphaComponent(hovered || focused ? 0.25 : 0.12).setFill()
        let path = NSBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1))
        path.fill()
        NSColor.white.withAlphaComponent(focused ? 0.88 : 0.33).setStroke()
        path.lineWidth = focused ? 2 : 1
        path.stroke()
        let string = NSAttributedString(string: title, attributes: [.font: NSFont.systemFont(ofSize: 22), .foregroundColor: NSColor.white])
        let size = string.size()
        string.draw(at: NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2))
    }
}

@MainActor
private final class SurfaceContent: NSView {
    weak var owner: SurfaceView?
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    private var anchor = NSPoint.zero
    private(set) var labels = [NSTextField]()

    override init(frame: NSRect) {
        super.init(frame: frame)
        for (text, size, weight) in [
            ("Liquid Glass", 18.0, NSFont.Weight.medium), ("09:41", 100.36, .light),
            ("☀  23°", 19.0, .regular), ("周二 · 11月17日", 15.0, .regular)
        ] {
            let label = NSTextField(labelWithString: text)
            label.font = .systemFont(ofSize: size, weight: weight)
            label.textColor = .white
            label.lineBreakMode = .byClipping
            addSubview(label)
            labels.append(label)
        }
        labels[1].alignment = .center
        labels[3].alignment = .right
        labels[1].setAccessibilityLabel("示例时间，九点四十一分")
        labels[2].setAccessibilityLabel("示例天气，晴，二十三度")
        setAccessibilityRole(.group)
        setAccessibilityLabel("液态玻璃面板，拖动或使用方向键移动")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unsupported") }

    override func layout() {
        super.layout()
        labels[0].frame = NSRect(x: 34, y: 28, width: 230, height: 25)
        let fontSize = min(bounds.height * 0.26, 104)
        labels[1].attributedStringValue = NSAttributedString(string: "09:41", attributes: [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .light), .kern: -3,
            .foregroundColor: NSColor.white,
            .paragraphStyle: { let p = NSMutableParagraphStyle(); p.alignment = .center; return p }()
        ])
        let textHeight = ceil(labels[1].font?.boundingRectForFont.height ?? fontSize * 1.2)
        labels[1].frame = NSRect(x: 0, y: (bounds.height - textHeight) / 2 - 5, width: bounds.width, height: textHeight)
        labels[2].frame = NSRect(x: 36, y: bounds.height - 60, width: 140, height: 27)
        labels[3].frame = NSRect(x: bounds.width - 236, y: bounds.height - 56, width: 200, height: 25)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.withAlphaComponent(0.16).setFill()
        NSRect(x: 34, y: bounds.height - 85, width: bounds.width - 68, height: 1).fill()
        NSColor.white.withAlphaComponent(0.77).setFill()
        for index in 0..<3 {
            NSBezierPath(ovalIn: NSRect(x: bounds.width - 59 + CGFloat(index) * 9, y: 37, width: 4, height: 4)).fill()
        }
        if window?.firstResponder === self {
            NSColor.white.withAlphaComponent(0.46).setStroke()
            let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 4), xRadius: 52, yRadius: 52)
            path.lineWidth = 1
            path.stroke()
        }
    }
    override func hitTest(_ point: NSPoint) -> NSView? { bounds.contains(convert(point, from: superview)) ? self : nil }
    override func becomeFirstResponder() -> Bool { needsDisplay = true; return true }
    override func resignFirstResponder() -> Bool { needsDisplay = true; return true }
    override func mouseDown(with event: NSEvent) {
        guard let owner else { return }
        window?.makeFirstResponder(self)
        let point = owner.convert(event.locationInWindow, from: nil)
        anchor = NSPoint(x: point.x - owner.glass.frame.minX, y: point.y - owner.glass.frame.minY)
    }
    override func mouseDragged(with event: NSEvent) {
        guard let owner else { return }
        let point = owner.convert(event.locationInWindow, from: nil)
        owner.movePanel(to: NSPoint(x: point.x - anchor.x, y: point.y - anchor.y))
    }
    override func keyDown(with event: NSEvent) {
        guard let owner else { return }
        var point = owner.glass.frame.origin
        switch event.keyCode {
        case 123: point.x -= 10
        case 124: point.x += 10
        case 125: point.y += 10
        case 126: point.y -= 10
        case 49: owner.togglePause(nil); return
        case 53: window?.performClose(nil); return
        default: super.keyDown(with: event); return
        }
        owner.movePanel(to: point)
    }
}

@MainActor
private final class SurfaceView: NSView {
    let background: BackgroundView
    let glass = NSGlassEffectView()
    let content = SurfaceContent(frame: .zero)
    private(set) var controls = [ToolButton]()
    private(set) var paused = false
    private(set) var regular = false
    var forceSolid = false
    var forceStill = false
    private(set) var panelMoved = false
    override var isFlipped: Bool { true }

    init(renderer: BackgroundRenderer) {
        background = BackgroundView(renderer: renderer)
        super.init(frame: NSRect(x: 0, y: 0, width: 1180, height: 820))
        wantsLayer = true
        addSubview(background)
        glass.cornerRadius = 56
        glass.style = .clear
        glass.appearance = NSAppearance(named: .darkAqua)
        glass.contentView = content
        content.owner = self
        addSubview(glass)
        for (symbol, action, label) in [
            ("Ⅱ", #selector(togglePause(_:)), "暂停背景"),
            ("▧", #selector(toggleScene(_:)), "切换折射对照色带"),
            ("◒", #selector(toggleMaterial(_:)), "切换 Regular 系统材质")
        ] {
            let button = ToolButton(title: symbol, target: self, action: action)
            button.isBordered = false
            button.focusRingType = .none
            button.toolTip = label
            button.setAccessibilityLabel(label)
            addSubview(button)
            controls.append(button)
        }
        refreshAccessibility()
        needsLayout = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unsupported") }

    override func layout() {
        super.layout()
        background.frame = bounds
        let size = NSSize(width: min(600, bounds.width - 130), height: min(386, bounds.height - 240))
        var origin = glass.frame.origin
        if !panelMoved { origin = NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2 - 25) }
        glass.frame = NSRect(origin: clamped(origin, size: size), size: size)
        content.frame = glass.isHidden ? glass.frame : NSRect(origin: .zero, size: size)
        for (index, control) in controls.enumerated() {
            control.frame = NSRect(x: (bounds.width - 188) / 2 + CGFloat(index) * 68, y: bounds.height - 95, width: 52, height: 52)
        }
    }

    func clamped(_ point: NSPoint, size: NSSize) -> NSPoint {
        NSPoint(x: min(max(28, point.x), bounds.width - size.width - 28),
            y: min(max(28, point.y), bounds.height - size.height - 105))
    }
    func movePanel(to point: NSPoint) {
        panelMoved = true
        glass.setFrameOrigin(clamped(point, size: glass.frame.size))
        if glass.isHidden { content.setFrameOrigin(glass.frame.origin) }
    }

    @objc func togglePause(_ sender: Any?) {
        paused.toggle()
        refreshAccessibility()
    }
    @objc func toggleScene(_ sender: Any?) {
        background.scene = 1 - background.scene
        let label = background.scene == 0 ? "切换折射对照色带" : "切换流动背景"
        controls[1].toolTip = label
        controls[1].setAccessibilityLabel(label)
        background.draw()
    }
    @objc func toggleMaterial(_ sender: Any?) {
        regular.toggle()
        glass.style = regular ? .regular : .clear
        let label = regular ? "切换 Clear 系统材质" : "切换 Regular 系统材质"
        controls[2].toolTip = label
        controls[2].setAccessibilityLabel(label)
    }

    @objc func refreshAccessibility() {
        let workspace = NSWorkspace.shared
        let solid = forceSolid || workspace.accessibilityDisplayShouldReduceTransparency
            || workspace.accessibilityDisplayShouldIncreaseContrast
        let still = forceStill || workspace.accessibilityDisplayShouldReduceMotion
        glass.isHidden = solid
        if solid {
            if content.superview === glass || content.superview !== self {
                glass.contentView = nil
                addSubview(content)
            }
            content.frame = glass.frame
            content.wantsLayer = true
            content.layer?.backgroundColor = NSColor(srgbRed: 0.18, green: 0.23, blue: 0.29, alpha: 1).cgColor
            content.layer?.cornerRadius = 56
        } else {
            content.layer?.backgroundColor = NSColor.clear.cgColor
            if glass.contentView !== content {
                content.removeFromSuperview()
                glass.contentView = content
            }
            content.frame = NSRect(origin: .zero, size: glass.frame.size)
        }
        let advancing = !paused && !still
        let frameRate = window?.screen?.maximumFramesPerSecond ?? 60
        if background.preferredFramesPerSecond != frameRate { background.preferredFramesPerSecond = frameRate }
        let visible = window.map { !$0.isMiniaturized && $0.occlusionState.contains(.visible) } ?? false
        let stop = !advancing || !visible
        if background.advancing != advancing || background.isPaused != stop {
            background.lastTime = CACurrentMediaTime()
            background.advancing = advancing
            background.isPaused = stop
            if stop { background.draw() }
        }
        let label = still ? "系统已减少动态效果" : paused ? "播放背景" : "暂停背景"
        if let button = controls.first {
            button.title = paused || still ? "▶" : "Ⅱ"
            button.toolTip = label
            button.setAccessibilityLabel(label)
        }
    }
}

@MainActor
private final class DemoDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow?
    var scene: SurfaceView?
    var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let renderer = try BackgroundRenderer()
            let scene = SurfaceView(renderer: renderer)
            let window = NSWindow(contentRect: scene.bounds,
                styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            window.title = "Swift · Liquid Glass"
            window.contentMinSize = NSSize(width: 760, height: 600)
            window.isReleasedWhenClosed = false
            window.contentView = scene
            window.delegate = self
            self.window = window
            self.scene = scene
            let menu = NSMenu()
            let item = NSMenuItem()
            let application = NSMenu()
            application.addItem(withTitle: "退出 Swift Liquid Surface", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            item.submenu = application
            menu.addItem(item)
            NSApp.mainMenu = menu
            window.center()
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(scene.content)
            NSApp.activate()
            scene.layoutSubtreeIfNeeded()
            scene.refreshAccessibility()
            if CommandLine.arguments.contains("--self-test") {
                scene.pausedForChecks()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { Checks.run(scene: scene, renderer: renderer) }
            } else {
                timer = Timer.scheduledTimer(timeInterval: 1, target: scene,
                    selector: #selector(SurfaceView.refreshAccessibility), userInfo: nil, repeats: true)
            }
        } catch {
            if CommandLine.arguments.contains("--self-test") {
                print("FAIL: \(error)")
                exit(1)
            }
            NSAlert(error: error).runModal()
            NSApp.terminate(nil)
        }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func windowDidMiniaturize(_ notification: Notification) { scene?.refreshAccessibility() }
    func windowDidDeminiaturize(_ notification: Notification) { scene?.refreshAccessibility() }
    func windowDidChangeOcclusionState(_ notification: Notification) { scene?.refreshAccessibility() }
    func windowWillClose(_ notification: Notification) { timer?.invalidate(); scene?.background.isPaused = true }
}

@MainActor
private extension SurfaceView {
    func pausedForChecks() {
        forceStill = true
        refreshAccessibility()
        background.phase = 0
    }
}

@MainActor
private enum Checks {
    static func delta(_ a: NSBitmapImageRep, _ b: NSBitmapImageRep, outsidePanel: Bool) -> Double {
        guard a.pixelsWide == b.pixelsWide, a.pixelsHigh == b.pixelsHigh else { return .infinity }
        var total = 0.0
        var count = 0
        for y in stride(from: 2, to: a.pixelsHigh, by: 8) {
            for x in stride(from: 2, to: a.pixelsWide, by: 8) {
                let px = Double(x) * 1180 / Double(a.pixelsWide)
                let py = Double(y) * 820 / Double(a.pixelsHigh)
                if outsidePanel && !(px < 140 || px > 1040 || py < 130 || py > 790) { continue }
                guard let p = a.colorAt(x: x, y: y)?.usingColorSpace(.sRGB),
                      let q = b.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { return .infinity }
                total += abs(p.redComponent - q.redComponent) + abs(p.greenComponent - q.greenComponent)
                    + abs(p.blueComponent - q.blueComponent)
                count += 3
            }
        }
        return count > 0 ? total * 255 / Double(count) : .infinity
    }

    static func run(scene: SurfaceView, renderer: BackgroundRenderer) {
        var count = 0
        var passed = true
        func check(_ value: Bool, _ message: String) {
            count += 1
            if !value { passed = false; print("FAIL: \(message)") }
        }
        func argument(_ name: String) -> String? {
            guard let index = CommandLine.arguments.firstIndex(of: name), index + 1 < CommandLine.arguments.count else { return nil }
            return CommandLine.arguments[index + 1]
        }
        do {
            scene.layoutSubtreeIfNeeded()
            scene.content.layoutSubtreeIfNeeded()
            check(scene.bounds.size == NSSize(width: 1180, height: 820), "Qt viewport geometry")
            check(scene.glass.frame == NSRect(x: 290, y: 192, width: 600, height: 386), "Qt panel geometry")
            check(scene.glass.cornerRadius == 56, "Qt corner radius")
            check(scene.glass.contentView === scene.content, "real content in native glass contentView")
            check(scene.glass.style == .clear, "default public Clear material")
            check(scene.content.labels.map(\.stringValue) == ["Liquid Glass", "09:41", "☀  23°", "周二 · 11月17日"], "matching Qt labels")
            check(scene.controls.count == 3 && scene.controls[0].frame == NSRect(x: 496, y: 725, width: 52, height: 52), "Qt control geometry")
            check(scene.controls.allSatisfy { $0.acceptsFirstResponder }, "keyboard-focusable comparison controls")
            check(scene.content.labels[0].font?.pointSize == 18, "Qt heading nominal font size")
            let clockFont = scene.content.labels[1].attributedStringValue.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
            check(abs((clockFont?.pointSize ?? 0) - 100.36) < 0.01, "Qt clock nominal font size")
            check(scene.background.isPaused && !scene.background.advancing, "reduced motion pauses the background")
            check(scene.background.preferredFramesPerSecond == (scene.window?.screen?.maximumFramesPerSecond ?? 60),
                  "background targets the window display refresh rate")
            scene.background.phase = 2
            scene.background.draw()
            check(scene.background.phase == 2, "paused redraw preserves the background phase")
            scene.toggleMaterial(nil)
            check(scene.glass.style == .regular, "public Regular switch")
            scene.toggleMaterial(nil)
            check(scene.glass.style == .clear, "restore Clear")
            scene.forceSolid = true
            scene.refreshAccessibility()
            check(scene.glass.isHidden && scene.content.superview === scene && scene.content.frame == scene.glass.frame,
                  "accessible opaque fallback keeps content geometry")
            scene.movePanel(to: NSPoint(x: -500, y: 900))
            check(scene.glass.frame.origin == NSPoint(x: 28, y: 329), "drag bounds")
            check(scene.content.frame == scene.glass.frame, "solid content follows dragging")
            scene.forceSolid = false
            scene.refreshAccessibility()
            check(scene.glass.contentView === scene.content && !scene.glass.isHidden, "restore native content ownership")
            scene.movePanel(to: NSPoint(x: 290, y: 192))
            scene.setFrameSize(NSSize(width: 760, height: 600))
            scene.needsLayout = true
            scene.layoutSubtreeIfNeeded()
            check(scene.bounds.contains(scene.glass.frame), "native resized panel stays in bounds")
            scene.setFrameSize(NSSize(width: 1180, height: 820))
            scene.needsLayout = true
            scene.layoutSubtreeIfNeeded()
            check(scene.background.renderFailure == nil, "native Metal view has no recorded encode error")

            let first = try renderer.snapshot(width: 1180, height: 820, phase: 0, scene: 1)
            let moved = try renderer.snapshot(width: 1180, height: 820, phase: 1.8, scene: 1)
            let motion = delta(first, moved, outsidePanel: false)
            check(motion > 5, "native background GPU motion")
            var report: [String: Any] = ["backgroundMotionDelta": motion,
                "glass": "NSGlassEffectView", "glassVisualAcceptance": "manual, not tested by offscreen background capture",
                "viewport": "1180x820", "panel": "600x386", "radius": 56]
            if let directory = argument("--qt-reference-dir") {
                for (name, phase, style) in [("01-no-refraction", Float(0), 1), ("07-interface", Float(3.6), 0)] {
                    let url = URL(fileURLWithPath: directory).appendingPathComponent(name + ".png")
                    let reference = try NSBitmapImageRep(data: Data(contentsOf: url))
                    guard let reference else { throw CocoaError(.fileReadCorruptFile) }
                    let native = try renderer.snapshot(width: reference.pixelsWide, height: reference.pixelsHigh, phase: phase, scene: style)
                    let error = delta(native, reference, outsidePanel: true)
                    print("Qt/native background \(name) mean channel delta: \(error)/255")
                    check(error < 1.5, "Qt/native background parity: \(name)")
                    report[name + "BackgroundDelta"] = error
                }
            } else {
                print("SKIP: Qt background image comparison; provide --qt-reference-dir")
                report["qtBackgroundComparison"] = "not run"
            }
            if let directory = argument("--evidence-dir") {
                let url = URL(fileURLWithPath: directory, isDirectory: true)
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                guard let png = first.representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
                try png.write(to: url.appendingPathComponent("native-background-only.png"))
                report["checks"] = count
                report["passed"] = passed
                try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
                    .write(to: url.appendingPathComponent("comparison-checks.json"))
            }
            print("\(passed ? "PASS" : "FAIL") \(count) native structure/background checks; system glass appearance remains manual")
            if passed { NSApp.terminate(nil) } else { exit(1) }
        } catch {
            print("FAIL: \(error)")
            exit(1)
        }
    }
}

@main
enum SwiftLiquidSurface {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = DemoDelegate()
        app.setActivationPolicy(.regular)
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
