import Foundation
import UIKit
import CoreLocation
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import AccountContext

final class KislapNearbyController: ViewController, CLLocationManagerDelegate {
    private let context: AccountContext
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    private let locationManager = CLLocationManager()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let eyebrowLabel = UILabel()
    private let headlineLabel = UILabel()
    private let detailLabel = UILabel()
    private let journeyTitleLabel = UILabel()
    private let journeyStack = UIStackView()
    private let learnJourneyButton = UIButton(type: .system)
    private let teachJourneyButton = UIButton(type: .system)
    private let connectJourneyButton = UIButton(type: .system)
    private let permissionCard = UIView()
    private let permissionTitleLabel = UILabel()
    private let permissionDetailLabel = UILabel()
    private let accountButton = UIButton(type: .system)
    private let enableButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let topicControl = UISegmentedControl(items: ["", "", ""])
    private let partnersTitleLabel = UILabel()
    private let partnersStack = UIStackView()
    private let safetyCard = UIView()
    private let safetyTitleLabel = UILabel()
    private let safetyDetailLabel = UILabel()
    private var safetyPrimaryLabels: [UILabel] = []
    private var safetySecondaryLabels: [UILabel] = []
    private var safetySeparators: [UIView] = []
    private let apiClient = KislapAPIClient.shared
    private var isVisible = false
    private var awaitingExplicitLocationAuthorization = false
    private var currentPartners: [KislapLearningPartner] = []
    private var appliedLanguageCode: String

    private var strings: KislapNearbyStrings {
        return KislapNearbyStrings(languageCode: self.presentationData.strings.baseLanguageCode)
    }

    private var selectedSkill: String {
        switch self.topicControl.selectedSegmentIndex {
        case 1:
            return "programming"
        case 2:
            return "singing"
        default:
            return "english"
        }
    }

    init(context: AccountContext) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.appliedLanguageCode = self.presentationData.strings.baseLanguageCode

        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData, style: .glass))

        self._hasGlassStyle = true
        self.title = self.strings.nearbyTitle
        self.tabBarItem.title = self.strings.nearbyTitle
        self.tabBarItem.image = UIImage(systemName: "location.circle")
        self.tabBarItem.selectedImage = UIImage(systemName: "location.circle.fill")
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: self.strings.connections, style: .plain, target: self, action: #selector(self.connectionsPressed))

        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer

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
                self.title = self.strings.nearbyTitle
                self.tabBarItem.title = self.strings.nearbyTitle
                self.navigationItem.rightBarButtonItem?.title = self.strings.connections
                if self.isNodeLoaded {
                    self.updateLocalizedStrings(resetState: true)
                }
            }
        })
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.presentationDataDisposable?.dispose()
        self.locationManager.stopUpdatingLocation()
    }

    override func loadDisplayNode() {
        let node = ASDisplayNode()
        self.displayNode = node
        self.displayNodeDidLoad()

        self.contentStack.axis = .vertical
        self.contentStack.spacing = 14.0
        self.contentStack.alignment = .fill

        let strings = self.strings

        self.eyebrowLabel.text = strings.learningEyebrow
        self.eyebrowLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        self.eyebrowLabel.textColor = KislapBrandPalette.brandGold

        self.headlineLabel.text = strings.headline
        self.headlineLabel.font = UIFont.systemFont(ofSize: 28.0, weight: .bold)
        self.headlineLabel.numberOfLines = 0

        self.detailLabel.text = strings.detail
        self.detailLabel.font = UIFont.systemFont(ofSize: 17.0)
        self.detailLabel.numberOfLines = 0

        self.journeyTitleLabel.text = strings.journeyTitle
        self.journeyTitleLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .bold)
        self.journeyTitleLabel.numberOfLines = 0

        self.journeyStack.axis = .vertical
        self.journeyStack.spacing = 10.0
        let journeyButtons = [self.learnJourneyButton, self.teachJourneyButton, self.connectJourneyButton]
        for button in journeyButtons {
            button.contentHorizontalAlignment = .left
            button.contentVerticalAlignment = .center
            button.titleLabel?.numberOfLines = 0
            button.layer.cornerRadius = 14.0
            button.contentEdgeInsets = UIEdgeInsets(top: 13.0, left: 16.0, bottom: 13.0, right: 16.0)
            button.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 12.0)
            button.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 0.0)
            button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 21.0, weight: .semibold), forImageIn: .normal)
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 76.0).isActive = true
            self.journeyStack.addArrangedSubview(button)
        }
        self.learnJourneyButton.addTarget(self, action: #selector(self.learnJourneyPressed), for: .touchUpInside)
        self.teachJourneyButton.addTarget(self, action: #selector(self.teachJourneyPressed), for: .touchUpInside)
        self.connectJourneyButton.addTarget(self, action: #selector(self.connectJourneyPressed), for: .touchUpInside)
        self.updateJourneyButtons()

        self.permissionCard.layer.cornerRadius = 14.0
        self.permissionCard.layer.borderWidth = UIScreenPixel

        self.permissionTitleLabel.text = strings.locationOff
        self.permissionTitleLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .semibold)
        self.permissionTitleLabel.numberOfLines = 0

        self.permissionDetailLabel.text = strings.locationPrivacyDetail
        self.permissionDetailLabel.font = UIFont.systemFont(ofSize: 15.0)
        self.permissionDetailLabel.numberOfLines = 0

        self.accountButton.setTitle(self.apiClient.hasSession ? strings.learningProfileConnected : strings.connectLearningProfile, for: .normal)
        self.accountButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        self.accountButton.contentHorizontalAlignment = .left
        self.accountButton.addTarget(self, action: #selector(self.accountPressed), for: .touchUpInside)

        self.enableButton.setTitle(strings.enableNearbyLearning, for: .normal)
        self.enableButton.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        self.enableButton.setTitleColor(.white, for: .normal)
        self.enableButton.backgroundColor = self.presentationData.theme.list.itemAccentColor
        self.enableButton.layer.cornerRadius = 13.0
        self.enableButton.contentEdgeInsets = UIEdgeInsets(top: 14.0, left: 18.0, bottom: 14.0, right: 18.0)
        self.enableButton.addTarget(self, action: #selector(self.enableNearbyPressed), for: .touchUpInside)

        self.statusLabel.text = strings.notVisible
        self.statusLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        self.statusLabel.numberOfLines = 0

        self.topicControl.selectedSegmentIndex = 0
        self.topicControl.addTarget(self, action: #selector(self.topicChanged), for: .valueChanged)

        self.partnersTitleLabel.text = strings.partnersTitle
        self.partnersTitleLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .bold)
        self.partnersTitleLabel.numberOfLines = 0

        self.partnersStack.axis = .vertical
        self.partnersStack.spacing = 12.0
        self.showPartnerMessage(strings.visibilityPrompt)

        self.safetyCard.layer.cornerRadius = 14.0
        self.safetyCard.layer.borderWidth = UIScreenPixel

        self.safetyTitleLabel.text = strings.safetyTitle
        self.safetyTitleLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .bold)
        self.safetyTitleLabel.numberOfLines = 0

        self.safetyDetailLabel.text = strings.safetyDetail
        self.safetyDetailLabel.font = UIFont.systemFont(ofSize: 14.0)
        self.safetyDetailLabel.numberOfLines = 0

        let safetyRows = UIStackView()
        safetyRows.axis = .vertical
        safetyRows.spacing = 0.0
        let safetyItems: [(String, String, String, UIColor)] = [
            ("person.2.fill", strings.adultMutualTitle, strings.adultMutualDetail, KislapBrandPalette.connection),
            ("timer", strings.oneHourTitle, strings.oneHourDetail, KislapBrandPalette.success),
            ("hand.raised.fill", strings.blockReportTitle, strings.blockReportDetail, KislapBrandPalette.caution),
            ("heart.fill", strings.datingSeparateTitle, strings.datingSeparateDetail, KislapBrandPalette.dating),
        ]
        for (index, item) in safetyItems.enumerated() {
            safetyRows.addArrangedSubview(self.makeSafetyRow(iconName: item.0, title: item.1, detail: item.2, tintColor: item.3, showSeparator: index < safetyItems.count - 1))
        }

        let safetyStack = UIStackView(arrangedSubviews: [self.safetyTitleLabel, self.safetyDetailLabel, safetyRows])
        safetyStack.axis = .vertical
        safetyStack.spacing = 7.0
        safetyStack.setCustomSpacing(14.0, after: self.safetyDetailLabel)
        safetyStack.translatesAutoresizingMaskIntoConstraints = false
        self.safetyCard.addSubview(safetyStack)
        NSLayoutConstraint.activate([
            safetyStack.topAnchor.constraint(equalTo: self.safetyCard.topAnchor, constant: 18.0),
            safetyStack.leadingAnchor.constraint(equalTo: self.safetyCard.leadingAnchor, constant: 16.0),
            safetyStack.trailingAnchor.constraint(equalTo: self.safetyCard.trailingAnchor, constant: -16.0),
            safetyStack.bottomAnchor.constraint(equalTo: self.safetyCard.bottomAnchor, constant: -8.0),
        ])

        let permissionStack = UIStackView(arrangedSubviews: [self.permissionTitleLabel, self.permissionDetailLabel, self.accountButton, self.enableButton, self.statusLabel])
        permissionStack.axis = .vertical
        permissionStack.spacing = 12.0
        permissionStack.translatesAutoresizingMaskIntoConstraints = false
        self.permissionCard.addSubview(permissionStack)
        NSLayoutConstraint.activate([
            permissionStack.topAnchor.constraint(equalTo: self.permissionCard.topAnchor, constant: 18.0),
            permissionStack.leadingAnchor.constraint(equalTo: self.permissionCard.leadingAnchor, constant: 18.0),
            permissionStack.trailingAnchor.constraint(equalTo: self.permissionCard.trailingAnchor, constant: -18.0),
            permissionStack.bottomAnchor.constraint(equalTo: self.permissionCard.bottomAnchor, constant: -18.0)
        ])

        self.contentStack.addArrangedSubview(self.eyebrowLabel)
        self.contentStack.addArrangedSubview(self.headlineLabel)
        self.contentStack.addArrangedSubview(self.detailLabel)
        self.contentStack.setCustomSpacing(22.0, after: self.detailLabel)
        self.contentStack.addArrangedSubview(self.journeyTitleLabel)
        self.contentStack.addArrangedSubview(self.journeyStack)
        self.contentStack.setCustomSpacing(24.0, after: self.journeyStack)
        self.contentStack.addArrangedSubview(self.permissionCard)
        self.contentStack.setCustomSpacing(24.0, after: self.permissionCard)
        self.contentStack.addArrangedSubview(self.topicControl)
        self.contentStack.addArrangedSubview(self.partnersTitleLabel)
        self.contentStack.addArrangedSubview(self.partnersStack)
        self.contentStack.setCustomSpacing(24.0, after: self.partnersStack)
        self.contentStack.addArrangedSubview(self.safetyCard)

        self.scrollView.alwaysBounceVertical = true
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
            self.contentStack.leadingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.leadingAnchor, constant: 20.0),
            self.contentStack.trailingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.trailingAnchor, constant: -20.0),
            self.contentStack.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor, constant: -32.0)
        ])

        self.updateLocalizedStrings(resetState: false)
        self.updateTheme()
        self.updateAuthorizationState(self.currentAuthorizationStatus())
        self.refreshLearningSessionState()
    }

    private func updateLocalizedStrings(resetState: Bool) {
        let strings = self.strings
        self.title = strings.nearbyTitle
        self.tabBarItem.title = strings.nearbyTitle
        self.eyebrowLabel.text = strings.learningEyebrow
        self.headlineLabel.text = strings.headline
        self.detailLabel.text = strings.detail
        self.journeyTitleLabel.text = strings.journeyTitle
        self.updateJourneyButtons()
        self.permissionDetailLabel.text = strings.locationPrivacyDetail
        self.accountButton.setTitle(self.apiClient.hasSession ? strings.learningProfileConnected : strings.connectLearningProfile, for: .normal)
        self.topicControl.setTitle(strings.topicEnglish, forSegmentAt: 0)
        self.topicControl.setTitle(strings.topicProgramming, forSegmentAt: 1)
        self.topicControl.setTitle(strings.topicSinging, forSegmentAt: 2)
        self.partnersTitleLabel.text = strings.partnersTitle
        self.safetyTitleLabel.text = strings.safetyTitle
        self.safetyDetailLabel.text = strings.safetyDetail

        let safetyTitles = [strings.adultMutualTitle, strings.oneHourTitle, strings.blockReportTitle, strings.datingSeparateTitle]
        let safetyDetails = [strings.adultMutualDetail, strings.oneHourDetail, strings.blockReportDetail, strings.datingSeparateDetail]
        for (index, label) in self.safetyPrimaryLabels.enumerated() where safetyTitles.indices.contains(index) {
            label.text = safetyTitles[index]
        }
        for (index, label) in self.safetySecondaryLabels.enumerated() where safetyDetails.indices.contains(index) {
            label.text = safetyDetails[index]
        }

        if resetState {
            if self.isVisible {
                self.permissionTitleLabel.text = strings.nearbyVisibilityOn
                self.enableButton.setTitle(strings.stopBeingVisible, for: .normal)
            } else {
                self.permissionTitleLabel.text = strings.locationOff
                self.updateAuthorizationState(self.currentAuthorizationStatus())
                if self.currentPartners.isEmpty {
                    self.showPartnerMessage(strings.visibilityPrompt)
                }
            }
            self.refreshLearningSessionState()
        }

        if !self.currentPartners.isEmpty {
            self.renderPartners(self.currentPartners)
        }
    }

    private func updateTheme() {
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData, style: .glass), transition: .immediate)

        let theme = self.presentationData.theme
        self.displayNode.backgroundColor = theme.list.blocksBackgroundColor
        self.eyebrowLabel.textColor = theme.list.itemAccentColor
        self.headlineLabel.textColor = theme.list.itemPrimaryTextColor
        self.detailLabel.textColor = theme.list.itemSecondaryTextColor
        self.journeyTitleLabel.textColor = theme.list.itemPrimaryTextColor
        self.updateJourneyButtons()
        self.permissionCard.backgroundColor = theme.list.itemBlocksBackgroundColor
        self.permissionCard.layer.borderColor = theme.list.itemBlocksSeparatorColor.cgColor
        self.permissionTitleLabel.textColor = theme.list.itemPrimaryTextColor
        self.permissionDetailLabel.textColor = theme.list.itemSecondaryTextColor
        self.accountButton.tintColor = theme.list.itemAccentColor
        self.enableButton.backgroundColor = theme.list.itemAccentColor
        self.statusLabel.textColor = theme.list.itemSecondaryTextColor
        self.partnersTitleLabel.textColor = theme.list.itemPrimaryTextColor
        self.topicControl.backgroundColor = theme.list.controlSecondaryColor
        self.topicControl.selectedSegmentTintColor = theme.list.itemBlocksBackgroundColor
        self.topicControl.setTitleTextAttributes([.foregroundColor: theme.list.itemPrimaryTextColor], for: .normal)
        self.topicControl.setTitleTextAttributes([.foregroundColor: theme.list.itemAccentColor], for: .selected)
        self.safetyCard.backgroundColor = theme.list.itemBlocksBackgroundColor
        self.safetyCard.layer.borderColor = theme.list.itemBlocksSeparatorColor.cgColor
        self.safetyTitleLabel.textColor = theme.list.itemPrimaryTextColor
        self.safetyDetailLabel.textColor = theme.list.itemSecondaryTextColor
        for label in self.safetyPrimaryLabels {
            label.textColor = theme.list.itemPrimaryTextColor
        }
        for label in self.safetySecondaryLabels {
            label.textColor = theme.list.itemSecondaryTextColor
        }
        for separator in self.safetySeparators {
            separator.backgroundColor = theme.list.itemBlocksSeparatorColor
        }
        if !self.currentPartners.isEmpty {
            self.renderPartners(self.currentPartners)
        }
    }

    private func updateJourneyButtons() {
        let strings = self.strings
        self.configureJourneyButton(
            self.learnJourneyButton,
            title: strings.learnActionTitle,
            detail: strings.learnActionDetail,
            iconName: "sparkles",
            tintColor: KislapBrandPalette.brandPurple
        )
        self.configureJourneyButton(
            self.teachJourneyButton,
            title: strings.teachActionTitle,
            detail: strings.teachActionDetail,
            iconName: "person.crop.circle.badge.checkmark",
            tintColor: KislapBrandPalette.success
        )
        self.configureJourneyButton(
            self.connectJourneyButton,
            title: strings.connectActionTitle,
            detail: strings.connectActionDetail,
            iconName: "bubble.left.and.bubble.right.fill",
            tintColor: KislapBrandPalette.connection
        )
    }

    private func configureJourneyButton(_ button: UIButton, title: String, detail: String, iconName: String, tintColor: UIColor) {
        let theme = self.presentationData.theme
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 2.0

        let titleText = NSMutableAttributedString(
            string: title + "\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 17.0, weight: .bold),
                .foregroundColor: theme.list.itemPrimaryTextColor,
                .paragraphStyle: paragraph
            ]
        )
        titleText.append(NSAttributedString(
            string: detail,
            attributes: [
                .font: UIFont.systemFont(ofSize: 13.0, weight: .regular),
                .foregroundColor: theme.list.itemSecondaryTextColor,
                .paragraphStyle: paragraph
            ]
        ))

        button.setAttributedTitle(titleText, for: .normal)
        button.setImage(UIImage(systemName: iconName), for: .normal)
        button.tintColor = tintColor
        button.backgroundColor = tintColor.withAlphaComponent(0.12)
        button.accessibilityLabel = title + ". " + detail
    }

    @objc private func learnJourneyPressed() {
        if !self.apiClient.hasSession {
            self.promptForEmail()
            return
        }
        let targetRect = self.topicControl.convert(self.topicControl.bounds, to: self.scrollView).insetBy(dx: 0.0, dy: -24.0)
        self.scrollView.scrollRectToVisible(targetRect, animated: true)
    }

    @objc private func teachJourneyPressed() {
        self.accountPressed()
    }

    @objc private func connectJourneyPressed() {
        self.connectionsPressed()
    }

    private func makeSafetyRow(iconName: String, title: String, detail: String, tintColor: UIColor, showSeparator: Bool) -> UIView {
        let row = UIView()

        let iconContainer = UIView()
        iconContainer.backgroundColor = tintColor.withAlphaComponent(0.14)
        iconContainer.layer.cornerRadius = 10.0
        iconContainer.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = tintColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
        titleLabel.numberOfLines = 0
        self.safetyPrimaryLabels.append(titleLabel)

        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.font = UIFont.systemFont(ofSize: 13.0)
        detailLabel.numberOfLines = 0
        self.safetySecondaryLabels.append(detailLabel)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        textStack.axis = .vertical
        textStack.spacing = 2.0

        let rowStack = UIStackView(arrangedSubviews: [iconContainer, textStack])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 12.0
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(rowStack)

        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 38.0),
            iconContainer.heightAnchor.constraint(equalToConstant: 38.0),
            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 19.0),
            iconView.heightAnchor.constraint(equalToConstant: 19.0),
            rowStack.topAnchor.constraint(equalTo: row.topAnchor, constant: 10.0),
            rowStack.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            rowStack.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -10.0),
        ])

        if showSeparator {
            let separator = UIView()
            separator.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(separator)
            self.safetySeparators.append(separator)
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: textStack.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                separator.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                separator.heightAnchor.constraint(equalToConstant: UIScreenPixel),
            ])
        }

        return row
    }

    @objc private func accountPressed() {
        if self.apiClient.hasSession {
            (self.navigationController as? NavigationController)?.pushViewController(KislapProfileController(context: self.context))
        } else {
            self.promptForEmail()
        }
    }

    @objc private func connectionsPressed() {
        if self.apiClient.hasSession {
            (self.navigationController as? NavigationController)?.pushViewController(KislapConnectionsController(context: self.context))
        } else {
            self.promptForEmail()
        }
    }

    private func promptForEmail() {
        let strings = self.strings
        let alert = UIAlertController(title: strings.connectLearningProfile, message: strings.connectProfileExplanation, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = strings.emailAddress
            field.keyboardType = .emailAddress
            field.textContentType = .emailAddress
            field.autocapitalizationType = .none
        }
        alert.addAction(UIAlertAction(title: self.presentationData.strings.Common_Cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: strings.sendCode, style: .default, handler: { [weak self, weak alert] _ in
            guard let self, let email = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else { return }
            self.statusLabel.text = self.strings.sendingCode
            self.apiClient.requestLoginCode(email: email) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self else { return }
                    switch result {
                    case let .success(devCode):
                        self.promptForCode(email: email, devCode: devCode)
                    case let .failure(error):
                        self.showError(title: self.strings.couldNotSendCode, error: error)
                    }
                }
            }
        }))
        self.present(alert, animated: true)
    }

    private func promptForCode(email: String, devCode: String?) {
        let strings = self.strings
        let message: String
        if let devCode {
            message = strings.developmentCode(devCode)
        } else {
            message = strings.codeSent(to: email)
        }
        let alert = UIAlertController(title: strings.verifyEmail, message: message, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = strings.sixDigitCode
            field.keyboardType = .numberPad
            field.textContentType = .oneTimeCode
        }
        alert.addAction(UIAlertAction(title: self.presentationData.strings.Common_Cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: strings.verify, style: .default, handler: { [weak self, weak alert] _ in
            guard let self, let code = alert?.textFields?.first?.text, code.count == 6 else { return }
            self.verify(email: email, code: code, profile: nil)
        }))
        self.present(alert, animated: true)
    }

    private func verify(email: String, code: String, profile: KislapRegistrationProfile?) {
        self.statusLabel.text = self.strings.verifyingProfile
        self.apiClient.verifyLoginCode(email: email, code: code, profile: profile) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                let strings = self.strings
                switch result {
                case .success:
                    self.accountButton.setTitle(strings.learningProfileConnected, for: .normal)
                    self.permissionTitleLabel.text = strings.readyForNearby
                    self.statusLabel.text = strings.verifiedLocationOff
                case let .failure(KislapAPIError.server(_, codeValue)) where codeValue == "profile_required":
                    self.promptForAdultProfile(email: email, code: code)
                case let .failure(error):
                    self.showError(title: strings.verificationFailed, error: error)
                }
            }
        }
    }

    private func promptForAdultProfile(email: String, code: String) {
        let strings = self.strings
        let alert = UIAlertController(title: strings.createProfile, message: strings.createProfileMessage, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = strings.displayName
            field.textContentType = .name
        }
        alert.addTextField { field in
            field.placeholder = strings.ageRange
            field.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: self.presentationData.strings.Common_Cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: strings.continueAction, style: .default, handler: { [weak self, weak alert] _ in
            guard let self,
                  let name = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
                  let ageText = alert?.textFields?.last?.text, let age = Int(ageText), (18 ... 99).contains(age) else {
                self?.statusLabel.text = self?.strings.invalidProfile
                return
            }
            self.promptForGender(email: email, code: code, displayName: name, age: age)
        }))
        self.present(alert, animated: true)
    }

    private func promptForGender(email: String, code: String, displayName: String, age: Int) {
        let strings = self.strings
        let alert = UIAlertController(title: strings.profileGender, message: strings.genderMessage, preferredStyle: .alert)
        for option in [(strings.woman, "FEMALE"), (strings.man, "MALE"), (strings.other, "OTHER")] {
            alert.addAction(UIAlertAction(title: option.0, style: .default, handler: { [weak self] _ in
                self?.confirmPolicies(email: email, code: code, displayName: displayName, age: age, gender: option.1)
            }))
        }
        alert.addAction(UIAlertAction(title: self.presentationData.strings.Common_Cancel, style: .cancel))
        self.present(alert, animated: true)
    }

    private func confirmPolicies(email: String, code: String, displayName: String, age: Int, gender: String) {
        let strings = self.strings
        let alert = UIAlertController(
            title: strings.safetyAgreement,
            message: strings.safetyAgreementMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: self.presentationData.strings.Common_Cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: strings.agreeCreateProfile, style: .default, handler: { [weak self] _ in
            let profile = KislapRegistrationProfile(displayName: displayName, age: age, gender: gender, interests: ["english"])
            self?.verify(email: email, code: code, profile: profile)
        }))
        self.present(alert, animated: true)
    }

    @objc private func enableNearbyPressed() {
        guard self.apiClient.hasSession else {
            self.statusLabel.text = self.strings.connectBeforeSharing
            self.promptForEmail()
            return
        }

        if self.isVisible {
            self.stopVisibility()
            return
        }

        guard CLLocationManager.locationServicesEnabled() else {
            self.statusLabel.text = self.strings.locationServicesDisabled
            return
        }

        switch self.currentAuthorizationStatus() {
        case .notDetermined:
            self.awaitingExplicitLocationAuthorization = true
            self.statusLabel.text = self.strings.waitingPermission
            self.locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            self.beginCoarseLocationLookup()
        case .denied, .restricted:
            self.awaitingExplicitLocationAuthorization = false
            self.statusLabel.text = self.strings.locationAccessOffStatus
        @unknown default:
            self.statusLabel.text = self.strings.locationUnavailable
        }
    }

    private func beginCoarseLocationLookup() {
        self.permissionTitleLabel.text = self.strings.findingArea
        self.statusLabel.text = self.strings.coarseLocationRequest
        self.locationManager.requestLocation()
    }

    private func stopVisibility() {
        self.enableButton.isEnabled = false
        self.statusLabel.text = self.strings.turningVisibilityOff
        self.apiClient.disableLocation { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                let strings = self.strings
                self.enableButton.isEnabled = true
                switch result {
                case .success:
                    self.isVisible = false
                    self.permissionTitleLabel.text = strings.locationOff
                    self.enableButton.setTitle(strings.useApproximateArea, for: .normal)
                    self.statusLabel.text = strings.notVisible
                    self.showPartnerMessage(strings.visibilityTurnOnAgain)
                case let .failure(error):
                    self.showError(title: strings.couldNotDisableVisibility, error: error)
                }
            }
        }
    }

    private func updateAuthorizationState(_ status: CLAuthorizationStatus) {
        let strings = self.strings
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            self.enableButton.setTitle(strings.useApproximateArea, for: .normal)
            self.statusLabel.text = strings.permissionGranted
        case .denied, .restricted:
            self.enableButton.setTitle(strings.locationAccessOffButton, for: .normal)
            self.statusLabel.text = strings.invisibleCanEnableLater
        case .notDetermined:
            self.enableButton.setTitle(strings.enableNearbyLearning, for: .normal)
            self.statusLabel.text = strings.notVisible
        @unknown default:
            self.statusLabel.text = strings.locationUnavailable
        }
    }

    private func currentAuthorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return self.locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }

    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        self.updateAuthorizationState(status)
        if self.awaitingExplicitLocationAuthorization && (status == .authorizedAlways || status == .authorizedWhenInUse) {
            self.awaitingExplicitLocationAuthorization = false
            self.beginCoarseLocationLookup()
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard #unavailable(iOS 14.0) else {
            return
        }
        self.updateAuthorizationState(status)
        if self.awaitingExplicitLocationAuthorization && (status == .authorizedAlways || status == .authorizedWhenInUse) {
            self.awaitingExplicitLocationAuthorization = false
            self.beginCoarseLocationLookup()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        self.enableButton.isEnabled = false
        self.permissionTitleLabel.text = self.strings.protectingArea
        self.statusLabel.text = self.strings.privacyFilter
        self.apiClient.updateLocation(location) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                let strings = self.strings
                self.enableButton.isEnabled = true
                switch result {
                case let .success(expiresAt):
                    self.isVisible = true
                    self.permissionTitleLabel.text = strings.visibleOneHour
                    self.statusLabel.text = strings.visibilityExpires(self.expiryDescription(expiresAt))
                    self.enableButton.setTitle(strings.stopBeingVisible, for: .normal)
                    self.loadPartners()
                case let .failure(error):
                    self.permissionTitleLabel.text = strings.remainInvisible
                    self.showError(title: strings.couldNotEnableNearby, error: error)
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.permissionTitleLabel.text = self.strings.couldNotFindArea
        self.statusLabel.text = self.strings.tryAgainRemainInvisible
    }

    @objc private func topicChanged() {
        if self.isVisible {
            self.loadPartners()
        }
    }

    private func refreshLearningSessionState() {
        guard self.apiClient.hasSession else { return }
        self.apiClient.locationStatus { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                let strings = self.strings
                switch result {
                case let .success(status):
                    self.accountButton.setTitle(strings.learningProfileConnected, for: .normal)
                    self.isVisible = status.visible
                    if status.visible {
                        self.permissionTitleLabel.text = strings.nearbyVisibilityOn
                        self.enableButton.setTitle(strings.stopBeingVisible, for: .normal)
                        self.statusLabel.text = strings.visibilityExpires(self.expiryDescription(status.expiresAt))
                        self.loadPartners()
                    }
                case .failure:
                    self.accountButton.setTitle(strings.connectLearningProfile, for: .normal)
                    self.statusLabel.text = strings.connectProfileToUseNearby
                }
            }
        }
    }

    private func loadPartners() {
        self.showPartnerMessage(self.strings.findingPartners)
        self.apiClient.learningPartners(skill: self.selectedSkill) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case let .success(partners):
                    self.currentPartners = partners
                    self.renderPartners(partners)
                case let .failure(error):
                    self.showPartnerMessage(self.strings.couldNotLoadPartners(self.localizedErrorDescription(error)))
                }
            }
        }
    }

    private func renderPartners(_ partners: [KislapLearningPartner]) {
        self.clearPartnerViews()
        if partners.isEmpty {
            self.showPartnerMessage(self.strings.noMatchingPartners)
            return
        }

        for partner in partners {
            let theme = self.presentationData.theme
            let card = UIView()
            card.layer.cornerRadius = 14.0
            card.backgroundColor = theme.list.itemBlocksBackgroundColor
            card.layer.borderWidth = UIScreenPixel
            card.layer.borderColor = theme.list.itemBlocksSeparatorColor.cgColor

            let avatarContainer = UIView()
            avatarContainer.backgroundColor = theme.list.itemAccentColor.withAlphaComponent(0.14)
            avatarContainer.layer.cornerRadius = 29.0
            avatarContainer.clipsToBounds = true
            avatarContainer.translatesAutoresizingMaskIntoConstraints = false

            let initials = UILabel()
            initials.text = self.initials(for: partner.displayName)
            initials.font = UIFont.systemFont(ofSize: 20.0, weight: .bold)
            initials.textColor = theme.list.itemAccentColor
            initials.textAlignment = .center
            initials.translatesAutoresizingMaskIntoConstraints = false
            avatarContainer.addSubview(initials)

            let avatarImage = UIImageView()
            avatarImage.contentMode = .scaleAspectFill
            avatarImage.clipsToBounds = true
            avatarImage.translatesAutoresizingMaskIntoConstraints = false
            avatarContainer.addSubview(avatarImage)

            let activityDot = UIView()
            activityDot.backgroundColor = partner.activityStatus == "active_now" ? KislapBrandPalette.success : KislapBrandPalette.success.withAlphaComponent(0.6)
            activityDot.layer.cornerRadius = 6.0
            activityDot.layer.borderWidth = 2.0
            activityDot.layer.borderColor = theme.list.itemBlocksBackgroundColor.cgColor
            activityDot.translatesAutoresizingMaskIntoConstraints = false
            avatarContainer.addSubview(activityDot)

            NSLayoutConstraint.activate([
                avatarContainer.widthAnchor.constraint(equalToConstant: 58.0),
                avatarContainer.heightAnchor.constraint(equalToConstant: 58.0),
                initials.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
                initials.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
                initials.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor),
                avatarImage.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
                avatarImage.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
                avatarImage.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
                avatarImage.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
                activityDot.widthAnchor.constraint(equalToConstant: 12.0),
                activityDot.heightAnchor.constraint(equalToConstant: 12.0),
                activityDot.centerXAnchor.constraint(equalTo: avatarContainer.trailingAnchor, constant: -4.0),
                activityDot.centerYAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: -4.0),
            ])

            let name = UILabel()
            let verifiedMark = partner.verificationStatus == "UNVERIFIED" ? "" : "  ✓"
            name.text = "\(partner.displayName), \(partner.age)\(verifiedMark)"
            name.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
            name.textColor = theme.list.itemPrimaryTextColor
            name.numberOfLines = 1

            let activity = UILabel()
            activity.text = partner.activityStatus == "active_now" ? self.strings.activeNow : self.strings.activeRecently
            activity.font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
            activity.textColor = partner.activityStatus == "active_now" ? KislapBrandPalette.success : theme.list.itemSecondaryTextColor

            let location = UILabel()
            if partner.isDemo == true {
                location.text = "✦  \(self.strings.reviewDemoProfile)"
            } else {
                location.text = "⌖  \(self.displayDistance(partner.distanceLabel))\(partner.city.map { " · \(self.displayCity($0))" } ?? "")"
            }
            location.font = UIFont.systemFont(ofSize: 13.0)
            location.textColor = theme.list.itemSecondaryTextColor
            location.numberOfLines = 1

            let identityStack = UIStackView(arrangedSubviews: [name, activity, location])
            identityStack.axis = .vertical
            identityStack.spacing = 2.0

            let profile = UIButton(type: .system)
            profile.setImage(UIImage(systemName: "chevron.right"), for: .normal)
            profile.tintColor = theme.list.itemSecondaryTextColor
            profile.accessibilityLabel = self.strings.viewProfile
            profile.tag = self.currentPartners.firstIndex(where: { $0.userId == partner.userId }) ?? 0
            profile.addTarget(self, action: #selector(self.profilePressed(_:)), for: .touchUpInside)
            profile.widthAnchor.constraint(equalToConstant: 34.0).isActive = true
            profile.heightAnchor.constraint(equalToConstant: 44.0).isActive = true

            let headerStack = UIStackView(arrangedSubviews: [avatarContainer, identityStack, profile])
            headerStack.axis = .horizontal
            headerStack.alignment = .center
            headerStack.spacing = 12.0
            identityStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            let badges = UIStackView()
            badges.axis = .horizontal
            badges.alignment = .leading
            badges.spacing = 7.0
            let skillNames = partner.skills.isEmpty
                ? partner.interests.prefix(2).map { self.displaySkillName($0, slug: nil) }
                : partner.skills.prefix(2).map { self.displaySkillName($0.name, slug: $0.slug) }
            for skillName in skillNames {
                badges.addArrangedSubview(self.makeSkillBadge(skillName))
            }
            let badgeSpacer = UIView()
            badgeSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            badges.addArrangedSubview(badgeSpacer)

            let bio = UILabel()
            bio.text = partner.bio
            bio.font = UIFont.systemFont(ofSize: 14.0)
            bio.textColor = theme.list.itemSecondaryTextColor
            bio.numberOfLines = 2
            bio.isHidden = (partner.bio?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

            let connect = UIButton(type: .system)
            connect.setTitle(self.strings.requestStudySession, for: .normal)
            connect.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
            connect.setTitleColor(.white, for: .normal)
            connect.backgroundColor = theme.list.itemAccentColor
            connect.layer.cornerRadius = 11.0
            connect.tag = self.currentPartners.firstIndex(where: { $0.userId == partner.userId }) ?? 0
            connect.addTarget(self, action: #selector(self.connectPressed(_:)), for: .touchUpInside)

            let safety = UIButton(type: .system)
            safety.setTitle(self.strings.safety, for: .normal)
            safety.setImage(UIImage(systemName: "shield.fill"), for: .normal)
            safety.tintColor = theme.list.itemAccentColor
            safety.titleLabel?.font = UIFont.systemFont(ofSize: 14.0, weight: .semibold)
            safety.backgroundColor = theme.list.controlSecondaryColor
            safety.layer.cornerRadius = 11.0
            safety.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: -4.0, bottom: 0.0, right: 4.0)
            safety.tag = connect.tag
            safety.addTarget(self, action: #selector(self.safetyPressed(_:)), for: .touchUpInside)

            let actions = UIStackView(arrangedSubviews: [connect, safety])
            actions.axis = .horizontal
            actions.spacing = 9.0

            let stack = UIStackView(arrangedSubviews: [headerStack, badges, bio, actions])
            stack.axis = .vertical
            stack.spacing = 12.0
            stack.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 15.0),
                stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16.0),
                stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16.0),
                stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -15.0),
                connect.heightAnchor.constraint(equalToConstant: 44.0),
                safety.widthAnchor.constraint(equalToConstant: 96.0),
            ])
            self.partnersStack.addArrangedSubview(card)
            self.loadAvatar(for: partner, into: avatarImage)
        }
    }

    private func initials(for displayName: String) -> String {
        let parts = displayName
            .split(whereSeparator: { $0.isWhitespace })
            .prefix(2)
        let value = parts.compactMap { $0.first }.map(String.init).joined()
        return value.isEmpty ? "K" : value.uppercased()
    }

    private func makeSkillBadge(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = "  \(title)  "
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .semibold)
        label.textColor = self.presentationData.theme.list.itemAccentColor
        label.backgroundColor = self.presentationData.theme.list.itemAccentColor.withAlphaComponent(0.12)
        label.layer.cornerRadius = 10.0
        label.clipsToBounds = true
        label.textAlignment = .center
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.heightAnchor.constraint(equalToConstant: 24.0).isActive = true
        return label
    }

    private func loadAvatar(for partner: KislapLearningPartner, into imageView: UIImageView) {
        let preferredPhoto = partner.photos.first(where: { $0.isMain == true }) ?? partner.photos.first
        guard let path = preferredPhoto?.thumbUrl ?? preferredPhoto?.url else {
            imageView.isHidden = true
            return
        }
        self.apiClient.loadProfileImage(path: path) { image in
            DispatchQueue.main.async { [weak imageView] in
                imageView?.image = image
                imageView?.isHidden = image == nil
            }
        }
    }

    @objc private func connectPressed(_ sender: UIButton) {
        guard self.currentPartners.indices.contains(sender.tag) else { return }
        let partner = self.currentPartners[sender.tag]
        sender.isEnabled = false
        self.apiClient.requestStudyConnection(userId: partner.userId, skill: self.selectedSkill) { [weak self, weak sender] result in
            DispatchQueue.main.async {
                sender?.isEnabled = true
                switch result {
                case .success:
                    sender?.setTitle(self?.strings.requestSent, for: .normal)
                case let .failure(error):
                    self?.showError(title: self?.strings.couldNotSendRequest ?? "", error: error)
                }
            }
        }
    }

    @objc private func profilePressed(_ sender: UIButton) {
        guard self.currentPartners.indices.contains(sender.tag) else { return }
        let partner = self.currentPartners[sender.tag]
        let controller = KislapPartnerProfileController(
            partner: partner,
            selectedSkill: self.selectedSkill,
            presentationData: self.presentationData
        )
        controller.onSafety = { [weak self] in
            self?.presentSafetyActions(for: partner)
        }
        controller.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *), let sheet = controller.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.selectedDetentIdentifier = .large
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 22.0
        }
        self.present(controller, animated: true)
    }

    @objc private func safetyPressed(_ sender: UIButton) {
        guard self.currentPartners.indices.contains(sender.tag) else { return }
        let partner = self.currentPartners[sender.tag]
        self.presentSafetyActions(for: partner)
    }

    private func presentSafetyActions(for partner: KislapLearningPartner) {
        let alert = UIAlertController(title: partner.displayName, message: self.strings.safetyActionsMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.presentationData.strings.Common_Cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: self.strings.report, style: .default, handler: { [weak self] _ in
            self?.apiClient.report(userId: partner.userId) { _ in }
        }))
        alert.addAction(UIAlertAction(title: self.strings.block, style: .destructive, handler: { [weak self] _ in
            self?.apiClient.block(userId: partner.userId) { [weak self] result in
                if case .success = result {
                    DispatchQueue.main.async {
                        self?.currentPartners.removeAll(where: { $0.userId == partner.userId })
                        self?.renderPartners(self?.currentPartners ?? [])
                    }
                }
            }
        }))
        self.present(alert, animated: true)
    }

    private func clearPartnerViews() {
        for view in self.partnersStack.arrangedSubviews {
            self.partnersStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    private func showPartnerMessage(_ text: String) {
        self.clearPartnerViews()
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 15.0)
        label.textColor = self.presentationData.theme.list.itemSecondaryTextColor
        label.numberOfLines = 0
        self.partnersStack.addArrangedSubview(label)
    }

    private func displayDistance(_ label: String) -> String {
        switch label {
        case "nearby": return self.strings.distanceNearby
        case "far": return self.strings.distanceFar
        default: return self.strings.distanceAbout(label)
        }
    }

    private func displaySkillName(_ name: String, slug: String?) -> String {
        guard self.strings.isChinese else {
            return name
        }
        let value = (slug ?? name).lowercased()
        if value.contains("english") {
            return value.contains("conversation") ? "英语口语" : "英语"
        } else if value.contains("program") || value.contains("coding") {
            return "编程"
        } else if value.contains("sing") {
            return "唱歌"
        } else if value.contains("music") {
            return "音乐"
        }
        return name
    }

    private func displayCity(_ city: String) -> String {
        guard self.strings.isChinese else {
            return city
        }
        switch city.lowercased() {
        case "manila": return "马尼拉"
        case "quezon city": return "奎松市"
        case "makati": return "马卡蒂"
        case "pasay": return "帕赛"
        case "taguig": return "达义市"
        default: return city
        }
    }

    private func expiryDescription(_ value: String?) -> String {
        guard let value else { return self.strings.expiresAutomatically }
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = fractionalFormatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
        guard let date else { return self.strings.expiresInOneHour }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = self.strings.isChinese ? Locale(identifier: "zh_Hans") : Locale(identifier: "en_PH")
        return self.strings.expiresAt(formatter.string(from: date))
    }

    private func showError(title: String, error: Error) {
        let message = self.localizedErrorDescription(error)
        self.statusLabel.text = message
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.presentationData.strings.Common_OK, style: .default))
        self.present(alert, animated: true)
    }

    private func localizedErrorDescription(_ error: Error) -> String {
        guard let error = error as? KislapAPIError else {
            return error.localizedDescription
        }
        switch error {
        case .unavailable:
            return self.strings.serviceUnavailable
        case .invalidResponse:
            return self.strings.invalidServiceResponse
        case .server:
            return self.strings.isChinese ? self.strings.unknownServiceError : error.localizedDescription
        }
    }
}
