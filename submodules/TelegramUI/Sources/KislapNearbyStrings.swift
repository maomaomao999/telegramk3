import Foundation

/// Kislap owns these strings because Telegram's server language packs do not
/// contain keys for product-specific screens. The selected Telegram language
/// remains the source of truth, so Kislap switches together with the rest of
/// the app instead of following a separate system-language setting.
struct KislapNearbyStrings {
    let isChinese: Bool

    init(languageCode: String) {
        self.isChinese = languageCode.lowercased().hasPrefix("zh")
    }

    private func value(_ english: String, _ chinese: String) -> String {
        return self.isChinese ? chinese : english
    }

    var nearbyTitle: String { self.value("Learn", "学习") }
    var connections: String { self.value("Connect", "连接") }
    var learningEyebrow: String { self.value("KISLAP LEARNING", "KISLAP 学习") }
    var headline: String { self.value("Find a study partner nearby", "寻找附近的学习搭子") }
    var detail: String { self.value("Practice English, learn programming, music, singing and more with people who share your goals.", "和目标相同的人一起练英语、学编程、音乐、唱歌，以及更多技能。") }

    var journeyTitle: String { self.value("Learn · Teach · Connect", "学习 · 教学 · 连接") }
    var learnActionTitle: String { self.value("Learn", "学习") }
    var learnActionDetail: String { self.value("Choose a skill and find a nearby practice partner.", "选择技能，寻找附近的练习搭子。") }
    var teachActionTitle: String { self.value("Teach", "教学") }
    var teachActionDetail: String { self.value("Show what you can teach and help someone improve.", "展示你能教的技能，帮助他人进步。") }
    var connectActionTitle: String { self.value("Connect", "连接") }
    var connectActionDetail: String { self.value("Manage requests, study partners and learning conversations.", "管理学习邀请、搭子和学习对话。") }
    var detailsPlaceholderTitle: String { self.value("Learning starts with a person", "学习，从找到合适的人开始") }
    var detailsPlaceholderDetail: String { self.value("Choose Learn to find a partner, Teach to share a skill, or Connect to plan your next session.", "通过“学习”寻找搭子，通过“教学”分享技能，或在“连接”中安排下一次学习。") }

    var topicEnglish: String { self.value("English", "英语") }
    var topicProgramming: String { self.value("Programming", "编程") }
    var topicSinging: String { self.value("Singing", "唱歌") }

    var locationOff: String { self.value("Location is off", "位置共享已关闭") }
    var locationPrivacyDetail: String { self.value("Turn it on only when you want to be discoverable. Kislap will show distance ranges, never your exact position.", "只在你想被发现时开启。Kislap 只显示距离范围，绝不会显示你的精确位置。") }
    var learningProfileConnected: String { self.value("Learning profile connected", "学习资料已连接") }
    var connectLearningProfile: String { self.value("Connect learning profile", "连接学习资料") }
    var enableNearbyLearning: String { self.value("Enable Nearby Learning", "开启附近学习") }
    var notVisible: String { self.value("You are not visible to anyone.", "当前没有人能看到你。") }
    var partnersTitle: String { self.value("Nearby learning partners", "附近的学习搭子") }
    var visibilityPrompt: String { self.value("Turn on one-hour visibility to see real people nearby. No demo profiles are shown.", "开启一小时可见状态后，才能看到附近的真实用户。这里不会显示虚构资料。") }

    var safetyTitle: String { self.value("Safety by design", "安全融入设计") }
    var safetyDetail: String { self.value("Built around learning, privacy and mutual choice.", "以学习、隐私和双方意愿为核心。") }
    var adultMutualTitle: String { self.value("Adults and mutual connection", "仅限成年人，双方确认连接") }
    var adultMutualDetail: String { self.value("Chat or call only after a learning request is accepted.", "学习请求被接受后才能聊天或通话。") }
    var oneHourTitle: String { self.value("One-hour visibility", "一小时可见") }
    var oneHourDetail: String { self.value("Your approximate area expires automatically.", "你的大致区域将在到期后自动隐藏。") }
    var blockReportTitle: String { self.value("Block and report anytime", "随时屏蔽或举报") }
    var blockReportDetail: String { self.value("Safety controls are always one tap away.", "安全操作始终触手可及。") }
    var datingSeparateTitle: String { self.value("Dating stays separate", "约会功能保持独立") }
    var datingSeparateDetail: String { self.value("Optional, off by default and mutual opt-in only.", "可选、默认关闭，且仅在双方主动开启后生效。") }

    var learningProfile: String { self.value("Learning profile", "学习资料") }
    var disconnectProfileMessage: String { self.value("Disconnect the separate Kislap learning profile from this device? Your Telegram session will not be affected.", "要从这台设备断开 Kislap 学习资料吗？你的 Telegram 登录不会受到影响。") }
    var disconnect: String { self.value("Disconnect", "断开连接") }
    var disconnecting: String { self.value("Disconnecting learning profile…", "正在断开学习资料…") }
    var profileDisconnected: String { self.value("Learning profile disconnected", "学习资料已断开") }
    var telegramSessionUnaffected: String { self.value("Your Telegram account remains signed in. Nearby Learning needs its own verified profile.", "你的 Telegram 账号仍保持登录。附近学习需要单独验证学习资料。") }
    var connectWhenReady: String { self.value("Connect a learning profile when you are ready.", "准备好后即可连接学习资料。") }
    var disconnectedOnDevice: String { self.value("Disconnected on this device", "已在此设备断开") }

    var connectProfileExplanation: String { self.value("We verify a separate Kislap profile by email. Telegram credentials are never sent to the Kislap server.", "Kislap 会通过邮箱验证独立的学习资料。你的 Telegram 登录凭据绝不会发送到 Kislap 服务器。") }
    var emailAddress: String { self.value("Email address", "邮箱地址") }
    var sendCode: String { self.value("Send code", "发送验证码") }
    var sendingCode: String { self.value("Sending a verification code…", "正在发送验证码…") }
    var couldNotSendCode: String { self.value("Couldn't send code", "验证码发送失败") }
    func developmentCode(_ code: String) -> String { self.value("Enter the six-digit code. Local development code: \(code)", "请输入六位验证码。本地开发验证码：\(code)") }
    func codeSent(to email: String) -> String { self.value("Enter the six-digit code sent to \(email).", "请输入发送到 \(email) 的六位验证码。") }
    var verifyEmail: String { self.value("Verify email", "验证邮箱") }
    var sixDigitCode: String { self.value("6-digit code", "六位验证码") }
    var verify: String { self.value("Verify", "验证") }
    var verifyingProfile: String { self.value("Verifying your learning profile…", "正在验证学习资料…") }
    var readyForNearby: String { self.value("Ready for Nearby Learning", "可以使用附近学习了") }
    var verifiedLocationOff: String { self.value("Verified. Location sharing remains off until you turn it on.", "验证成功。位置共享仍保持关闭，直到你主动开启。") }
    var verificationFailed: String { self.value("Verification failed", "验证失败") }

    var createProfile: String { self.value("Create learning profile", "创建学习资料") }
    var createProfileMessage: String { self.value("Nearby Learning is for adults only. Enter the name and age people will see.", "附近学习仅面向成年人。请输入其他人可以看到的姓名和年龄。") }
    var displayName: String { self.value("Display name", "显示名称") }
    var ageRange: String { self.value("Age (18–99)", "年龄（18–99 岁）") }
    var continueAction: String { self.value("Continue", "继续") }
    var invalidProfile: String { self.value("A display name and an age from 18 to 99 are required.", "请填写显示名称，并输入 18 至 99 岁之间的年龄。") }
    var profileGender: String { self.value("Profile gender", "资料中的性别") }
    var genderMessage: String { self.value("Choose what your learning profile displays.", "请选择学习资料中显示的性别。") }
    var woman: String { self.value("Woman", "女性") }
    var man: String { self.value("Man", "男性") }
    var other: String { self.value("Other", "其他") }
    var safetyAgreement: String { self.value("Safety agreement", "安全协议") }
    var safetyAgreementMessage: String { self.value("By continuing, you confirm that you are 18 or older and agree to follow Kislap's Terms, Privacy Policy and Community Guidelines. Never share an exact address with people you have not verified.", "继续即表示你确认已满 18 岁，并同意遵守 Kislap 的服务条款、隐私政策和社区规范。请勿向尚未核实身份的人透露精确地址。") }
    var agreeCreateProfile: String { self.value("I Agree & Create Profile", "同意并创建资料") }

    var connectBeforeSharing: String { self.value("Connect a verified learning profile before sharing your area.", "共享大致区域前，请先连接已验证的学习资料。") }
    var locationServicesDisabled: String { self.value("Location Services are disabled in iOS Settings.", "iOS 设置中的定位服务已关闭。") }
    var waitingPermission: String { self.value("Waiting for your permission…", "正在等待你的授权…") }
    var locationAccessOffStatus: String { self.value("Location access is off. Enable it in iOS Settings when you are ready.", "位置访问已关闭。准备好后可前往 iOS 设置开启。") }
    var locationUnavailable: String { self.value("Location is unavailable right now.", "暂时无法获取位置。") }
    var findingArea: String { self.value("Finding your area…", "正在确定你的大致区域…") }
    var coarseLocationRequest: String { self.value("Kislap is requesting a coarse location. You are not visible yet.", "Kislap 正在获取大致位置，此时其他人还看不到你。") }
    var turningVisibilityOff: String { self.value("Turning off Nearby visibility…", "正在关闭附近可见状态…") }
    var useApproximateArea: String { self.value("Use My Approximate Area", "使用我的大致区域") }
    var visibilityTurnOnAgain: String { self.value("Turn visibility on again when you want to meet a learning partner.", "想认识学习搭子时，可以再次开启可见状态。") }
    var couldNotDisableVisibility: String { self.value("Couldn't turn visibility off", "无法关闭可见状态") }
    var permissionGranted: String { self.value("Permission granted. Tap above when you want to look for study partners.", "位置权限已开启。想寻找学习搭子时，请点击上方按钮。") }
    var locationAccessOffButton: String { self.value("Location Access Off", "位置权限已关闭") }
    var invisibleCanEnableLater: String { self.value("You are not visible. Location can be enabled later in iOS Settings.", "当前没有人能看到你。稍后可在 iOS 设置中开启位置权限。") }
    var protectingArea: String { self.value("Protecting your area…", "正在保护你的区域…") }
    var privacyFilter: String { self.value("Sending your location through Kislap's server-side privacy filter.", "正在通过 Kislap 服务端隐私过滤器处理你的位置。") }
    var visibleOneHour: String { self.value("Visible for one hour", "一小时内可见") }
    func visibilityExpires(_ expiry: String) -> String { self.value("Only a distance range is shown. Visibility expires \(expiry).", "只会显示距离范围，可见状态将\(expiry)。") }
    var stopBeingVisible: String { self.value("Stop Being Visible", "停止对附近的人可见") }
    var remainInvisible: String { self.value("You remain invisible", "你仍处于不可见状态") }
    var couldNotEnableNearby: String { self.value("Couldn't enable Nearby", "无法开启附近学习") }
    var couldNotFindArea: String { self.value("Couldn't find your area", "无法确定你的区域") }
    var tryAgainRemainInvisible: String { self.value("Please try again when location is available. You remain invisible.", "请在位置可用时重试。你仍处于不可见状态。") }
    var nearbyVisibilityOn: String { self.value("Nearby visibility is on", "附近可见状态已开启") }
    var connectProfileToUseNearby: String { self.value("Connect a learning profile to use Nearby Learning.", "连接学习资料后才能使用附近学习。") }

    var findingPartners: String { self.value("Finding real learning partners…", "正在寻找真实的学习搭子…") }
    func couldNotLoadPartners(_ detail: String) -> String { self.value("Couldn't load partners: \(detail)", "无法加载学习搭子：\(detail)") }
    var noMatchingPartners: String { self.value("No matching learning partners are visible within 10 km right now.", "目前 10 公里范围内没有符合条件且处于可见状态的学习搭子。") }
    var activeNow: String { self.value("Active now", "当前在线") }
    var activeRecently: String { self.value("Active recently", "最近在线") }
    var verifiedAdult: String { self.value("Verified adult profile", "已验证的成年资料") }
    var reviewDemoProfile: String { self.value("App Review demo profile", "App 审核演示资料") }
    var viewProfile: String { self.value("View learning profile", "查看学习资料") }
    var profileAbout: String { self.value("ABOUT", "关于") }
    var wantsToLearn: String { self.value("WANTS TO LEARN", "想学习") }
    var canTeach: String { self.value("CAN TEACH", "可以教") }
    var learningInterests: String { self.value("LEARNING INTERESTS", "学习兴趣") }
    var noProfileDetails: String { self.value("This learner has not added more details yet.", "这位学习者还没有补充更多资料。") }
    var approximateAreaOnly: String { self.value("Approximate area only", "仅显示大致区域") }
    var profileSafetyNote: String { self.value("Connect first. Keep early conversations in Kislap and use Safety whenever something feels wrong.", "请先建立连接。初次交流建议留在 Kislap 内；遇到异常情况可随时使用安全操作。") }
    var close: String { self.value("Close", "关闭") }
    var requestStudySession: String { self.value("Request study session", "邀请一起学习") }
    var safety: String { self.value("Safety", "安全") }
    var requestSent: String { self.value("Request sent", "邀请已发送") }
    var couldNotSendRequest: String { self.value("Couldn't send request", "邀请发送失败") }
    var safetyActionsMessage: String { self.value("Safety actions take effect in Kislap Learning and do not change your Telegram block list.", "这些安全操作只会在 Kislap 学习功能中生效，不会更改你的 Telegram 屏蔽列表。") }
    var report: String { self.value("Report", "举报") }
    var block: String { self.value("Block", "屏蔽") }

    var distanceNearby: String { self.value("Nearby", "就在附近") }
    var distanceFar: String { self.value("More than 15 km away", "距离超过 15 公里") }
    func distanceAbout(_ label: String) -> String { self.value("About \(label) away", "距离约 \(label)") }
    var expiresAutomatically: String { self.value("automatically", "自动结束") }
    var expiresInOneHour: String { self.value("in one hour", "在一小时后结束") }
    func expiresAt(_ time: String) -> String { self.value("at \(time)", "于 \(time) 结束") }

    var serviceUnavailable: String { self.value("The Kislap learning service is not configured.", "Kislap 学习服务尚未配置。") }
    var invalidServiceResponse: String { self.value("The learning service returned an invalid response.", "学习服务返回了无效响应。") }
    var unknownServiceError: String { self.value("The learning service encountered an error.", "学习服务发生错误。") }
}
