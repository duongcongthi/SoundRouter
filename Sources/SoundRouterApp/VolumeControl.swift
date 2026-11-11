import SwiftUI

/// 音量滑軌：系統預設樣式的連續滑軌，不分格、不畫刻度，拖到哪就是哪。
struct VolumeControl: View {
    let value: Float
    /// 傳 nil 表示這個控制項沒有靜音功能。
    var isMuted: Bool?
    let onChange: (Float) -> Void
    var onToggleMute: (() -> Void)?

    private var percent: Int { Int((value * 100).rounded()) }

    var body: some View {
        HStack(spacing: 8) {
            if let isMuted, let onToggleMute {
                Button(action: onToggleMute) {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.fill")
                        .frame(width: 14)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(isMuted ? Color.red : Color.secondary)
            }

            Slider(
                value: Binding(get: { value }, set: { onChange($0) }),
                in: 0...1
            )

            Text("\(percent)%")
                .font(.callout.monospacedDigit())
                .foregroundStyle(isMuted == true ? .secondary : .primary)
                .frame(width: 44, alignment: .trailing)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        VolumeControl(value: 0.73, isMuted: false, onChange: { _ in }, onToggleMute: {})
        VolumeControl(value: 0.4, isMuted: true, onChange: { _ in }, onToggleMute: {})
        VolumeControl(value: 1, onChange: { _ in })
    }
    .padding()
    .frame(width: 360)
}
