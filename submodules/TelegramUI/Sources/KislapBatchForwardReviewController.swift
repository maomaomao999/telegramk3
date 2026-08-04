import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData
import AccountContext

private struct KislapBatchForwardReviewStrings {
    private let chinese: Bool

    init(languageCode: String) {
        self.chinese = languageCode.lowercased().hasPrefix("zh")
    }

    private func value(_ english: String, _ chinese: String) -> String {
        return self.chinese ? chinese : english
    }

    var title: String { self.value("Review Batch", "复核批量转发") }
    var eyebrow: String { self.value("KISLAP BATCH FORWARD", "KISLAP 批量转发") }
    var headline: String { self.value("Check once before it goes everywhere", "发送到多个目标前统一检查") }
    var detail: String { self.value("Review the message and destination counts. Telegram network restrictions and destination permissions are still applied when sending.", "请复核消息数和目标数；发送时仍会执行 Telegram 网络限制及目标权限。") }
    var messages: String { self.value("Messages", "消息") }
    var destinations: String { self.value("Destinations", "目标") }
    var options: String { self.value("Forwarding options", "转发选项") }
    var namesVisible: String { self.value("Sender names included", "包含发送者名称") }
    var namesHidden: String { self.value("Sender names hidden", "隐藏发送者名称") }
    var captionsVisible: String { self.value("Captions included", "包含说明文字") }
    var captionsHidden: String { self.value("Captions hidden", "隐藏说明文字") }
    var commentIncluded: String { self.value("A comment will be sent first", "将先发送附加留言") }
    var restrictionTitle: String { self.value("Restrictions stay active", "继续执行转发限制") }
    var restrictionDetail: String { self.value("Protected content, channel rules, paid-message requirements and rate limits are checked by the existing forwarding engine.", "现有转发引擎会继续检查受保护内容、频道规则、付费消息要求和频率限制。") }
    var send: String { self.value("Send Batch", "发送这一批") }
    var cancel: String { self.value("Cancel", "取消") }
    func moreDestinations(_ count: Int) -> String { self.value("+\(count) more", "另有 \(count) 个") }
}

final class KislapBatchForwardReviewController: ViewController {
    private let presentationData: PresentationData
    private let messageCount: Int
    private let destinationNames: [String]
    private let includesComment: Bool
    private let hideNames: Bool
    private let hideCaptions: Bool
    private let confirm: () -> Void

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private var strings: KislapBatchForwardReviewStrings {
        return KislapBatchForwardReviewStrings(languageCode: self.presentationData.strings.baseLanguageCode)
    }

    init(
        context: AccountContext,
        messageCount: Int,
        destinationNames: [String],
        includesComment: Bool,
        hideNames: Bool,
        hideCaptions: Bool,
        confirm: @escaping () -> Void
    ) {
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.messageCount = messageCount
        self.destinationNames = destinationNames
        self.includesComment = includesComment
        self.hideNames = hideNames
        self.hideCaptions = hideCaptions
        self.confirm = confirm

        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData, style: .glass))

        self._hasGlassStyle = true
        self.title = self.strings.title
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.strings.cancel, style: .plain, target: self, action: #selector(self.cancelPressed))
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadDisplayNode() {
        let node = ASDisplayNode()
        self.displayNode = node
        self.displayNodeDidLoad()

        let theme = self.presentationData.theme
        node.backgroundColor = theme.list.blocksBackgroundColor

        self.scrollView.alwaysBounceVertical = true
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.contentStack.axis = .vertical
        self.contentStack.spacing = 14.0
        self.contentStack.translatesAutoresizingMaskIntoConstraints = false

        let eyebrow = self.label(self.strings.eyebrow, size: 13.0, weight: .semibold, color: theme.list.itemAccentColor)
        let headline = self.label(self.strings.headline, size: 28.0, weight: .bold, color: theme.list.itemPrimaryTextColor)
        let detail = self.label(self.strings.detail, size: 15.0, weight: .regular, color: theme.list.itemSecondaryTextColor)
        self.contentStack.addArrangedSubview(eyebrow)
        self.contentStack.addArrangedSubview(headline)
        self.contentStack.addArrangedSubview(detail)
        self.contentStack.setCustomSpacing(22.0, after: detail)

        let counts = UIStackView(arrangedSubviews: [
            self.metricCard(value: "\(self.messageCount)", title: self.strings.messages),
            self.metricCard(value: "\(self.destinationNames.count)", title: self.strings.destinations),
        ])
        counts.axis = .horizontal
        counts.distribution = .fillEqually
        counts.spacing = 12.0
        self.contentStack.addArrangedSubview(counts)

        let destinationText: String
        let visibleNames = self.destinationNames.prefix(4)
        if self.destinationNames.count > visibleNames.count {
            destinationText = visibleNames.joined(separator: " • ") + "\n" + self.strings.moreDestinations(self.destinationNames.count - visibleNames.count)
        } else {
            destinationText = visibleNames.joined(separator: " • ")
        }
        self.contentStack.addArrangedSubview(self.infoCard(
            title: self.strings.destinations,
            detail: destinationText,
            icon: "person.2.fill",
            tint: KislapBrandPalette.brandPurple
        ))

        var optionLines = [self.hideNames ? self.strings.namesHidden : self.strings.namesVisible]
        optionLines.append(self.hideCaptions ? self.strings.captionsHidden : self.strings.captionsVisible)
        if self.includesComment {
            optionLines.append(self.strings.commentIncluded)
        }
        self.contentStack.addArrangedSubview(self.infoCard(
            title: self.strings.options,
            detail: optionLines.joined(separator: "\n"),
            icon: "checklist",
            tint: theme.list.itemAccentColor
        ))
        self.contentStack.addArrangedSubview(self.infoCard(
            title: self.strings.restrictionTitle,
            detail: self.strings.restrictionDetail,
            icon: "shield.checkered",
            tint: KislapBrandPalette.success
        ))

        let sendButton = UIButton(type: .system)
        sendButton.setTitle(self.strings.send, for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .bold)
        sendButton.backgroundColor = KislapBrandPalette.brandPurple
        sendButton.layer.cornerRadius = 14.0
        sendButton.heightAnchor.constraint(equalToConstant: 54.0).isActive = true
        sendButton.addTarget(self, action: #selector(self.sendPressed), for: .touchUpInside)
        self.contentStack.setCustomSpacing(22.0, after: self.contentStack.arrangedSubviews.last!)
        self.contentStack.addArrangedSubview(sendButton)

        node.view.addSubview(self.scrollView)
        self.scrollView.addSubview(self.contentStack)
        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: node.view.safeAreaLayoutGuide.topAnchor, constant: 44.0),
            self.scrollView.leadingAnchor.constraint(equalTo: node.view.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: node.view.trailingAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: node.view.safeAreaLayoutGuide.bottomAnchor),
            self.contentStack.topAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.topAnchor, constant: 18.0),
            self.contentStack.leadingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.leadingAnchor, constant: 20.0),
            self.contentStack.trailingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.trailingAnchor, constant: -20.0),
            self.contentStack.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor, constant: -32.0),
        ])
    }

    private func label(_ text: String, size: CGFloat, weight: UIFont.Weight, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.numberOfLines = 0
        return label
    }

    private func metricCard(value: String, title: String) -> UIView {
        let theme = self.presentationData.theme
        let valueLabel = self.label(value, size: 30.0, weight: .bold, color: theme.list.itemPrimaryTextColor)
        let titleLabel = self.label(title, size: 13.0, weight: .semibold, color: theme.list.itemSecondaryTextColor)
        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 3.0
        return self.card(containing: stack)
    }

    private func infoCard(title: String, detail: String, icon: String, tint: UIColor) -> UIView {
        let theme = self.presentationData.theme
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = tint
        iconView.contentMode = .scaleAspectFit
        iconView.widthAnchor.constraint(equalToConstant: 30.0).isActive = true
        let textStack = UIStackView(arrangedSubviews: [
            self.label(title, size: 17.0, weight: .bold, color: theme.list.itemPrimaryTextColor),
            self.label(detail, size: 14.0, weight: .regular, color: theme.list.itemSecondaryTextColor),
        ])
        textStack.axis = .vertical
        textStack.spacing = 5.0
        let row = UIStackView(arrangedSubviews: [iconView, textStack])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 14.0
        return self.card(containing: row)
    }

    private func card(containing content: UIView) -> UIView {
        let theme = self.presentationData.theme
        let card = UIView()
        card.backgroundColor = theme.list.itemBlocksBackgroundColor
        card.layer.cornerRadius = 16.0
        card.layer.borderWidth = UIScreenPixel
        card.layer.borderColor = theme.list.itemBlocksSeparatorColor.cgColor
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 16.0),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16.0),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16.0),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16.0),
        ])
        return card
    }

    @objc private func cancelPressed() {
        self.dismiss(animated: true)
    }

    @objc private func sendPressed() {
        self.confirm()
    }
}
