import Foundation

struct KislapPrivacyCenterStrings {
    private let useChinese: Bool

    init(languageCode: String) {
        self.useChinese = languageCode.lowercased().hasPrefix("zh")
    }

    private func value(_ english: String, _ chinese: String) -> String {
        return self.useChinese ? chinese : english
    }

    var title: String { self.value("Privacy Center", "隐私中心") }
    var eyebrow: String { self.value("KISLAP PRIVACY CONTROLS", "KISLAP 隐私控制") }
    var headline: String { self.value("Choose when your activity is shared", "由你决定何时共享活动状态") }
    var detail: String { self.value("These controls change client behavior immediately and never claim to reverse a state already recorded by the communication network.", "这些控制会立即改变客户端行为，也不会声称撤销通信网络已经记录的状态。") }
    var peekTitle: String { self.value("Peek Mode", "隐私预览") }
    var peekDetail: String { self.value("Opening a conversation does not automatically advance its interactive read state. Use Mark as Read when you are ready.", "打开会话时不自动推进交互式已读状态；准备好后再使用“标记为已读”。") }
    var stealthTitle: String { self.value("Stealth Mode", "潜水模式") }
    var stealthDetail: String { self.value("Suppress typing, sticker-selection, voice-recording and instant-video activity broadcasts while keeping local editing available.", "保留本地输入和录制，同时抑制输入、选贴纸、语音录制和即时视频活动广播。") }
    var durationTitle: String { self.value("Stealth duration", "潜水时长") }
    var oneHour: String { self.value("1 hour", "1 小时") }
    var eightHours: String { self.value("8 hours", "8 小时") }
    var always: String { self.value("Until off", "持续开启") }
    var activeTitle: String { self.value("Protection is active", "隐私保护已开启") }
    var inactiveTitle: String { self.value("Standard communication behavior", "标准通信行为") }
    var bothActive: String { self.value("Peek and Stealth are active.", "隐私预览和潜水模式均已开启。") }
    var peekActive: String { self.value("Peek Mode is active.", "隐私预览已开启。") }
    var stealthActive: String { self.value("Stealth Mode is active.", "潜水模式已开启。") }
    func stealthActive(until value: String) -> String { self.value("Stealth Mode is active until \(value).", "潜水模式开启至 \(value)。") }
    var noneActive: String { self.value("Automatic read advancement and activity broadcasts use their standard behavior.", "自动推进已读状态和活动广播采用标准行为。") }
    var networkNoteTitle: String { self.value("Network boundary", "网络边界") }
    var networkNote: String { self.value("Kislap controls what this client sends. Server-side presence, previously delivered read states and other devices remain governed by the communication network.", "Kislap 控制本客户端发送的状态；服务器在线状态、此前已发送的已读状态以及其他设备仍由通信网络管理。") }
}
