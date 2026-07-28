import Foundation

struct KislapConversationStrings {
    let isChinese: Bool

    init(languageCode: String) {
        self.isChinese = languageCode.lowercased().hasPrefix("zh")
    }

    private func value(_ english: String, _ chinese: String) -> String {
        return self.isChinese ? chinese : english
    }

    var safety: String { self.value("Safety", "安全") }
    var notice: String { self.value("Kislap learning chat · Available only after both people accept the connection. This is separate from Telegram chats.", "Kislap 学习聊天 · 仅在双方接受连接后可用，与 Telegram 聊天相互独立。") }
    var empty: String { self.value("Start with a learning goal, a suitable time, or a friendly introduction.", "可以从学习目标、合适的时间，或友好的自我介绍开始。") }
    var placeholder: String { self.value("Learning message", "输入学习消息") }
    var send: String { self.value("Send", "发送") }
    var loadFailed: String { self.value("Couldn't load learning messages", "无法加载学习消息") }
    var sendFailed: String { self.value("Couldn't send message", "无法发送消息") }
    var connectionUnavailable: String { self.value("This learning connection is no longer available. It may have been removed or blocked.", "此学习连接已不可用，可能已被解除或屏蔽。") }
    var report: String { self.value("Report", "举报") }
    var block: String { self.value("Block", "屏蔽") }
    var blockTitle: String { self.value("Block this person?", "要屏蔽此用户吗？") }
    var blockMessage: String { self.value("They will immediately disappear from Nearby and Connect. Neither person will be able to read or send new Kislap learning messages through this connection.", "对方会立即从“附近”和“连接”中消失，双方都无法再通过此连接读取或发送新的 Kislap 学习消息。") }
    var blockConfirm: String { self.value("Block and Close Chat", "屏蔽并关闭聊天") }
    var reportReason: String { self.value("Why are you reporting this person?", "请选择举报原因") }
    var harassment: String { self.value("Harassment", "骚扰") }
    var spam: String { self.value("Spam", "垃圾信息") }
    var inappropriate: String { self.value("Inappropriate content", "不当内容") }
    var scam: String { self.value("Scam", "诈骗") }
    var fakeProfile: String { self.value("Fake profile", "虚假资料") }
    var underage: String { self.value("Underage user", "未成年用户") }
    var other: String { self.value("Other", "其他") }
    var reportSent: String { self.value("Report submitted", "举报已提交") }
    var reportSentDetail: String { self.value("Thank you. The report is stored for moderation review. You can also block this person immediately.", "感谢你的反馈。举报已保存并等待审核，你也可以立即屏蔽此用户。") }
    var reportFailed: String { self.value("Couldn't submit report", "无法提交举报") }
    var blockFailed: String { self.value("Couldn't block this person", "无法屏蔽此用户") }
    var cancel: String { self.value("Cancel", "取消") }
    var retry: String { self.value("Retry", "重试") }
    var ok: String { self.value("OK", "好") }
}
