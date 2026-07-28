import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import AccountContext

final class KislapDatingSettingsController: ViewController {
    private let context: AccountContext
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    private var appliedLanguageCode: String
    private let apiClient = KislapAPIClient.shared

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let heroCard = UIView()
    private let heroTitleLabel = UILabel()
    private let heroDetailLabel = UILabel()
    private let modeTitleLabel = UILabel()
    private let modeCard = UIView()
    private let modeLabel = UILabel()
    private let modeSwitch = UISwitch()
    private let statusLabel = UILabel()
    private let safetyTitleLabel = UILabel()
    private let safetyCard = UIView()
    private var rowTitleLabels: [UILabel] = []
    private var rowDetailLabels: [UILabel] = []
    private var separators: [UIView] = []
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var serverValue = false
    private var isUpdating = false

    private var strings: KislapDatingSettingsStrings {
        return KislapDatingSettingsStrings(languageCode: self.presentationData.strings.baseLanguageCode)
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
        self.configureHero()
        self.configureMode()
        self.configureSafety()

        self.contentStack.addArrangedSubview(self.heroCard)
        self.contentStack.setCustomSpacing(22.0, after: self.heroCard)
        self.contentStack.addArrangedSubview(self.modeTitleLabel)
        self.contentStack.addArrangedSubview(self.modeCard)
        self.contentStack.setCustomSpacing(22.0, after: self.modeCard)
        self.contentStack.addArrangedSubview(self.safetyTitleLabel)
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
            self.contentStack.leadingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.leadingAnchor, constant: 16.0),
            self.contentStack.trailingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.trailingAnchor, constant: -16.0),
            self.contentStack.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor, constant: -32.0),
        ])
        self.updateLocalizedStrings()
        self.updateTheme()
        self.loadSetting()
    }

    private func configureHero() {
        self.styleCard(self.heroCard)
        let icon = UIImageView(image: UIImage(systemName: "heart.fill"))
        icon.tintColor = KislapBrandPalette.dating
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        let iconBackground = UIView()
        iconBackground.backgroundColor = KislapBrandPalette.dating.withAlphaComponent(0.14)
        iconBackground.layer.cornerRadius = 13.0
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(icon)
        self.heroTitleLabel.font = UIFont.systemFont(ofSize: 21.0, weight: .bold)
        self.heroDetailLabel.font = UIFont.systemFont(ofSize: 14.0)
        self.heroDetailLabel.numberOfLines = 0
        let text = UIStackView(arrangedSubviews: [self.heroTitleLabel, self.heroDetailLabel])
        text.axis = .vertical
        text.spacing = 4.0
        let row = UIStackView(arrangedSubviews: [iconBackground, text])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 13.0
        row.translatesAutoresizingMaskIntoConstraints = false
        self.heroCard.addSubview(row)
        NSLayoutConstraint.activate([
            iconBackground.widthAnchor.constraint(equalToConstant: 52.0),
            iconBackground.heightAnchor.constraint(equalToConstant: 52.0),
            icon.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 25.0),
            icon.heightAnchor.constraint(equalToConstant: 25.0),
            row.topAnchor.constraint(equalTo: self.heroCard.topAnchor, constant: 16.0),
            row.leadingAnchor.constraint(equalTo: self.heroCard.leadingAnchor, constant: 16.0),
            row.trailingAnchor.constraint(equalTo: self.heroCard.trailingAnchor, constant: -16.0),
            row.bottomAnchor.constraint(equalTo: self.heroCard.bottomAnchor, constant: -16.0),
        ])
    }

    private func configureMode() {
        self.modeTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        self.styleCard(self.modeCard)
        self.modeLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        self.statusLabel.font = UIFont.systemFont(ofSize: 13.0)
        self.statusLabel.numberOfLines = 0
        self.modeSwitch.onTintColor = KislapBrandPalette.dating
        self.modeSwitch.addTarget(self, action: #selector(self.modeChanged), for: .valueChanged)
        let titleRow = UIStackView(arrangedSubviews: [self.modeLabel, self.activityIndicator, self.modeSwitch])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 10.0
        let stack = UIStackView(arrangedSubviews: [titleRow, self.statusLabel])
        stack.axis = .vertical
        stack.spacing = 7.0
        stack.translatesAutoresizingMaskIntoConstraints = false
        self.modeCard.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: self.modeCard.topAnchor, constant: 16.0),
            stack.leadingAnchor.constraint(equalTo: self.modeCard.leadingAnchor, constant: 16.0),
            stack.trailingAnchor.constraint(equalTo: self.modeCard.trailingAnchor, constant: -16.0),
            stack.bottomAnchor.constraint(equalTo: self.modeCard.bottomAnchor, constant: -16.0),
        ])
    }

    private func configureSafety() {
        self.safetyTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        self.styleCard(self.safetyCard)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0.0
        let values = [
            ("checkmark.shield.fill", KislapBrandPalette.connection),
            ("book.fill", KislapBrandPalette.caution),
            ("power", KislapBrandPalette.success),
        ]
        for (index, value) in values.enumerated() {
            stack.addArrangedSubview(self.safetyRow(icon: value.0, color: value.1))
            if index < values.count - 1 {
                let separator = UIView()
                self.separators.append(separator)
                separator.heightAnchor.constraint(equalToConstant: UIScreenPixel).isActive = true
                stack.addArrangedSubview(separator)
            }
        }
        stack.translatesAutoresizingMaskIntoConstraints = false
        self.safetyCard.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: self.safetyCard.topAnchor, constant: 7.0),
            stack.leadingAnchor.constraint(equalTo: self.safetyCard.leadingAnchor, constant: 16.0),
            stack.trailingAnchor.constraint(equalTo: self.safetyCard.trailingAnchor, constant: -16.0),
            stack.bottomAnchor.constraint(equalTo: self.safetyCard.bottomAnchor, constant: -7.0),
        ])
    }

    private func safetyRow(icon: String, color: UIColor) -> UIView {
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
        title.numberOfLines = 0
        self.rowTitleLabels.append(title)
        let detail = UILabel()
        detail.font = UIFont.systemFont(ofSize: 13.0)
        detail.numberOfLines = 0
        self.rowDetailLabels.append(detail)
        let text = UIStackView(arrangedSubviews: [title, detail])
        text.axis = .vertical
        text.spacing = 2.0
        let row = UIStackView(arrangedSubviews: [iconView, text])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12.0
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 12.0, left: 0.0, bottom: 12.0, right: 0.0)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 24.0),
            iconView.heightAnchor.constraint(equalToConstant: 24.0),
        ])
        return row
    }

    private func styleCard(_ view: UIView) {
        view.layer.cornerRadius = 14.0
        view.layer.borderWidth = UIScreenPixel
    }

    private func updateLocalizedStrings() {
        let strings = self.strings
        self.title = strings.title
        self.heroTitleLabel.text = strings.headline
        self.heroDetailLabel.text = strings.detail
        self.modeTitleLabel.text = strings.modeTitle
        self.modeLabel.text = strings.enable
        self.statusLabel.text = self.modeSwitch.isOn ? strings.on : strings.off
        self.safetyTitleLabel.text = strings.safetyTitle
        let titles = [strings.mutualTitle, strings.learningTitle, strings.controlTitle]
        let details = [strings.mutualDetail, strings.learningDetail, strings.controlDetail]
        for (index, label) in self.rowTitleLabels.enumerated() where titles.indices.contains(index) { label.text = titles[index] }
        for (index, label) in self.rowDetailLabels.enumerated() where details.indices.contains(index) { label.text = details[index] }
    }

    private func updateTheme() {
        guard self.isNodeLoaded else { return }
        let theme = self.presentationData.theme
        self.statusBar.statusBarStyle = theme.rootController.statusBarStyle.style
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData, style: .glass), transition: .immediate)
        self.displayNode.backgroundColor = theme.list.blocksBackgroundColor
        for card in [self.heroCard, self.modeCard, self.safetyCard] {
            card.backgroundColor = theme.list.itemBlocksBackgroundColor
            card.layer.borderColor = theme.list.itemBlocksSeparatorColor.cgColor
        }
        self.heroTitleLabel.textColor = theme.list.itemPrimaryTextColor
        self.heroDetailLabel.textColor = theme.list.itemSecondaryTextColor
        self.modeTitleLabel.textColor = theme.list.itemSecondaryTextColor
        self.modeLabel.textColor = theme.list.itemPrimaryTextColor
        self.statusLabel.textColor = theme.list.itemSecondaryTextColor
        self.safetyTitleLabel.textColor = theme.list.itemSecondaryTextColor
        for label in self.rowTitleLabels { label.textColor = theme.list.itemPrimaryTextColor }
        for label in self.rowDetailLabels { label.textColor = theme.list.itemSecondaryTextColor }
        for separator in self.separators { separator.backgroundColor = theme.list.itemBlocksSeparatorColor }
    }

    private func loadSetting() {
        self.activityIndicator.startAnimating()
        self.modeSwitch.isEnabled = false
        self.apiClient.profile { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.activityIndicator.stopAnimating()
                self.modeSwitch.isEnabled = true
                switch result {
                case let .success(profile):
                    self.serverValue = profile.datingEnabled
                    self.modeSwitch.setOn(profile.datingEnabled, animated: false)
                    self.updateLocalizedStrings()
                case let .failure(error):
                    self.showError(title: self.strings.loadFailed, error: error, retry: true)
                }
            }
        }
    }

    @objc private func modeChanged() {
        guard !self.isUpdating else { return }
        if self.modeSwitch.isOn {
            self.modeSwitch.setOn(false, animated: true)
            let alert = UIAlertController(title: self.strings.confirmTitle, message: self.strings.confirmMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: self.strings.cancel, style: .cancel))
            alert.addAction(UIAlertAction(title: self.strings.confirm, style: .default, handler: { [weak self] _ in
                self?.modeSwitch.setOn(true, animated: true)
                self?.persist(true)
            }))
            self.present(alert, animated: true)
        } else {
            self.persist(false)
        }
    }

    private func persist(_ enabled: Bool) {
        self.isUpdating = true
        self.modeSwitch.isEnabled = false
        self.activityIndicator.startAnimating()
        self.apiClient.updateDating(enabled: enabled) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isUpdating = false
                self.modeSwitch.isEnabled = true
                self.activityIndicator.stopAnimating()
                switch result {
                case .success:
                    self.serverValue = enabled
                    self.modeSwitch.setOn(enabled, animated: true)
                    self.updateLocalizedStrings()
                case let .failure(error):
                    self.modeSwitch.setOn(self.serverValue, animated: true)
                    self.updateLocalizedStrings()
                    self.showError(title: self.strings.updateFailed, error: error, retry: false)
                }
            }
        }
    }

    private func showError(title: String, error: Error, retry: Bool) {
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.strings.ok, style: .cancel))
        if retry {
            alert.addAction(UIAlertAction(title: self.strings.retry, style: .default, handler: { [weak self] _ in self?.loadSetting() }))
        }
        self.present(alert, animated: true)
    }
}
