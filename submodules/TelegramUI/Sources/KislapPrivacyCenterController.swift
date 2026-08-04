import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import AccountContext

final class KislapPrivacyCenterController: ViewController {
    private let context: AccountContext
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    private var preferenceObserver: NSObjectProtocol?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let eyebrowLabel = UILabel()
    private let headlineLabel = UILabel()
    private let detailLabel = UILabel()
    private let statusCard = UIView()
    private let statusIcon = UIImageView()
    private let statusTitleLabel = UILabel()
    private let statusDetailLabel = UILabel()
    private let peekCard = UIView()
    private let peekTitleLabel = UILabel()
    private let peekDetailLabel = UILabel()
    private let peekSwitch = UISwitch()
    private let stealthCard = UIView()
    private let stealthTitleLabel = UILabel()
    private let stealthDetailLabel = UILabel()
    private let stealthSwitch = UISwitch()
    private let durationCard = UIView()
    private let durationTitleLabel = UILabel()
    private let durationControl = UISegmentedControl(items: ["1h", "8h", "∞"])
    private let networkCard = UIView()
    private let networkTitleLabel = UILabel()
    private let networkDetailLabel = UILabel()
    private var appliedLanguageCode: String

    private var strings: KislapPrivacyCenterStrings {
        return KislapPrivacyCenterStrings(languageCode: self.presentationData.strings.baseLanguageCode)
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
                self?.updatePreferenceState()
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

        self.eyebrowLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        self.headlineLabel.font = UIFont.systemFont(ofSize: 29.0, weight: .bold)
        self.headlineLabel.numberOfLines = 0
        self.detailLabel.font = UIFont.systemFont(ofSize: 16.0)
        self.detailLabel.numberOfLines = 0

        self.configureCard(self.statusCard)
        self.statusIcon.contentMode = .scaleAspectFit
        self.statusIcon.translatesAutoresizingMaskIntoConstraints = false
        self.statusTitleLabel.font = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        self.statusTitleLabel.numberOfLines = 0
        self.statusDetailLabel.font = UIFont.systemFont(ofSize: 14.0)
        self.statusDetailLabel.numberOfLines = 0
        let statusTextStack = UIStackView(arrangedSubviews: [self.statusTitleLabel, self.statusDetailLabel])
        statusTextStack.axis = .vertical
        statusTextStack.spacing = 3.0
        let statusStack = UIStackView(arrangedSubviews: [self.statusIcon, statusTextStack])
        statusStack.axis = .horizontal
        statusStack.alignment = .center
        statusStack.spacing = 14.0
        statusStack.translatesAutoresizingMaskIntoConstraints = false
        self.statusCard.addSubview(statusStack)
        NSLayoutConstraint.activate([
            self.statusIcon.widthAnchor.constraint(equalToConstant: 36.0),
            self.statusIcon.heightAnchor.constraint(equalToConstant: 36.0),
            statusStack.topAnchor.constraint(equalTo: self.statusCard.topAnchor, constant: 17.0),
            statusStack.leadingAnchor.constraint(equalTo: self.statusCard.leadingAnchor, constant: 17.0),
            statusStack.trailingAnchor.constraint(equalTo: self.statusCard.trailingAnchor, constant: -17.0),
            statusStack.bottomAnchor.constraint(equalTo: self.statusCard.bottomAnchor, constant: -17.0),
        ])

        self.configureToggleCard(
            self.peekCard,
            titleLabel: self.peekTitleLabel,
            detailLabel: self.peekDetailLabel,
            control: self.peekSwitch,
            selector: #selector(self.peekSwitchChanged)
        )
        self.configureToggleCard(
            self.stealthCard,
            titleLabel: self.stealthTitleLabel,
            detailLabel: self.stealthDetailLabel,
            control: self.stealthSwitch,
            selector: #selector(self.stealthSwitchChanged)
        )

        self.configureCard(self.durationCard)
        self.durationTitleLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .semibold)
        self.durationTitleLabel.numberOfLines = 0
        self.durationControl.addTarget(self, action: #selector(self.durationChanged), for: .valueChanged)
        let durationStack = UIStackView(arrangedSubviews: [self.durationTitleLabel, self.durationControl])
        durationStack.axis = .vertical
        durationStack.spacing = 10.0
        durationStack.translatesAutoresizingMaskIntoConstraints = false
        self.durationCard.addSubview(durationStack)
        NSLayoutConstraint.activate([
            durationStack.topAnchor.constraint(equalTo: self.durationCard.topAnchor, constant: 14.0),
            durationStack.leadingAnchor.constraint(equalTo: self.durationCard.leadingAnchor, constant: 17.0),
            durationStack.trailingAnchor.constraint(equalTo: self.durationCard.trailingAnchor, constant: -17.0),
            durationStack.bottomAnchor.constraint(equalTo: self.durationCard.bottomAnchor, constant: -14.0),
        ])

        self.configureCard(self.networkCard)
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

        self.contentStack.addArrangedSubview(self.eyebrowLabel)
        self.contentStack.addArrangedSubview(self.headlineLabel)
        self.contentStack.addArrangedSubview(self.detailLabel)
        self.contentStack.setCustomSpacing(22.0, after: self.detailLabel)
        self.contentStack.addArrangedSubview(self.statusCard)
        self.contentStack.addArrangedSubview(self.peekCard)
        self.contentStack.addArrangedSubview(self.stealthCard)
        self.contentStack.addArrangedSubview(self.durationCard)
        self.contentStack.setCustomSpacing(22.0, after: self.durationCard)
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
        self.updatePreferenceState()
    }

    private func configureCard(_ card: UIView) {
        card.layer.cornerRadius = 16.0
        card.layer.borderWidth = UIScreenPixel
    }

    private func configureToggleCard(_ card: UIView, titleLabel: UILabel, detailLabel: UILabel, control: UISwitch, selector: Selector) {
        self.configureCard(card)
        titleLabel.font = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        titleLabel.numberOfLines = 0
        detailLabel.font = UIFont.systemFont(ofSize: 14.0)
        detailLabel.numberOfLines = 0
        control.addTarget(self, action: selector, for: .valueChanged)
        control.setContentHuggingPriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        textStack.axis = .vertical
        textStack.spacing = 4.0
        let row = UIStackView(arrangedSubviews: [textStack, control])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 16.0
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 17.0),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 17.0),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -17.0),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -17.0),
        ])
    }

    private func updateLocalizedStrings() {
        let strings = self.strings
        self.title = strings.title
        self.eyebrowLabel.text = strings.eyebrow
        self.headlineLabel.text = strings.headline
        self.detailLabel.text = strings.detail
        self.peekTitleLabel.text = strings.peekTitle
        self.peekDetailLabel.text = strings.peekDetail
        self.stealthTitleLabel.text = strings.stealthTitle
        self.stealthDetailLabel.text = strings.stealthDetail
        self.durationTitleLabel.text = strings.durationTitle
        self.durationControl.setTitle(strings.oneHour, forSegmentAt: KislapStealthDuration.oneHour.rawValue)
        self.durationControl.setTitle(strings.eightHours, forSegmentAt: KislapStealthDuration.eightHours.rawValue)
        self.durationControl.setTitle(strings.always, forSegmentAt: KislapStealthDuration.always.rawValue)
        self.networkTitleLabel.text = strings.networkNoteTitle
        self.networkDetailLabel.text = strings.networkNote
        self.updatePreferenceState()
    }

    private func updateTheme() {
        guard self.isNodeLoaded else {
            return
        }
        let theme = self.presentationData.theme
        self.statusBar.statusBarStyle = theme.rootController.statusBarStyle.style
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData, style: .glass), transition: .immediate)
        self.displayNode.backgroundColor = theme.list.blocksBackgroundColor
        self.eyebrowLabel.textColor = theme.list.itemAccentColor
        self.headlineLabel.textColor = theme.list.itemPrimaryTextColor
        self.detailLabel.textColor = theme.list.itemSecondaryTextColor
        for card in [self.statusCard, self.peekCard, self.stealthCard, self.durationCard, self.networkCard] {
            card.backgroundColor = theme.list.itemBlocksBackgroundColor
            card.layer.borderColor = theme.list.itemBlocksSeparatorColor.cgColor
        }
        for label in [self.statusTitleLabel, self.peekTitleLabel, self.stealthTitleLabel, self.networkTitleLabel] {
            label.textColor = theme.list.itemPrimaryTextColor
        }
        for label in [self.statusDetailLabel, self.peekDetailLabel, self.stealthDetailLabel, self.networkDetailLabel] {
            label.textColor = theme.list.itemSecondaryTextColor
        }
        self.peekSwitch.onTintColor = theme.list.itemAccentColor
        self.stealthSwitch.onTintColor = KislapBrandPalette.brandPurple
        self.durationTitleLabel.textColor = theme.list.itemSecondaryTextColor
        self.durationControl.selectedSegmentTintColor = KislapBrandPalette.brandPurple
        self.updatePreferenceState()
    }

    private func updatePreferenceState() {
        guard self.isNodeLoaded else {
            return
        }
        let peekEnabled = KislapPrivacyPreferences.isPeekModeEnabled
        let stealthEnabled = KislapPrivacyPreferences.isStealthModeEnabled
        self.peekSwitch.setOn(peekEnabled, animated: true)
        self.stealthSwitch.setOn(stealthEnabled, animated: true)
        self.durationControl.isEnabled = stealthEnabled
        self.durationControl.selectedSegmentIndex = KislapPrivacyPreferences.stealthDuration.rawValue

        let strings = self.strings
        if peekEnabled || stealthEnabled {
            self.statusTitleLabel.text = strings.activeTitle
            self.statusIcon.image = UIImage(systemName: "shield.lefthalf.filled")
            self.statusIcon.tintColor = KislapBrandPalette.success
            if peekEnabled && stealthEnabled {
                self.statusDetailLabel.text = strings.bothActive
            } else if peekEnabled {
                self.statusDetailLabel.text = strings.peekActive
            } else if let expiresAt = KislapPrivacyPreferences.stealthExpiresAt {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                formatter.dateStyle = .none
                self.statusDetailLabel.text = strings.stealthActive(until: formatter.string(from: expiresAt))
            } else {
                self.statusDetailLabel.text = strings.stealthActive
            }
        } else {
            self.statusTitleLabel.text = strings.inactiveTitle
            self.statusDetailLabel.text = strings.noneActive
            self.statusIcon.image = UIImage(systemName: "shield")
            self.statusIcon.tintColor = self.presentationData.theme.list.itemSecondaryTextColor
        }
    }

    @objc private func peekSwitchChanged() {
        KislapPrivacyPreferences.isPeekModeEnabled = self.peekSwitch.isOn
    }

    @objc private func stealthSwitchChanged() {
        if self.stealthSwitch.isOn {
            KislapPrivacyPreferences.enableStealth(for: .oneHour)
        } else {
            KislapPrivacyPreferences.isStealthModeEnabled = false
        }
    }

    @objc private func durationChanged() {
        guard let duration = KislapStealthDuration(rawValue: self.durationControl.selectedSegmentIndex) else {
            return
        }
        KislapPrivacyPreferences.enableStealth(for: duration)
    }
}
