import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import AccountContext

final class KislapConversationController: ViewController, UITextViewDelegate {
    private let context: AccountContext
    private let connection: KislapConnection
    private let onConnectionChanged: () -> Void
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    private var appliedLanguageCode: String
    private let apiClient = KislapAPIClient.shared

    private let scrollView = UIScrollView()
    private let messagesStack = UIStackView()
    private let noticeCard = UIView()
    private let noticeLabel = UILabel()
    private let inputBar = UIView()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let sendButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var inputBottomConstraint: NSLayoutConstraint?
    private var messages: [KislapConnectionMessage] = []
    private var pollTimer: Foundation.Timer?
    private var isLoading = false
    private var isSending = false
    private var isUnavailable = false

    private var strings: KislapConversationStrings {
        return KislapConversationStrings(languageCode: self.presentationData.strings.baseLanguageCode)
    }

    init(context: AccountContext, connection: KislapConnection, onConnectionChanged: @escaping () -> Void) {
        self.context = context
        self.connection = connection
        self.onConnectionChanged = onConnectionChanged
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.appliedLanguageCode = self.presentationData.strings.baseLanguageCode
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData, style: .glass))

        self._hasGlassStyle = true
        self.title = connection.otherUser.displayName
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: self.strings.safety, style: .plain, target: self, action: #selector(self.safetyPressed))

        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).startStrict(next: { [weak self] presentationData in
            guard let self else { return }
            let languageChanged = self.appliedLanguageCode != presentationData.strings.baseLanguageCode
            self.presentationData = presentationData
            self.updateTheme()
            if languageChanged {
                self.appliedLanguageCode = presentationData.strings.baseLanguageCode
                self.updateLocalizedStrings()
                self.renderMessages(scrollToBottom: false)
            }
        })
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.presentationDataDisposable?.dispose()
        self.pollTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    override func loadDisplayNode() {
        let node = ASDisplayNode()
        self.displayNode = node
        self.displayNodeDidLoad()

        self.configureMessages()
        self.configureInput()
        self.updateLocalizedStrings()
        self.updateTheme()
        self.renderMessages(scrollToBottom: false)
        self.loadMessages(showSpinner: true, presentErrors: true)

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardFrameChanged(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.pollTimer?.invalidate()
        self.pollTimer = Foundation.Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true, block: { [weak self] _ in
            self?.loadMessages(showSpinner: false, presentErrors: false)
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.pollTimer?.invalidate()
        self.pollTimer = nil
    }

    private func configureMessages() {
        self.scrollView.alwaysBounceVertical = true
        self.scrollView.keyboardDismissMode = .interactive
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.messagesStack.axis = .vertical
        self.messagesStack.spacing = 8.0
        self.messagesStack.translatesAutoresizingMaskIntoConstraints = false

        self.noticeCard.layer.cornerRadius = 12.0
        self.noticeCard.layer.borderWidth = UIScreenPixel
        self.noticeLabel.font = UIFont.systemFont(ofSize: 13.0)
        self.noticeLabel.numberOfLines = 0
        self.noticeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.noticeCard.addSubview(self.noticeLabel)
        NSLayoutConstraint.activate([
            self.noticeLabel.topAnchor.constraint(equalTo: self.noticeCard.topAnchor, constant: 11.0),
            self.noticeLabel.leadingAnchor.constraint(equalTo: self.noticeCard.leadingAnchor, constant: 13.0),
            self.noticeLabel.trailingAnchor.constraint(equalTo: self.noticeCard.trailingAnchor, constant: -13.0),
            self.noticeLabel.bottomAnchor.constraint(equalTo: self.noticeCard.bottomAnchor, constant: -11.0),
        ])
        self.messagesStack.addArrangedSubview(self.noticeCard)
        self.messagesStack.setCustomSpacing(14.0, after: self.noticeCard)

        self.displayNode.view.addSubview(self.scrollView)
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.displayNode.view.addSubview(self.activityIndicator)
        self.scrollView.addSubview(self.messagesStack)
        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: self.displayNode.view.safeAreaLayoutGuide.topAnchor, constant: 52.0),
            self.scrollView.leadingAnchor.constraint(equalTo: self.displayNode.view.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.displayNode.view.trailingAnchor),
            self.activityIndicator.centerXAnchor.constraint(equalTo: self.displayNode.view.centerXAnchor),
            self.activityIndicator.centerYAnchor.constraint(equalTo: self.displayNode.view.centerYAnchor),
            self.messagesStack.topAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.topAnchor, constant: 12.0),
            self.messagesStack.leadingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.leadingAnchor, constant: 12.0),
            self.messagesStack.trailingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.trailingAnchor, constant: -12.0),
            self.messagesStack.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor, constant: -12.0),
        ])
    }

    private func configureInput() {
        self.inputBar.translatesAutoresizingMaskIntoConstraints = false
        self.inputBar.layer.borderWidth = UIScreenPixel
        self.textView.font = UIFont.systemFont(ofSize: 16.0)
        self.textView.delegate = self
        self.textView.isScrollEnabled = true
        self.textView.layer.cornerRadius = 18.0
        self.textView.textContainerInset = UIEdgeInsets(top: 8.0, left: 10.0, bottom: 8.0, right: 10.0)
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        self.placeholderLabel.font = UIFont.systemFont(ofSize: 16.0)
        self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        self.textView.addSubview(self.placeholderLabel)
        self.sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
        self.sendButton.layer.cornerRadius = 18.0
        self.sendButton.translatesAutoresizingMaskIntoConstraints = false
        self.sendButton.addTarget(self, action: #selector(self.sendPressed), for: .touchUpInside)

        self.displayNode.view.addSubview(self.inputBar)
        self.inputBar.addSubview(self.textView)
        self.inputBar.addSubview(self.sendButton)
        let bottom = self.inputBar.bottomAnchor.constraint(equalTo: self.displayNode.view.safeAreaLayoutGuide.bottomAnchor)
        self.inputBottomConstraint = bottom
        NSLayoutConstraint.activate([
            self.scrollView.bottomAnchor.constraint(equalTo: self.inputBar.topAnchor),
            bottom,
            self.inputBar.leadingAnchor.constraint(equalTo: self.displayNode.view.leadingAnchor),
            self.inputBar.trailingAnchor.constraint(equalTo: self.displayNode.view.trailingAnchor),
            self.textView.topAnchor.constraint(equalTo: self.inputBar.topAnchor, constant: 8.0),
            self.textView.leadingAnchor.constraint(equalTo: self.inputBar.leadingAnchor, constant: 10.0),
            self.textView.bottomAnchor.constraint(equalTo: self.inputBar.bottomAnchor, constant: -8.0),
            self.textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 38.0),
            self.textView.heightAnchor.constraint(lessThanOrEqualToConstant: 100.0),
            self.sendButton.leadingAnchor.constraint(equalTo: self.textView.trailingAnchor, constant: 8.0),
            self.sendButton.trailingAnchor.constraint(equalTo: self.inputBar.trailingAnchor, constant: -10.0),
            self.sendButton.bottomAnchor.constraint(equalTo: self.textView.bottomAnchor),
            self.sendButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 62.0),
            self.sendButton.heightAnchor.constraint(equalToConstant: 38.0),
            self.placeholderLabel.leadingAnchor.constraint(equalTo: self.textView.leadingAnchor, constant: 15.0),
            self.placeholderLabel.topAnchor.constraint(equalTo: self.textView.topAnchor, constant: 9.0),
        ])
        self.updateSendState()
    }

    private func updateLocalizedStrings() {
        self.title = self.connection.otherUser.displayName
        self.navigationItem.rightBarButtonItem?.title = self.strings.safety
        self.noticeLabel.text = self.strings.notice
        self.placeholderLabel.text = self.strings.placeholder
        self.sendButton.setTitle(self.strings.send, for: .normal)
    }

    private func updateTheme() {
        guard self.isNodeLoaded else { return }
        let theme = self.presentationData.theme
        self.statusBar.statusBarStyle = theme.rootController.statusBarStyle.style
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData, style: .glass), transition: .immediate)
        self.displayNode.backgroundColor = theme.list.blocksBackgroundColor
        self.scrollView.backgroundColor = theme.list.blocksBackgroundColor
        self.noticeCard.backgroundColor = theme.list.itemBlocksBackgroundColor
        self.noticeCard.layer.borderColor = theme.list.itemBlocksSeparatorColor.cgColor
        self.noticeLabel.textColor = theme.list.itemSecondaryTextColor
        self.inputBar.backgroundColor = theme.list.itemBlocksBackgroundColor
        self.inputBar.layer.borderColor = theme.list.itemBlocksSeparatorColor.cgColor
        self.textView.backgroundColor = theme.list.controlSecondaryColor
        self.textView.textColor = theme.list.itemPrimaryTextColor
        self.placeholderLabel.textColor = theme.list.itemPlaceholderTextColor
        self.sendButton.backgroundColor = theme.list.itemAccentColor
        self.sendButton.setTitleColor(.white, for: .normal)
    }

    private func loadMessages(showSpinner: Bool, presentErrors: Bool) {
        guard !self.isLoading, !self.isUnavailable else { return }
        self.isLoading = true
        if showSpinner {
            self.activityIndicator.startAnimating()
        }
        self.apiClient.connectionMessages(id: self.connection.id) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                self.activityIndicator.stopAnimating()
                switch result {
                case let .success(messages):
                    let shouldScroll = self.messages.last?.id != messages.last?.id
                    self.messages = messages
                    self.renderMessages(scrollToBottom: shouldScroll)
                case let .failure(error):
                    if self.isConnectionUnavailable(error) {
                        self.handleUnavailable()
                    } else if presentErrors {
                        self.showError(title: self.strings.loadFailed, error: error, retry: true)
                    }
                }
            }
        }
    }

    private func renderMessages(scrollToBottom: Bool) {
        guard self.isNodeLoaded else { return }
        while self.messagesStack.arrangedSubviews.count > 1 {
            let view = self.messagesStack.arrangedSubviews.last!
            self.messagesStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        if self.messages.isEmpty {
            let label = UILabel()
            label.text = self.strings.empty
            label.font = UIFont.systemFont(ofSize: 14.0)
            label.textColor = self.presentationData.theme.list.itemSecondaryTextColor
            label.textAlignment = .center
            label.numberOfLines = 0
            let container = UIView()
            container.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: container.topAnchor, constant: 30.0),
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24.0),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24.0),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -30.0),
            ])
            self.messagesStack.addArrangedSubview(container)
        } else {
            for message in self.messages {
                self.messagesStack.addArrangedSubview(self.messageRow(message))
            }
        }
        if scrollToBottom {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let offset = max(0.0, self.scrollView.contentSize.height - self.scrollView.bounds.height + self.scrollView.adjustedContentInset.bottom)
                self.scrollView.setContentOffset(CGPoint(x: 0.0, y: offset), animated: true)
            }
        }
    }

    private func messageRow(_ message: KislapConnectionMessage) -> UIView {
        let bubble = UIView()
        bubble.layer.cornerRadius = 16.0
        bubble.backgroundColor = message.isMine ? self.presentationData.theme.list.itemAccentColor : self.presentationData.theme.list.itemBlocksBackgroundColor
        if !message.isMine {
            bubble.layer.borderWidth = UIScreenPixel
            bubble.layer.borderColor = self.presentationData.theme.list.itemBlocksSeparatorColor.cgColor
        }
        let body = UILabel()
        body.text = message.body
        body.font = UIFont.systemFont(ofSize: 16.0)
        body.textColor = message.isMine ? .white : self.presentationData.theme.list.itemPrimaryTextColor
        body.numberOfLines = 0
        let time = UILabel()
        time.text = self.timeText(message.createdAt)
        time.font = UIFont.systemFont(ofSize: 11.0)
        time.textColor = message.isMine ? UIColor.white.withAlphaComponent(0.72) : self.presentationData.theme.list.itemSecondaryTextColor
        time.textAlignment = .right
        let content = UIStackView(arrangedSubviews: [body, time])
        content.axis = .vertical
        content.spacing = 3.0
        content.translatesAutoresizingMaskIntoConstraints = false
        bubble.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 9.0),
            content.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12.0),
            content.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12.0),
            content.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -7.0),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: self.scrollView.frameLayoutGuide.widthAnchor, multiplier: 0.76),
        ])
        let spacer = UIView()
        let row = UIStackView(arrangedSubviews: message.isMine ? [spacer, bubble] : [bubble, spacer])
        row.axis = .horizontal
        row.alignment = .bottom
        return row
    }

    private func timeText(_ value: String) -> String {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fractional.date(from: value) ?? ISO8601DateFormatter().date(from: value) else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = self.strings.isChinese ? Locale(identifier: "zh_Hans") : Locale(identifier: "en_PH")
        return formatter.string(from: date)
    }

    @objc private func sendPressed() {
        let body = self.textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, body.count <= 1000, !self.isSending, !self.isUnavailable else { return }
        self.isSending = true
        self.updateSendState()
        self.apiClient.sendConnectionMessage(id: self.connection.id, body: body) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isSending = false
                switch result {
                case let .success(message):
                    self.textView.text = ""
                    self.placeholderLabel.isHidden = false
                    self.messages.append(message)
                    self.renderMessages(scrollToBottom: true)
                    self.updateSendState()
                case let .failure(error):
                    self.updateSendState()
                    if self.isConnectionUnavailable(error) {
                        self.handleUnavailable()
                    } else {
                        self.showError(title: self.strings.sendFailed, error: error, retry: false)
                    }
                }
            }
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        self.placeholderLabel.isHidden = !textView.text.isEmpty
        self.updateSendState()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let current = textView.text, let swiftRange = Range(range, in: current) else { return false }
        return current.replacingCharacters(in: swiftRange, with: text).count <= 1000
    }

    private func updateSendState() {
        let hasText = !(self.textView.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        self.sendButton.isEnabled = hasText && !self.isSending && !self.isUnavailable
        self.sendButton.alpha = self.sendButton.isEnabled ? 1.0 : 0.45
    }

    @objc private func safetyPressed() {
        let alert = UIAlertController(title: self.connection.otherUser.displayName, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.strings.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: self.strings.report, style: .default, handler: { [weak self] _ in self?.chooseReportReason() }))
        alert.addAction(UIAlertAction(title: self.strings.block, style: .destructive, handler: { [weak self] _ in self?.confirmBlock() }))
        self.present(alert, animated: true)
    }

    private func chooseReportReason() {
        let reasons = [
            ("HARASSMENT", self.strings.harassment),
            ("SPAM", self.strings.spam),
            ("INAPPROPRIATE_CONTENT", self.strings.inappropriate),
            ("SCAM", self.strings.scam),
            ("FAKE_PROFILE", self.strings.fakeProfile),
            ("UNDERAGE", self.strings.underage),
            ("OTHER", self.strings.other),
        ]
        let alert = UIAlertController(title: self.strings.reportReason, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.strings.cancel, style: .cancel))
        for reason in reasons {
            alert.addAction(UIAlertAction(title: reason.1, style: .default, handler: { [weak self] _ in
                self?.submitReport(reason: reason.0)
            }))
        }
        self.present(alert, animated: true)
    }

    private func submitReport(reason: String) {
        self.apiClient.report(userId: self.connection.otherUser.id, reason: reason, description: "Reported from an accepted Kislap learning conversation") { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    let alert = UIAlertController(title: self.strings.reportSent, message: self.strings.reportSentDetail, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: self.strings.ok, style: .default))
                    self.present(alert, animated: true)
                case let .failure(error):
                    self.showError(title: self.strings.reportFailed, error: error, retry: false)
                }
            }
        }
    }

    private func confirmBlock() {
        let alert = UIAlertController(title: self.strings.blockTitle, message: self.strings.blockMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.strings.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: self.strings.blockConfirm, style: .destructive, handler: { [weak self] _ in self?.performBlock() }))
        self.present(alert, animated: true)
    }

    private func performBlock() {
        self.textView.isEditable = false
        self.sendButton.isEnabled = false
        self.apiClient.block(userId: self.connection.otherUser.id) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    self.onConnectionChanged()
                    (self.navigationController as? NavigationController)?.filterController(self, animated: true)
                case let .failure(error):
                    self.textView.isEditable = true
                    self.updateSendState()
                    self.showError(title: self.strings.blockFailed, error: error, retry: false)
                }
            }
        }
    }

    private func isConnectionUnavailable(_ error: Error) -> Bool {
        if case let KislapAPIError.server(status, code) = error {
            return status == 404 && code == "connection_not_found"
        }
        return false
    }

    private func handleUnavailable() {
        guard !self.isUnavailable else { return }
        self.isUnavailable = true
        self.pollTimer?.invalidate()
        self.textView.isEditable = false
        self.updateSendState()
        let alert = UIAlertController(title: self.connection.otherUser.displayName, message: self.strings.connectionUnavailable, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.strings.ok, style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.onConnectionChanged()
            (self.navigationController as? NavigationController)?.filterController(self, animated: true)
        }))
        self.present(alert, animated: true)
    }

    private func showError(title: String, error: Error, retry: Bool) {
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.strings.ok, style: .cancel))
        if retry {
            alert.addAction(UIAlertAction(title: self.strings.retry, style: .default, handler: { [weak self] _ in self?.loadMessages(showSpinner: true, presentErrors: true) }))
        }
        self.present(alert, animated: true)
    }

    @objc private func keyboardFrameChanged(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let converted = self.displayNode.view.convert(frame, from: nil)
        let overlap = max(0.0, self.displayNode.view.bounds.maxY - converted.minY - self.displayNode.view.safeAreaInsets.bottom)
        self.animateKeyboard(notification: notification, constant: -overlap)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        self.animateKeyboard(notification: notification, constant: 0.0)
    }

    private func animateKeyboard(notification: Notification, constant: CGFloat) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        self.inputBottomConstraint?.constant = constant
        UIView.animate(withDuration: duration) {
            self.displayNode.view.layoutIfNeeded()
        }
    }
}
