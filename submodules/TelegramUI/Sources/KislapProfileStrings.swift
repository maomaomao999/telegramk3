import Foundation

struct KislapProfileStrings {
    let isChinese: Bool

    init(languageCode: String) {
        self.isChinese = languageCode.lowercased().hasPrefix("zh")
    }

    private func value(_ english: String, _ chinese: String) -> String {
        return self.isChinese ? chinese : english
    }

    var title: String { self.value("Learning Profile", "学习资料") }
    var subtitle: String { self.value("What nearby study partners can see", "附近学习搭子可以看到的内容") }
    var verifiedAdult: String { self.value("Verified adult learning profile", "已验证的成年学习资料") }
    var basicInformation: String { self.value("BASIC INFORMATION", "基本资料") }
    var displayName: String { self.value("Display name", "显示名称") }
    var learningGoal: String { self.value("Learning goal", "学习目标") }
    var bio: String { self.value("About me", "个人简介") }
    var languages: String { self.value("Languages, separated by commas", "语言，用逗号分隔") }
    var availability: String { self.value("Availability", "方便学习的时间") }
    var skillsTitle: String { self.value("LEARNING & TEACHING", "学习与教学") }
    var skillsDetail: String { self.value("Choose whether you want to learn or can teach each topic.", "选择你希望学习或可以教授的主题。") }
    var learn: String { self.value("Learn", "想学") }
    var teach: String { self.value("Teach", "可教") }
    var english: String { self.value("English conversation", "英语口语") }
    var programming: String { self.value("Programming", "编程技术") }
    var singing: String { self.value("Singing", "唱歌") }
    var privacyTitle: String { self.value("PRIVACY", "隐私") }
    var privacyDetail: String { self.value("Exact location is never shown. Dating remains separate and off until you explicitly enable it.", "绝不会显示精确位置。Dating 保持独立，只有你明确开启后才会生效。") }
    var datingSettings: String { self.value("Dating settings · Off by default", "Dating 设置 · 默认关闭") }
    var save: String { self.value("Save Profile", "保存资料") }
    var saving: String { self.value("Saving…", "正在保存…") }
    var saved: String { self.value("Profile saved", "资料已保存") }
    var loadFailed: String { self.value("Couldn't load profile", "无法加载资料") }
    var saveFailed: String { self.value("Couldn't save profile", "无法保存资料") }
    var nameRequired: String { self.value("Display name is required.", "请填写显示名称。") }
    var accountTitle: String { self.value("ACCOUNT", "账号") }
    var disconnect: String { self.value("Disconnect from this device", "从这台设备断开") }
    var disconnectMessage: String { self.value("Your Telegram account will remain signed in.", "你的 Telegram 账号仍会保持登录。") }
    var deleteAccount: String { self.value("Delete Kislap learning account", "删除 Kislap 学习账号") }
    var deleteMessage: String { self.value("This permanently deletes your Kislap learning profile, connections and learning messages. Your Telegram account is not affected.", "这会永久删除你的 Kislap 学习资料、连接和学习消息，但不会影响 Telegram 账号。") }
    var deleteConfirm: String { self.value("Delete Permanently", "永久删除") }
    var deleting: String { self.value("Deleting…", "正在删除…") }
    var deleteFailed: String { self.value("Couldn't delete account", "无法删除账号") }
    var cancel: String { self.value("Cancel", "取消") }
    var ok: String { self.value("OK", "好") }
    var retry: String { self.value("Retry", "重试") }
}
