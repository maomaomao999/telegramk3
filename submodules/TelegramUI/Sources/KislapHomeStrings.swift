import Foundation

struct KislapHomeStrings {
    private let useChinese: Bool

    init(languageCode: String) {
        self.useChinese = languageCode.lowercased().hasPrefix("zh")
    }

    private func value(_ english: String, _ chinese: String) -> String {
        return self.useChinese ? chinese : english
    }

    var title: String { self.value("Home", "首页") }
    var eyebrow: String { self.value("KISLAP 1.2", "KISLAP 1.2") }
    var headline: String { self.value("Connect on your terms", "按你的方式保持连接") }
    var detail: String { self.value("Batch-forward thoughtfully, preview privately, control activity signals and meet nearby learning partners.", "谨慎批量转发、私密预览消息、控制活动状态，并结识附近的学习搭子。") }
    var toolsTitle: String { self.value("Your Kislap tools", "你的 Kislap 工具") }
    var batchTitle: String { self.value("Batch Forward", "批量转发") }
    var batchDetail: String { self.value("Select multiple messages and destinations with a review step before sending.", "选择多条消息和多个目标，发送前统一复核。") }
    var peekTitle: String { self.value("Peek Mode", "隐私预览") }
    var peekDetail: String { self.value("Preview conversations without automatically advancing their read state.", "预览会话时不自动推进已读状态。") }
    var stealthTitle: String { self.value("Stealth Mode", "潜水模式") }
    var stealthDetail: String { self.value("Pause typing and recording activity broadcasts from this client.", "暂停本客户端的输入和录制活动广播。") }
    var nearbyTitle: String { self.value("Nearby Learning", "附近学习") }
    var nearbyDetail: String { self.value("Discover learning partners with approximate distance and time-limited visibility.", "通过模糊距离和限时可见发现学习搭子。") }
    var communicationTitle: String { self.value("Communication", "通信") }
    var messagesTitle: String { self.value("Messages & Groups", "消息与群组") }
    var messagesDetail: String { self.value("Open your communication inbox.", "打开通信收件箱。") }
    var callsTitle: String { self.value("Voice & Video Calls", "语音与视频通话") }
    var callsDetail: String { self.value("Continue conversations with voice or video.", "通过语音或视频继续交流。") }
    var privacyStatusTitle: String { self.value("Privacy status", "隐私状态") }
    var standardStatus: String { self.value("Standard mode", "标准模式") }
    var peekStatus: String { self.value("Peek active", "隐私预览已开启") }
    var stealthStatus: String { self.value("Stealth active", "潜水模式已开启") }
    var bothStatus: String { self.value("Peek + Stealth active", "隐私预览 + 潜水模式已开启") }
    var networkTitle: String { self.value("Communication foundation", "通信基础") }
    var networkDetail: String { self.value("Messages, groups and calls use the Telegram network. Kislap independently provides this Home, privacy controls, learning profiles, Nearby, Connect and safety workflows.", "消息、群组和通话使用 Telegram 网络；Kislap 独立提供本首页、隐私控制、学习资料、附近、连接和安全流程。") }
    var batchSheetTitle: String { self.value("Start a batch forward", "开始批量转发") }
    var batchSheetDetail: String { self.value("Open a conversation, select the messages, choose Forward, then select multiple destinations and review the available forwarding options before sending.", "打开会话并选择消息，点击“转发”，再选择多个目标并在发送前复核可用的转发选项。") }
    var openMessages: String { self.value("Open Messages", "打开消息") }
}
