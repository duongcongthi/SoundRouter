import AppKit

/// 選單列圖示：方形音箱、單一喇叭單體。
///
/// SF Symbols 只有雙單體的 `hifispeaker`，沒有方形單喇叭，所以自己畫。
/// 做成 template 影像，選單列深淺色由系統自動上色；18pt 比一般 SF Symbol 略大一點。
@MainActor
enum MenuBarIcon {
    static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            // even-odd 一次畫完：箱體實心、喇叭環形挖空、中心防塵蓋再填回實心。
            let path = NSBezierPath(
                roundedRect: NSRect(x: 1, y: 1, width: 16, height: 16), xRadius: 3.5, yRadius: 3.5
            )
            path.append(NSBezierPath(ovalIn: NSRect(x: 3.75, y: 3.75, width: 10.5, height: 10.5)))
            path.append(NSBezierPath(ovalIn: NSRect(x: 7.25, y: 7.25, width: 3.5, height: 3.5)))
            path.windingRule = .evenOdd
            NSColor.black.setFill()
            path.fill()
            return true
        }
        image.isTemplate = true
        // 輔助使用與系統清單讀到的名稱，要跟 App 名稱一致。
        image.accessibilityDescription = "SoundRouter"
        return image
    }()
}
