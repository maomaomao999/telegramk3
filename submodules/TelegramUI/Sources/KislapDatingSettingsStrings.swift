import Foundation

struct KislapDatingSettingsStrings {
    let isChinese: Bool

    init(languageCode: String) {
        self.isChinese = languageCode.lowercased().hasPrefix("zh")
    }

    private func value(_ english: String, _ chinese: String) -> String {
        return self.isChinese ? chinese : english
    }

    var title: String { self.value("Dating", "Dating") }
    var headline: String { self.value("Optional and separate", "可选，并与学习功能分开") }
    var detail: String { self.value("Kislap is learning-first. Dating is a secondary mode and remains off unless you explicitly enable it.", "Kislap 以学习为主。Dating 是次要模式，只有你明确选择后才会开启。") }
    var modeTitle: String { self.value("DATING MODE", "DATING 模式") }
    var enable: String { self.value("Enable Dating", "开启 Dating") }
    var off: String { self.value("Off · You will not appear in Dating", "已关闭 · 不会出现在 Dating 中") }
    var on: String { self.value("On · Only mutual opt-in requests are allowed", "已开启 · 仅允许双方主动开启后的邀请") }
    var safetyTitle: String { self.value("BEFORE YOU ENABLE", "开启前请了解") }
    var mutualTitle: String { self.value("Mutual opt-in only", "必须双方主动开启") }
    var mutualDetail: String { self.value("A Dating connection cannot be created unless both adults enable this mode.", "只有双方成年人都开启此模式后，才能建立 Dating 连接。") }
    var learningTitle: String { self.value("Learning stays primary", "学习始终是主线") }
    var learningDetail: String { self.value("Nearby learning partners and skill matching do not depend on Dating.", "附近学习搭子和技能匹配不会依赖 Dating。") }
    var controlTitle: String { self.value("Turn it off anytime", "可随时关闭") }
    var controlDetail: String { self.value("Turning it off stops new Dating requests without changing your learning profile.", "关闭后会停止新的 Dating 邀请，不会改变你的学习资料。") }
    var confirmTitle: String { self.value("Enable Dating?", "要开启 Dating 吗？") }
    var confirmMessage: String { self.value("You confirm that this is your own choice. Your precise location is never shown, and connections still require mutual consent.", "请确认这是你的自主选择。你的精确位置绝不会显示，建立连接仍需双方同意。") }
    var confirm: String { self.value("I Understand, Enable", "我已了解，开启") }
    var cancel: String { self.value("Cancel", "取消") }
    var updated: String { self.value("Dating setting updated", "Dating 设置已更新") }
    var loadFailed: String { self.value("Couldn't load Dating setting", "无法加载 Dating 设置") }
    var updateFailed: String { self.value("Couldn't update Dating setting", "无法更新 Dating 设置") }
    var retry: String { self.value("Retry", "重试") }
    var ok: String { self.value("OK", "好") }
}
