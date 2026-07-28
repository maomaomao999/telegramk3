import Foundation

struct KislapConnectionsStrings {
    let isChinese: Bool

    init(languageCode: String) {
        self.isChinese = languageCode.lowercased().hasPrefix("zh")
    }

    private func value(_ english: String, _ chinese: String) -> String {
        return self.isChinese ? chinese : english
    }

    var title: String { self.value("Connect", "连接") }
    var subtitle: String { self.value("Study together after both people agree", "双方同意后再一起学习") }
    var requestsTitle: String { self.value("REQUESTS", "收到的邀请") }
    var connectionsTitle: String { self.value("LEARNING CONNECTIONS", "学习连接") }
    var requestsEmpty: String { self.value("No pending requests", "暂无待处理邀请") }
    var connectionsEmpty: String { self.value("No learning connections yet. Find a study partner in Nearby.", "还没有学习连接。可以去“附近”寻找学习搭子。") }
    var accept: String { self.value("Accept", "接受") }
    var decline: String { self.value("Decline", "拒绝") }
    var remove: String { self.value("Remove", "解除连接") }
    var chat: String { self.value("Learning chat", "学习聊天") }
    var removeMessage: String { self.value("Remove this learning connection?", "要解除这个学习连接吗？") }
    var cancel: String { self.value("Cancel", "取消") }
    var studyPartner: String { self.value("Study partner", "学习搭子") }
    var skillExchange: String { self.value("Skill exchange", "技能交换") }
    var dating: String { self.value("Dating · mutual opt-in", "Dating · 双方主动开启") }
    var safety: String { self.value("Block and report remain available from Nearby. Dating requests only work when both people explicitly opt in.", "你可以随时在“附近”屏蔽或举报。只有双方都明确开启后，Dating 邀请才会生效。") }
    var loadFailed: String { self.value("Couldn't load connections", "无法加载连接") }
    var actionFailed: String { self.value("Couldn't update request", "无法处理邀请") }
    var retry: String { self.value("Retry", "重试") }
    var ok: String { self.value("OK", "好") }
}
