import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import AccountContext

final class KislapHomeController: ViewController {
    private let context: AccountContext
    private let openMessages: () -> Void
    private let openCalls: () -> Void
    private let openNearby: () -> Void
    private let openPrivacy: () -> Void
    private let openBatchForward: () -> Void

    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    private var preferenceObserver: NSObjectProtocol?
    private var appliedLanguageCode: String

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let heroCard = UIView()
    private let eyebrowLabel = UILabel()
    private let headlineLabel = UILabel()
    private let detailLabel = UILabel()
    private let privacyStatusLabel = UILabel()
    private let toolsTitleLabel = UILabel()
    private let toolsStack = UIStackView()
    private let batchButton = UIButton(type: .system)
    private let peekButton = UIButton(type: .system)
    private let stealthButton = UIButton(type: .system)
    private let nearbyButton = UIButton(type: .system)
    private let communicationTitleLabel = UILabel()
    private let communicationStack = UIStackView()
    private let messagesButton = UIButton(type: .system)
    private let callsButton = UIButton(type: .system)
    private let networkCard = UIView()
    private let networkTitleLabel = UILabel()
    private let networkDetailLabel = UILabel()

    private var strings: KislapHomeStrings {
        return KislapHomeStrings(languageCode: self.presentationData.strings.baseLanguageCode)
    }

    init(
        context: AccountContext,
        openMessages: @escaping () -> Void,
        openCalls: @escaping () -> Void,
        openNearby: @escaping () -> Void,
        openPrivacy: @escaping () -> Void,
        openBatchForward: @escaping () -> Void
    ) {
        self.context = context
        self.openMessages = openMessages
        self.openCalls = openCalls
        self.openNearby = openNearby
        self.openPrivacy = openPrivacy
        self.openBatchForward = openBatchForward
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.appliedLanguageCode = self.presentationData.strings.baseLanguageCode

        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData, style: .glass))

        self._hasGlassStyle = true
        self.title = self.strings.title
        self.tabBarItem.title = self.strings.title
        self.tabBarItem.image = UIImage(systemName: "sparkles.rectangle.stack")
        self.tabBarItem.selectedImage = UIImage(systemName: "sparkles.rectangle.stack.fill")
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "shield.lefthalf.filled"), style: .plain, target: self, action: #selector(self.privacyPressed))

        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).startStrict(next: { [weak self] presentationData in
            guard let self else {
                return
            }
            let languageChanged = self.appliedLanguageCode != presentationData.strings.baseLanguageCode
            self.presentationData = presentationData
            self.updateTheme()
            if languageChanged {
                self.appliedLanguageCode = presentationData.strings.baseLanguageCode
                self.updateLocalizedStrings()
            }
        })

        self.preferenceObserver = NotificationCenter.default.addObserver(
            forName: .kislapPrivacyPreferencesDidChange,
            object: nil,
            queue: .main,
            using: { [weak self] _ in
                self?.updatePrivacyState()
            }
        )
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.presentationDataDisposable?.dispose()
        if let preferenceObserver = self.preferenceObserver {
            NotificationCenter.default.removeObserver(preferenceObserver)
        }
    }

    override func loadDisplayNode() {
        let node = ASDisplayNode()
        self.displayNode = node
        self.displayNodeDidLoad()

        self.scrollView.alwaysBounceVertical = true
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.contentStack.axis = .vertical
        self.contentStack.spacing = 14.0
        self.contentStack.translatesAutoresizingMaskIntoConstraints = false

        self.heroCard.layer.cornerRadius = 24.0
        self.heroCard.clipsToBounds = true
        self.eyebrowLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .bold)
        self.headlineLabel.font = UIFont.systemFont(ofSize: 31.0, weight: .bold)
        self.headlineLabel.numberOfLines = 0
        self.detailLabel.font = UIFont.systemFont(ofSize: 16.0)
        self.detailLabel.numberOfLines = 0
        self.privacyStatusLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        self.privacyStatusLabel.numberOfLines = 0
        self.privacyStatusLabel.layer.cornerRadius = 9.0
        self.privacyStatusLabel.clipsToBounds = true
        self.privacyStatusLabel.textAlignment = .center
        let heroStack = UIStackView(arrangedSubviews: [self.eyebrowLabel, self.headlineLabel, self.detailLabel, self.privacyStatusLabel])
        heroStack.axis = .vertical
        heroStack.spacing = 9.0
        heroStack.setCustomSpacing(16.0, after: self.detailLabel)
        heroStack.translatesAutoresizingMaskIntoConstraints = false
        self.heroCard.addSubview(heroStack)
        NSLayoutConstraint.activate([
            heroStack.topAnchor.constraint(equalTo: self.heroCard.topAnchor, constant: 22.0),
            heroStack.leadingAnchor.constraint(equalTo: self.heroCard.leadingAnchor, constant: 20.0),
            heroStack.trailingAnchor.constraint(equalTo: self.heroCard.trailingAnchor, constant: -20.0),
            heroStack.bottomAnchor.constraint(equalTo: self.heroCard.bottomAnchor, constant: -22.0),
            self.privacyStatusLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 34.0),
        ])

        self.toolsTitleLabel.font = UIFont.systemFont(ofSize: 21.0, weight: .bold)
        self.toolsTitleLabel.numberOfLines = 0
        self.toolsStack.axis = .vertical
        self.toolsStack.spacing = 11.0
        let toolButtons = [self.batchButton, self.peekButton, self.stealthButton, self.nearbyButton]
        for button in toolButtons {
            self.configureActionButton(button)
            self.toolsStack.addArrangedSubview(button)
        }
        self.batchButton.addTarget(self, action: #selector(self.batchPressed), for: .touchUpInside)
        self.peekButton.addTarget(self, action: #selector(self.privacyPressed), for: .touchUpInside)
        self.stealthButton.addTarget(self, action: #selector(self.privacyPressed), for: .touchUpInside)
        self.nearbyButton.addTarget(self, action: #selector(self.nearbyPressed), for: .touchUpInside)

        self.communicationTitleLabel.font = UIFont.systemFont(ofSize: 21.0, weight: .bold)
        self.communicationTitleLabel.numberOfLines = 0
        self.communicationStack.axis = .vertical
        self.communicationStack.spacing = 11.0
        for button in [self.messagesButton, self.callsButton] {
            self.configureActionButton(button)
            self.communicationStack.addArrangedSubview(button)
        }
        self.messagesButton.addTarget(self, action: #selector(self.messagesPressed), for: .touchUpInside)
        self.callsButton.addTarget(self, action: #selector(self.callsPressed), for: .touchUpInside)

        self.networkCard.layer.cornerRadius = 16.0
        self.networkCard.layer.borderWidth = UIScreenPixel
        self.networkTitleLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        self.networkTitleLabel.numberOfLines = 0
        self.networkDetailLabel.font = UIFont.systemFont(ofSize: 14.0)
        self.networkDetailLabel.numberOfLines = 0
        let networkStack = UIStackView(arrangedSubviews: [self.networkTitleLabel, self.networkDetailLabel])
        networkStack.axis = .vertical
        networkStack.spacing = 6.0
        networkStack.translatesAutoresizingMaskIntoConstraints = false
        self.networkCard.addSubview(networkStack)
        NSLayoutConstraint.activate([
            networkStack.topAnchor.constraint(equalTo: self.networkCard.topAnchor, constant: 17.0),
            networkStack.leadingAnchor.constraint(equalTo: self.networkCard.leadingAnchor, constant: 17.0),
            networkStack.trailingAnchor.constraint(equalTo: self.networkCard.trailingAnchor, constant: -17.0),
            networkStack.bottomAnchor.constraint(equalTo: self.networkCard.bottomAnchor, constant: -17.0),
        ])

        self.contentStack.addArrangedSubview(self.heroCard)
        self.contentStack.setCustomSpacing(24.0, after: self.heroCard)
        self.contentStack.addArrangedSubview(self.toolsTitleLabel)
        self.contentStack.addArrangedSubview(self.toolsStack)
        self.contentStack.setCustomSpacing(24.0, after: self.toolsStack)
        self.contentStack.addArrangedSubview(self.communicationTitleLabel)
        self.contentStack.addArrangedSubview(self.communicationStack)
        self.contentStack.setCustomSpacing(24.0, after: self.communicationStack)
        self.contentStack.addArrangedSubview(self.networkCard)

        node.view.addSubview(self.scrollView)
        self.scrollView.addSubview(self.contentStack)
        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: node.view.safeAreaLayoutGuide.topAnchor, constant: 48.0),
            self.scrollView.leadingAnchor.constraint(equalTo: node.view.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: node.view.trailingAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: node.view.safeAreaLayoutGuide.bottomAnchor),
            self.contentStack.topAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.topAnchor, constant: 18.0),
            self.contentStack.leadingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.leadingAnchor, constant: 20.0),
            self.contentStack.trailingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.trailingAnchor, constant: -20.0),
            self.contentStack.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor, constant: -32.0),
        ])

        self.updateLocalizedStrings()
        self.updateTheme()
        self.updatePrivacyState()
    }

    private func configureActionButton(_ button: UIButton) {
        button.contentHorizontalAlignment = .left
        button.contentVerticalAlignment = .center
        button.titleLabel?.numberOfLines = 0
        button.layer.cornerRadius = 16.0
        button.layer.borderWidth = UIScreenPixel
        button.contentEdgeInsets = UIEdgeInsets(top: 15.0, left: 16.0, bottom: 15.0, right: 16.0)
        button.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 12.0)
        button.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 0.0)
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 21.0, weight: .semibold), forImageIn: .normal)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 78.0).isActive = true
    }

    private func updateLocalizedStrings() {
        let strings = self.strings
        self.title = strings.title
        self.tabBarItem.title = strings.title
        self.eyebrowLabel.text = strings.eyebrow
        self.headlineLabel.text = strings.headline
        self.detailLabel.text = strings.detail
        self.toolsTitleLabel.text = strings.toolsTitle
        self.communicationTitleLabel.text = strings.communicationTitle
        self.networkTitleLabel.text = strings.networkTitle
        self.networkDetailLabel.text = strings.networkDetail
        self.configureButton(self.batchButton, title: strings.batchTitle, detail: strings.batchDetail, iconName: "rectangle.stack.badge.plus", tint: KislapBrandPalette.brandPurple)
        self.configureButton(self.peekButton, title: strings.peekTitle, detail: strings.peekDetail, iconName: "eye.circle.fill", tint: KislapBrandPalette.connection)
        self.configureButton(self.stealthButton, title: strings.stealthTitle, detail: strings.stealthDetail, iconName: "moon.stars.fill", tint: KislapBrandPalette.midnight)
        self.configureButton(self.nearbyButton, title: strings.nearbyTitle, detail: strings.nearbyDetail, iconName: "location.circle.fill", tint: KislapBrandPalette.success)
        self.configureButton(self.messagesButton, title: strings.messagesTitle, detail: strings.messagesDetail, iconName: "bubble.left.and.bubble.right.fill", tint: KislapBrandPalette.connection)
        self.configureButton(self.callsButton, title: strings.callsTitle, detail: strings.callsDetail, iconName: "phone.fill", tint: KislapBrandPalette.brandCoral)
        self.updatePrivacyState()
    }

    private func configureButton(_ button: UIButton, title: String, detail: String, iconName: String, tint: UIColor) {
        let theme = self.presentationData.theme
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 2.0
        let text = NSMutableAttributedString(string: title + "\n", attributes: [
            .font: UIFont.systemFont(ofSize: 17.0, weight: .bold),
            .foregroundColor: theme.list.itemPrimaryTextColor,
            .paragraphStyle: paragraph,
        ])
        text.append(NSAttributedString(string: detail, attributes: [
            .font: UIFont.systemFont(ofSize: 13.0),
            .foregroundColor: theme.list.itemSecondaryTextColor,
            .paragraphStyle: paragraph,
        ]))
        button.setAttributedTitle(text, for: .normal)
        button.setImage(UIImage(systemName: iconName), for: .normal)
        button.tintColor = tint
        button.backgroundColor = theme.list.itemBlocksBackgroundColor
        button.layer.borderColor = theme.list.itemBlocksSeparatorColor.cgColor
        button.accessibilityLabel = title + ". " + detail
    }

    private func updateTheme() {
        guard self.isNodeLoaded else {
            return
        }
        let theme = self.presentationData.theme
        self.statusBar.statusBarStyle = theme.rootController.statusBarStyle.style
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData, style: .glass), transition: .immediate)
        self.displayNode.backgroundColor = theme.list.blocksBackgroundColor
        self.heroCard.backgroundColor = KislapBrandPalette.brandPurple.withAlphaComponent(theme.overallDarkAppearance ? 0.28 : 0.13)
        self.eyebrowLabel.textColor = theme.list.itemAccentColor
        self.headlineLabel.textColor = theme.list.itemPrimaryTextColor
        self.detailLabel.textColor = theme.list.itemSecondaryTextColor
        self.toolsTitleLabel.textColor = theme.list.itemPrimaryTextColor
        self.communicationTitleLabel.textColor = theme.list.itemPrimaryTextColor
        self.networkCard.backgroundColor = theme.list.itemBlocksBackgroundColor
        self.networkCard.layer.borderColor = theme.list.itemBlocksSeparatorColor.cgColor
        self.networkTitleLabel.textColor = theme.list.itemPrimaryTextColor
        self.networkDetailLabel.textColor = theme.list.itemSecondaryTextColor
        self.updateLocalizedStrings()
    }

    private func updatePrivacyState() {
        guard self.isNodeLoaded else {
            return
        }
        let strings = self.strings
        let peek = KislapPrivacyPreferences.isPeekModeEnabled
        let stealth = KislapPrivacyPreferences.isStealthModeEnabled
        if peek && stealth {
            self.privacyStatusLabel.text = strings.bothStatus
        } else if peek {
            self.privacyStatusLabel.text = strings.peekStatus
        } else if stealth {
            self.privacyStatusLabel.text = strings.stealthStatus
        } else {
            self.privacyStatusLabel.text = strings.standardStatus
        }
        let active = peek || stealth
        self.privacyStatusLabel.textColor = active ? UIColor.white : self.presentationData.theme.list.itemSecondaryTextColor
        self.privacyStatusLabel.backgroundColor = active ? KislapBrandPalette.success : self.presentationData.theme.list.controlSecondaryColor
    }

    @objc private func messagesPressed() {
        self.openMessages()
    }

    @objc private func callsPressed() {
        self.openCalls()
    }

    @objc private func nearbyPressed() {
        self.openNearby()
    }

    @objc private func privacyPressed() {
        self.openPrivacy()
    }

    @objc private func batchPressed() {
        let strings = self.strings
        let alert = UIAlertController(title: strings.batchSheetTitle, message: strings.batchSheetDetail, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.presentationData.strings.Common_Cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: strings.openMessages, style: .default, handler: { [weak self] _ in
            self?.openBatchForward()
        }))
        self.present(alert, animated: true)
    }
}
