import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData
import AccountContext
import TelegramCore
import SwiftSignalKit

private struct KislapBatchForwardProgressStrings {
    private let chinese: Bool

    init(languageCode: String) {
        self.chinese = languageCode.lowercased().hasPrefix("zh")
    }

    private func value(_ english: String, _ chinese: String) -> String {
        return self.chinese ? chinese : english
    }

    var title: String { self.value("Batch Progress", "批量转发进度") }
    var eyebrow: String { self.value("KISLAP DELIVERY", "KISLAP 发送进度") }
    var headline: String { self.value("One batch, every destination in view", "一批消息，每个目标都清楚可见") }
    var queued: String { self.value("Queued", "等待发送") }
    var sending: String { self.value("Sending", "正在发送") }
    var sent: String { self.value("Sent", "发送成功") }
    var failed: String { self.value("Failed", "发送失败") }
    var cancelled: String { self.value("Cancelled", "已取消") }
    var cancelPending: String { self.value("Cancel Pending", "取消待发送任务") }
    var cancelling: String { self.value("Cancelling pending items…", "正在取消待发送任务…") }
    var done: String { self.value("Done", "完成") }
    var close: String { self.value("Close", "关闭") }

    func summary(completed: Int, total: Int) -> String {
        return self.value("\(completed) of \(total) destinations finished", "已完成 \(completed) / \(total) 个目标")
    }

    func result(sent: Int, failed: Int, cancelled: Int) -> String {
        return self.value(
            "\(sent) sent · \(failed) failed · \(cancelled) cancelled",
            "成功 \(sent) · 失败 \(failed) · 取消 \(cancelled)"
        )
    }
}

final class KislapBatchForwardProgressController: ViewController {
    private enum DestinationState {
        case queued
        case sending
        case sent
        case failed
        case cancelled

        var terminal: Bool {
            switch self {
            case .sent, .failed, .cancelled:
                return true
            case .queued, .sending:
                return false
            }
        }
    }

    private final class Destination {
        let id: EnginePeer.Id
        let name: String
        var state: DestinationState = .queued
        var pendingIds = Set<EngineMessage.Id>()
        var hadFailure = false

        init(id: EnginePeer.Id, name: String) {
            self.id = id
            self.name = name
        }
    }

    private final class DestinationRow: UIView {
        let iconView = UIImageView()
        let nameLabel = UILabel()
        let statusLabel = UILabel()

        init(name: String, theme: PresentationTheme) {
            super.init(frame: .zero)

            self.backgroundColor = theme.list.itemBlocksBackgroundColor
            self.layer.cornerRadius = 15.0
            self.layer.borderWidth = UIScreenPixel
            self.layer.borderColor = theme.list.itemBlocksSeparatorColor.cgColor

            self.iconView.contentMode = .scaleAspectFit
            self.iconView.translatesAutoresizingMaskIntoConstraints = false
            self.iconView.widthAnchor.constraint(equalToConstant: 26.0).isActive = true

            self.nameLabel.text = name
            self.nameLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
            self.nameLabel.textColor = theme.list.itemPrimaryTextColor
            self.nameLabel.numberOfLines = 1

            self.statusLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
            self.statusLabel.textColor = theme.list.itemSecondaryTextColor

            let textStack = UIStackView(arrangedSubviews: [self.nameLabel, self.statusLabel])
            textStack.axis = .vertical
            textStack.spacing = 3.0

            let row = UIStackView(arrangedSubviews: [self.iconView, textStack])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 13.0
            row.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(row)
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: self.topAnchor, constant: 14.0),
                row.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16.0),
                row.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16.0),
                row.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -14.0),
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private let context: AccountContext
    private let presentationData: PresentationData
    private var destinations: [Destination]
    private var destinationMap: [EnginePeer.Id: Destination] = [:]
    private var rowMap: [EnginePeer.Id: DestinationRow] = [:]
    private let statusDisposables = DisposableSet()
    private var cancellationRequested = false

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let summaryLabel = UILabel()
    private let resultLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let cancelButton = UIButton(type: .system)
    private let doneButton = UIButton(type: .system)

    private var strings: KislapBatchForwardProgressStrings {
        return KislapBatchForwardProgressStrings(languageCode: self.presentationData.strings.baseLanguageCode)
    }

    init(context: AccountContext, destinations: [(id: EnginePeer.Id, name: String)]) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.destinations = destinations.map { Destination(id: $0.id, name: $0.name) }
        for destination in self.destinations {
            self.destinationMap[destination.id] = destination
        }

        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData, style: .glass))

        self._hasGlassStyle = true
        self.title = self.strings.title
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.strings.close, style: .plain, target: self, action: #selector(self.closePressed))
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.statusDisposables.dispose()
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
        self.contentStack.spacing = 12.0
        self.contentStack.translatesAutoresizingMaskIntoConstraints = false

        self.contentStack.addArrangedSubview(self.label(self.strings.eyebrow, size: 13.0, weight: .semibold, color: theme.list.itemAccentColor))
        self.contentStack.addArrangedSubview(self.label(self.strings.headline, size: 27.0, weight: .bold, color: theme.list.itemPrimaryTextColor))

        self.summaryLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
        self.summaryLabel.textColor = theme.list.itemPrimaryTextColor
        self.resultLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
        self.resultLabel.textColor = theme.list.itemSecondaryTextColor
        self.progressView.progressTintColor = KislapBrandPalette.brandPurple
        self.progressView.trackTintColor = theme.list.controlSecondaryColor
        self.progressView.heightAnchor.constraint(equalToConstant: 6.0).isActive = true

        let progressStack = UIStackView(arrangedSubviews: [self.summaryLabel, self.progressView, self.resultLabel])
        progressStack.axis = .vertical
        progressStack.spacing = 9.0
        self.contentStack.setCustomSpacing(20.0, after: self.contentStack.arrangedSubviews.last!)
        self.contentStack.addArrangedSubview(self.card(containing: progressStack))

        for destination in self.destinations {
            let row = DestinationRow(name: destination.name, theme: theme)
            self.rowMap[destination.id] = row
            self.contentStack.addArrangedSubview(row)
        }

        self.cancelButton.setTitle(self.strings.cancelPending, for: .normal)
        self.cancelButton.setTitleColor(KislapBrandPalette.brandCoral, for: .normal)
        self.cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        self.cancelButton.backgroundColor = KislapBrandPalette.brandCoral.withAlphaComponent(theme.overallDarkAppearance ? 0.18 : 0.10)
        self.cancelButton.layer.cornerRadius = 14.0
        self.cancelButton.heightAnchor.constraint(equalToConstant: 52.0).isActive = true
        self.cancelButton.addTarget(self, action: #selector(self.cancelPendingPressed), for: .touchUpInside)

        self.doneButton.setTitle(self.strings.done, for: .normal)
        self.doneButton.setTitleColor(.white, for: .normal)
        self.doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .bold)
        self.doneButton.backgroundColor = KislapBrandPalette.brandPurple
        self.doneButton.layer.cornerRadius = 14.0
        self.doneButton.heightAnchor.constraint(equalToConstant: 52.0).isActive = true
        self.doneButton.addTarget(self, action: #selector(self.closePressed), for: .touchUpInside)
        self.doneButton.isHidden = true

        self.contentStack.setCustomSpacing(20.0, after: self.contentStack.arrangedSubviews.last!)
        self.contentStack.addArrangedSubview(self.cancelButton)
        self.contentStack.addArrangedSubview(self.doneButton)

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

        self.refreshUI(animated: false)
    }

    func markEnqueued(peerId: EnginePeer.Id, messageIds: [EngineMessage.Id]) {
        guard let destination = self.destinationMap[peerId] else {
            return
        }
        if self.cancellationRequested {
            self.deletePending(messageIds)
            destination.pendingIds.removeAll()
            destination.state = .cancelled
            self.refreshUI(animated: true)
            return
        }
        guard !destination.state.terminal else {
            return
        }
        guard !messageIds.isEmpty else {
            destination.state = .failed
            self.refreshUI(animated: true)
            return
        }

        destination.pendingIds = Set(messageIds)
        destination.state = .sending
        let statusSignals: [Signal<(EngineMessage.Id, PendingMessageStatus?, PendingMessageFailureReason?), NoError>] = messageIds.map { id in
            return self.context.account.pendingMessageManager.pendingMessageStatus(id)
            |> map { status, error in
                return (id, status, error)
            }
        }
        let disposable = (combineLatest(statusSignals)
        |> deliverOnMainQueue).startStrict(next: { [weak self] statuses in
            self?.apply(statuses: statuses, peerId: peerId)
        })
        self.statusDisposables.add(disposable)
        self.refreshUI(animated: true)
    }

    func markFailed(peerId: EnginePeer.Id) {
        guard let destination = self.destinationMap[peerId], !destination.state.terminal else {
            return
        }
        destination.state = self.cancellationRequested ? .cancelled : .failed
        self.refreshUI(animated: true)
    }

    private func apply(statuses: [(EngineMessage.Id, PendingMessageStatus?, PendingMessageFailureReason?)], peerId: EnginePeer.Id) {
        guard let destination = self.destinationMap[peerId], destination.state != .cancelled else {
            return
        }

        var pendingIds = Set<EngineMessage.Id>()
        for (id, status, error) in statuses {
            if error != nil {
                destination.hadFailure = true
                self.deletePending([id])
            } else if status != nil {
                pendingIds.insert(id)
            }
        }
        destination.pendingIds = pendingIds
        if pendingIds.isEmpty {
            destination.state = destination.hadFailure ? .failed : .sent
        } else {
            destination.state = .sending
        }
        self.refreshUI(animated: true)
    }

    private func deletePending(_ messageIds: [EngineMessage.Id]) {
        guard !messageIds.isEmpty else {
            return
        }
        let _ = self.context.engine.messages.deleteMessagesInteractively(messageIds: messageIds, type: .forEveryone).startStandalone()
    }

    private func refreshUI(animated: Bool) {
        guard self.isNodeLoaded else {
            return
        }

        var sent = 0
        var failed = 0
        var cancelled = 0
        for destination in self.destinations {
            switch destination.state {
            case .sent:
                sent += 1
            case .failed:
                failed += 1
            case .cancelled:
                cancelled += 1
            case .queued, .sending:
                break
            }
            if let row = self.rowMap[destination.id] {
                self.update(row: row, state: destination.state)
            }
        }

        let completed = sent + failed + cancelled
        self.summaryLabel.text = self.strings.summary(completed: completed, total: self.destinations.count)
        self.resultLabel.text = self.cancellationRequested && completed < self.destinations.count ? self.strings.cancelling : self.strings.result(sent: sent, failed: failed, cancelled: cancelled)
        self.progressView.setProgress(self.destinations.isEmpty ? 1.0 : Float(completed) / Float(self.destinations.count), animated: animated)

        let allDone = completed == self.destinations.count
        self.cancelButton.isHidden = allDone
        self.doneButton.isHidden = !allDone
        self.cancelButton.isEnabled = !self.cancellationRequested
        self.cancelButton.alpha = self.cancellationRequested ? 0.55 : 1.0
    }

    private func update(row: DestinationRow, state: DestinationState) {
        let iconName: String
        let text: String
        let tint: UIColor
        switch state {
        case .queued:
            iconName = "clock.fill"
            text = self.strings.queued
            tint = self.presentationData.theme.list.itemSecondaryTextColor
        case .sending:
            iconName = "arrow.up.circle.fill"
            text = self.strings.sending
            tint = KislapBrandPalette.connection
        case .sent:
            iconName = "checkmark.circle.fill"
            text = self.strings.sent
            tint = KislapBrandPalette.success
        case .failed:
            iconName = "exclamationmark.circle.fill"
            text = self.strings.failed
            tint = KislapBrandPalette.brandCoral
        case .cancelled:
            iconName = "xmark.circle.fill"
            text = self.strings.cancelled
            tint = self.presentationData.theme.list.itemSecondaryTextColor
        }
        row.iconView.image = UIImage(systemName: iconName)
        row.iconView.tintColor = tint
        row.statusLabel.text = text
        row.statusLabel.textColor = tint
    }

    private func label(_ text: String, size: CGFloat, weight: UIFont.Weight, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.numberOfLines = 0
        return label
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

    @objc private func cancelPendingPressed() {
        guard !self.cancellationRequested else {
            return
        }
        self.cancellationRequested = true
        var messageIds = Set<EngineMessage.Id>()
        for destination in self.destinations where !destination.state.terminal {
            messageIds.formUnion(destination.pendingIds)
            destination.pendingIds.removeAll()
            destination.state = .cancelled
        }
        self.deletePending(Array(messageIds))
        self.refreshUI(animated: true)
    }

    @objc private func closePressed() {
        self.dismiss(animated: true)
    }
}
