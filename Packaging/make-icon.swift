// 產生 App 圖示：三條各自獨立的推桿，代表每個 App 各有一條音量。
// 純 CoreGraphics 向量繪製，每個尺寸直接在目標像素數重畫，小尺寸才不會糊掉。
//
// 用法：swift Packaging/make-icon.swift <輸出的 .iconset 目錄>
//       iconutil -c icns <該目錄> -o Packaging/AppIcon.icns
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let canvas: CGFloat = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        colorSpace: space,
        components: [
            CGFloat((hex >> 16) & 0xFF) / 255,
            CGFloat((hex >> 8) & 0xFF) / 255,
            CGFloat(hex & 0xFF) / 255,
            alpha,
        ]
    )!
}

func linearGradient(_ ctx: CGContext, _ colors: [CGColor], from start: CGPoint, to end: CGPoint) {
    let gradient = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: nil)!
    ctx.drawLinearGradient(gradient, start: start, end: end, options: [])
}

func drawIcon(in ctx: CGContext) {
    // macOS 圖示樣板：1024 畫布裡 824×824 的圓角方塊，四周留給陰影。
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let bodyPath = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0x000000, 0.35))
    ctx.addPath(bodyPath)
    ctx.setFillColor(color(0x1E1B4B))
    ctx.fillPath()
    ctx.restoreGState()

    // 底色：上方偏靛藍、下方偏深紫。
    ctx.saveGState()
    ctx.addPath(bodyPath)
    ctx.clip()
    linearGradient(
        ctx, [color(0x3B3FD9), color(0x2A1D6E), color(0x170F3A)],
        from: CGPoint(x: body.minX, y: body.maxY), to: CGPoint(x: body.maxX, y: body.minY)
    )
    // 上半部一層淡淡的反光。
    linearGradient(
        ctx, [color(0xFFFFFF, 0.16), color(0xFFFFFF, 0)],
        from: CGPoint(x: 0, y: body.maxY), to: CGPoint(x: 0, y: body.midY)
    )
    ctx.restoreGState()

    // 內緣細線，讓深色背景在深色 Dock／Finder 裡仍有邊界。
    ctx.saveGState()
    ctx.addPath(CGPath(
        roundedRect: body.insetBy(dx: 2, dy: 2), cornerWidth: 183, cornerHeight: 183, transform: nil
    ))
    ctx.setStrokeColor(color(0xFFFFFF, 0.14))
    ctx.setLineWidth(4)
    ctx.strokePath()
    ctx.restoreGState()

    // 三條推桿：位置、填色、推桿高度（0…1）。
    let faders: [(x: CGFloat, top: UInt32, bottom: UInt32, level: CGFloat)] = [
        (322, 0x67E8F9, 0x0891B2, 0.62),
        (512, 0xC4B5FD, 0x7C3AED, 0.34),
        (702, 0xF9A8D4, 0xDB2777, 0.82),
    ]
    let trackBottom: CGFloat = 250
    let trackTop: CGFloat = 774
    let trackWidth: CGFloat = 52

    for fader in faders {
        let track = CGRect(
            x: fader.x - trackWidth / 2, y: trackBottom,
            width: trackWidth, height: trackTop - trackBottom
        )
        let trackPath = CGPath(
            roundedRect: track, cornerWidth: trackWidth / 2, cornerHeight: trackWidth / 2, transform: nil
        )
        ctx.addPath(trackPath)
        ctx.setFillColor(color(0x000000, 0.28))
        ctx.fillPath()

        let knobY = trackBottom + (trackTop - trackBottom) * fader.level

        // 推桿以下的已填滿部分，帶一點光暈。
        let filled = CGRect(x: track.minX, y: track.minY, width: track.width, height: knobY - track.minY)
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 36, color: color(fader.top, 0.75))
        ctx.addPath(CGPath(
            roundedRect: filled, cornerWidth: trackWidth / 2, cornerHeight: trackWidth / 2, transform: nil
        ))
        ctx.clip()
        linearGradient(
            ctx, [color(fader.top), color(fader.bottom)],
            from: CGPoint(x: 0, y: knobY), to: CGPoint(x: 0, y: track.minY)
        )
        ctx.restoreGState()

        // 推桿頭：白色圓角塊，中間一道與軌道同色的刻線。
        let knob = CGRect(x: fader.x - 82, y: knobY - 44, width: 164, height: 88)
        let knobPath = CGPath(roundedRect: knob, cornerWidth: 30, cornerHeight: 30, transform: nil)
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 22, color: color(0x000000, 0.45))
        ctx.addPath(knobPath)
        ctx.setFillColor(color(0xFFFFFF))
        ctx.fillPath()
        ctx.restoreGState()

        ctx.saveGState()
        ctx.addPath(knobPath)
        ctx.clip()
        linearGradient(
            ctx, [color(0xFFFFFF), color(0xDCDDF2)],
            from: CGPoint(x: 0, y: knob.maxY), to: CGPoint(x: 0, y: knob.minY)
        )
        ctx.restoreGState()

        let groove = CGRect(x: fader.x - 46, y: knobY - 7, width: 92, height: 14)
        ctx.addPath(CGPath(roundedRect: groove, cornerWidth: 7, cornerHeight: 7, transform: nil))
        ctx.setFillColor(color(fader.bottom))
        ctx.fillPath()
    }
}

func render(pixels: Int, to url: URL) throws {
    guard let ctx = CGContext(
        data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { throw NSError(domain: "make-icon", code: 1) }
    ctx.interpolationQuality = .high
    ctx.scaleBy(x: CGFloat(pixels) / canvas, y: CGFloat(pixels) / canvas)
    drawIcon(in: ctx)

    guard let image = ctx.makeImage(),
          let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { throw NSError(domain: "make-icon", code: 2) }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw NSError(domain: "make-icon", code: 3) }
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write("用法：swift make-icon.swift <輸出的 .iconset 目錄>\n".data(using: .utf8)!)
    exit(64)
}
let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

// iconutil 要求的完整檔名組合：每個點數尺寸各有 1x 與 2x。
for points in [16, 32, 128, 256, 512] {
    try render(pixels: points, to: output.appendingPathComponent("icon_\(points)x\(points).png"))
    try render(pixels: points * 2, to: output.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}
print("已輸出 \(output.path)")
