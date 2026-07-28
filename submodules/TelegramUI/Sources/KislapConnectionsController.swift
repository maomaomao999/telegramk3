import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import AccountContext

final class KislapConnectionsController: ViewController {
    private let context: AccountContext
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    private var appliedLanguageCode: String
    private let apiClient = KislapAPIClient.shared

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let headerCard = UIView()
    private let headerTitleLabel = UILabel()
    private let headerDetailLabel = UILabel()
    private let requestsTitleLabel = UILabel()
    private let requestsStack = UIStackView()
    private let connectionsTitleLabel = UILabel()
    private let connectionsStack = UIStackView()
    private let safetyCard = UIView()
    private let safetyLabel = UILabel()
    private let refreshControl = UIRefreshControl()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private var requests: [KislapConnectionRequest] = []
    private var connections: [KislapConnection] = []

    private var strings: KislapConnectionsStrings {
        return KislapConnectionsStrings(languageCode: self.presentationData.strings.baseLanguageCode)
    }

    init(context: AccountContext) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.appliedLanguageCode = self.presentationData.strings.baseLanguageCode
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData, style: .glass))

        self._hasGlassStyle = true
        self.title = self.strings.title
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)

        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).startStrict(next: { [weak self] presentationData in
            guard let self else { return }
            let languageChanged = self.appliedLanguageCode != presentationData.strings.baseLanguageCode
            self.presentationData = presentationData
            self.updateTheme()
            if languageChanged {
                self.appliedLanguageCode = presentationData.strings.baseLanguageCode
                self.updateLocalizedStrings()
                self.render()
            }
        })
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.presentationDataDisposable?.dispose()
    }

    override func loadDisplayNode() {
        let node = ASDisplayNode()
        self.displayNode = node
        self.displayNodeDidLoad()

        self.contentStack.axis = .vertical
        self.contentStack.spacing = 12.0
        self.requestsStack.axis = .vertical
        self.requestsStack.spacing = 10.0
        self.connectionsStack.axis = .vertical
        self.connectionsStack.spacing = 10.0

        self.configureHeader()
        self.requestsTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        self.connectionsTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        self.configureSafety()

        self.contentStack.addArrangedSubview(self.headerCard)
        self.contentStack.setCustomSpacing(22.0, after: self.headerCard)
        self.contentStack.addArrangedSubview(self.requestsTitleLabel)
        self.contentStack.addArrangedSubview(self.requestsStack)
        self.contentStack.setCustomSpacing(22.0, after: self.requestsStack)
        self.contentStack.addArrangedSubview(self.connectionsTitleLabel)
        self.contentStack.addArrangedSubview(self.connectionsStack)
        self.contentStack.setCustomSpacing(22.0, after: self.connectionsStack)
        self.contentStack.addArrangedSubview(self.safetyCard)

        self.scrollView.alwaysBounceVertical = true
        self.scrollView.refreshControl = self.refreshControl
        self.refreshControl.addTarget(self, action: #selector(self.refreshPulled), for: .valueChanged)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.contentStack.translatesAutoresizingMaskIntoConstraints = false
        node.view.addSubview(self.scrollView)
        self.scrollView.addSubview(self.contentStack)
        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: node.view.safeAreaLayoutGuide.topAnchor, constant: 52.0),
            self.scrollView.leadingAnchor.constraint(equalTo: node.view.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: node.view.trailingAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: node.view.safeAreaLayoutGuide.bottomAnchor),
            self.contentStack.topAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.topAnchor, constant: 18.0),
            self.contentStack.leadingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.leadingAnchor, constant: 16.0),
            self.contentStack.trailingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.trailingAnchor, constant: -16.0),
            self.contentStack.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor, constant: -32.0),
        ])

        self.updateLocalizedStrings()
        self.updateTheme()
        self.showLoading()
        self.loadConnections(showSpinner: true)
    }

    private func configureHeader() {
        self.styleCard(self.headerCard)
        let icon = UIImageView(image: UIImage(systemName: "person.2.fill"))
        icon.tintColor = KislapBrandPalette.connection
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        let iconBackground = UIView()
        iconBackground.backgroundColor = KislapBrandPalette.connection.withAlphaComponent(0.14)
        iconBackground.layer.cornerRadius = 12.0
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(icon)

        self.headerTitleLabel.font = UIFont.systemFont(ofSize: 21.0, weight: .bold)
        self.headerDetailLabel.font = UIFont.systemFont(ofSize: 14.0)
        self.headerDetailLabel.numberOfLines = 0
        let textStack = UIStackView(arrangedSubviews: [self.headerTitleLabel, self.headerDetailLabel])
        textStack.axis = .vertical
        textStack.spacing = 3.0
        let row = UIStackView(arrangedSubviews: [iconBackground, textStack, self.activityIndicator])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 13.0
        row.translatesAutoresizingMaskIntoConstraints = false
        self.headerCard.addSubview(row)
        NSLayoutConstraint.activate([
            iconBackground.widthAnchor.constraint(equalToConstant: 48.0),
            iconBackground.heightAnchor.constraint(equalToConstant: 48.0),
            icon.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24.0),
            icon.heightAnchor.constraint(equalToConstant: 24.0),
            row.topAnchor.constraint(equalTo: self.headerCard.topAnchor, constant: 16.0),
            row.leadingAnchor.constraint(equalTo: self.headerCard.leadingAnchor, constant: 16.0),
            row.trailingAnchor.constraint(equalTo: self.headerCard.trailingAnchor, constant: -16.0),
            row.bottomAnchor.constraint(equalTo: self.headerCard.bottomAnchor, constant: -16.0),
        ])
    }

    private func configureSafety() {
        self.styleCard(self.safetyCard)
        self.safetyLabel.font = UIFont.systemFont(ofSize: 14.0)
        self.safetyLabel.numberOfLines = 0
        self.safetyLabel.translatesAutoresizingMaskIntoConstraints = false
        self.safetyCard.addSubview(self.safetyLabel)
        NSLayoutConstraint.activate([
            self.safetyLabel.topAnchor.constraint(equalTo: self.safetyCard.topAnchor, constant: 15.0),
            self.safetyLabel.leadingAnchor.constraint(equalTo: self.safetyCard.leadingAnchor, constant: 16.0),
            self.safetyLabel.trailingAnchor.constraint(equalTo: self.safetyCard.trailingAnchor, constant: -16.0),
            self.safetyLabel.bottomAnchor.constraint(equalTo: self.safetyCard.bottomAnchor, constant: -15.0),
        ])
    }

    private func styleCard(_ view: UIView) {
        view.layer.cornerRadius = 14.0
        view.layer.borderWidth = UIScreenPixel
    }

    private func updateLocalizedStrings() {
        let strings = self.strings
        self.title = strings.title
        self.headerTitleLabel.text = strings.title
        self.headerDetailLabel.text = strings.subtitle
        self.requestsTitleLabel.text = strings.requestsTitle
        self.connectionsTitleLabel.text = strings.connectionsTitle
        self.safetyLabel.text = strings.safety
    }

    private func updateTheme() {
        guard self.isNodeLoaded else { return }
        let theme = self.presentationData.theme
        self.statusBar.statusBarStyle = theme.rootController.statusBarStyle.style
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData, style: .glass), transition: .immediate)
        self.displayNode.backgroundColor = theme.list.blocksBackgroundColor
        for card in [self.headerCard, self.safetyCard] {
            card.backgroundColor = theme.list.itemBlocksBackgroundColor
            card.layer.borderColor = theme.list.itemBlocksSeparatorColor.cgColor
        }
        self.headerTitleLabel.textColor = theme.list.itemPrimaryTextColor
        self.headerDetailLabel.textColor = theme.list.itemSecondaryTextColor
        self.requestsTitleLabel.textColor = theme.list.itemSecondaryTextColor
        self.connectionsTitleLabel.textColor = theme.list.itemSecondaryTextColor
        self.safetyLabel.textColor = theme.list.itemSecondaryTextColor
        self.render()
    }

    private func showLoading() {
        self.clear(self.requestsStack)
        self.clear(self.connectionsStack)
        self.requestsStack.addArrangedSubview(self.messageLabel("…"))
        self.connectionsStack.addArrangedSubview(self.messageLabel("…"))
    }

    private func loadConnections(showSpinner: Bool) {
        if showSpinner { self.activityIndicator.startAnimating() }
        self.apiClient.connections { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.activityIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
                switch result {
                case let .success(value):
                    self.requests = value.requests
                    self.connections = value.connections
                    self.render()
                case let .failure(error):
                    self.showError(title: self.strings.loadFailed, error: error, retry: true)
                }
            }
        }
    }

    private func render() {
        guard self.isNodeLoaded else { return }
        self.clear(self.requestsStack)
        self.clear(self.connectionsStack)
        if self.requests.isEmpty {
            self.requestsStack.addArrangedSubview(self.messageCard(self.strings.requestsEmpty))
        } else {
            for (index, request) in self.requests.enumerated() {
                self.requestsStack.addArrangedSubview(self.requestCard(request, index: index))
            }
        }
        if self.connections.isEmpty {
            self.connectionsStack.addArrangedSubview(self.messageCard(self.strings.connectionsEmpty))
        } else {
            for (index, connection) in self.connections.enumerated() {
                self.connectionsStack.addArrangedSubview(self.connectionCard(connection, index: index))
            }
        }
    }

    private func requestCard(_ request: KislapConnectionRequest, index: Int) -> UIView {
        let name = self.personHeader(request.sender, purpose: request.purpose)
        let message = self.messageLabel(request.message ?? self.purposeText(request.purpose))
        let accept = UIButton(type: .system)
        accept.tag = index
        accept.setTitle(self.strings.accept, for: .normal)
        accept.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
        accept.setTitleColor(.white, for: .normal)
        accept.backgroundColor = self.presentationData.theme.list.itemAccentColor
        accept.layer.cornerRadius = 10.0
        accept.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        accept.addTarget(self, action: #selector(self.acceptPressed(_:)), for: .touchUpInside)
        let decline = UIButton(type: .system)
        decline.tag = index
        decline.setTitle(self.strings.decline, for: .normal)
        decline.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
        decline.setTitleColor(self.presentationData.theme.list.itemSecondaryTextColor, for: .normal)
        decline.backgroundColor = self.presentationData.theme.list.controlSecondaryColor
        decline.layer.cornerRadius = 10.0
        decline.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        decline.addTarget(self, action: #selector(self.declinePressed(_:)), for: .touchUpInside)
        let actions = UIStackView(arrangedSubviews: [decline, accept])
        actions.axis = .horizontal
        actions.distribution = .fillEqually
        actions.spacing = 10.0
        return self.wrapCard(UIStackView(arrangedSubviews: [name, message, actions]))
    }

    private func connectionCard(_ connection: KislapConnection, index: Int) -> UIView {
        let name = self.personHeader(connection.otherUser, purpose: connection.purpose)
        let chat = UIButton(type: .system)
        chat.tag = index
        chat.setTitle(self.strings.chat, for: .normal)
        chat.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
        chat.setTitleColor(.white, for: .normal)
        chat.backgroundColor = self.presentationData.theme.list.itemAccentColor
        chat.layer.cornerRadius = 10.0
        chat.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        chat.addTarget(self, action: #selector(self.openChatPressed(_:)), for: .touchUpInside)
        let remove = UIButton(type: .system)
        remove.tag = index
        remove.setTitle(self.strings.remove, for: .normal)
        remove.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
        remove.setTitleColor(self.presentationData.theme.list.itemDestructiveColor, for: .normal)
        remove.backgroundColor = self.presentationData.theme.list.controlSecondaryColor
        remove.layer.cornerRadius = 10.0
        remove.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        remove.addTarget(self, action: #selector(self.removePressed(_:)), for: .touchUpInside)
        let actions = UIStackView(arrangedSubviews: [chat, remove])
        actions.axis = .horizontal
        actions.distribution = .fillEqually
        actions.spacing = 10.0
        return self.wrapCard(UIStackView(arrangedSubviews: [name, actions]))
    }

    private func personHeader(_ person: KislapConnectionPerson, purpose: String) -> UIView {
        let avatar = UILabel()
        avatar.text = self.initials(person.displayName)
        avatar.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        avatar.textAlignment = .center
        avatar.textColor = self.presentationData.theme.list.itemAccentColor
        avatar.backgroundColor = self.presentationData.theme.list.itemAccentColor.withAlphaComponent(0.14)
        avatar.layer.cornerRadius = 21.0
        avatar.clipsToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        let name = UILabel()
        name.text = person.displayName
        name.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        name.textColor = self.presentationData.theme.list.itemPrimaryTextColor
        let purposeLabel = UILabel()
        purposeLabel.text = self.purposeText(purpose)
        purposeLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
        purposeLabel.textColor = purpose == "DATING" ? KislapBrandPalette.dating : self.presentationData.theme.list.itemAccentColor
        let text = UIStackView(arrangedSubviews: [name, purposeLabel])
        text.axis = .vertical
        text.spacing = 2.0
        let row = UIStackView(arrangedSubviews: [avatar, text])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12.0
        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 42.0),
            avatar.heightAnchor.constraint(equalToConstant: 42.0),
        ])
        return row
    }

    private func wrapCard(_ stack: UIStackView) -> UIView {
        let card = UIView()
        self.styleCard(card)
        card.backgroundColor = self.presentationData.theme.list.itemBlocksBackgroundColor
        card.layer.borderColor = self.presentationData.theme.list.itemBlocksSeparatorColor.cgColor
        stack.axis = .vertical
        stack.spacing = 11.0
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14.0),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 15.0),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -15.0),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14.0),
        ])
        return card
    }

    private func messageCard(_ text: String) -> UIView {
        let label = self.messageLabel(text)
        return self.wrapCard(UIStackView(arrangedSubviews: [label]))
    }

    private func messageLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = self.presentationData.theme.list.itemSecondaryTextColor
        label.numberOfLines = 0
        return label
    }

    private func clear(_ stack: UIStackView) {
        for view in stack.arrangedSubviews {
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    private func purposeText(_ purpose: String) -> String {
        switch purpose {
        case "SKILL_EXCHANGE": return self.strings.skillExchange
        case "DATING": return self.strings.dating
        default: return self.strings.studyPartner
        }
    }

    private func initials(_ name: String) -> String {
        let value = name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
        return value.isEmpty ? "K" : value.uppercased()
    }

    @objc private func refreshPulled() {
        self.loadConnections(showSpinner: false)
    }

    @objc private func acceptPressed(_ sender: UIButton) {
        self.respond(index: sender.tag, accept: true)
    }

    @objc private func declinePressed(_ sender: UIButton) {
        self.respond(index: sender.tag, accept: false)
    }

    private func respond(index: Int, accept: Bool) {
        guard self.requests.indices.contains(index) else { return }
        self.activityIndicator.startAnimating()
        self.apiClient.respondToConnectionRequest(id: self.requests[index].id, accept: accept) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success: self.loadConnections(showSpinner: false)
                case let .failure(error):
                    self.activityIndicator.stopAnimating()
                    self.showError(title: self.strings.actionFailed, error: error, retry: false)
                }
            }
        }
    }

    @objc private func removePressed(_ sender: UIButton) {
        guard self.connections.indices.contains(sender.tag) else { return }
        let connection = self.connections[sender.tag]
        let alert = UIAlertController(title: connection.otherUser.displayName, message: self.strings.removeMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.strings.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: self.strings.remove, style: .destructive, handler: { [weak self] _ in
            guard let self else { return }
            self.apiClient.removeConnection(id: connection.id) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self else { return }
                    switch result {
                    case .success: self.loadConnections(showSpinner: true)
                    case let .failure(error): self.showError(title: self.strings.actionFailed, error: error, retry: false)
                    }
                }
            }
        }))
        self.present(alert, animated: true)
    }

    @objc private func openChatPressed(_ sender: UIButton) {
        guard self.connections.indices.contains(sender.tag) else { return }
        let controller = KislapConversationController(context: self.context, connection: self.connections[sender.tag], onConnectionChanged: { [weak self] in
            self?.loadConnections(showSpinner: true)
        })
        (self.navigationController as? NavigationController)?.pushViewController(controller)
    }

    private func showError(title: String, error: Error, retry: Bool) {
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.strings.ok, style: .cancel))
        if retry {
            alert.addAction(UIAlertAction(title: self.strings.retry, style: .default, handler: { [weak self] _ in self?.loadConnections(showSpinner: true) }))
        }
        self.present(alert, animated: true)
    }
}
