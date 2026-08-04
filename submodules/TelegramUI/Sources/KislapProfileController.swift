import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import AVFoundation
import Photos

final class KislapProfileController: ViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private struct SkillControl {
        let slug: String
        let learnSwitch: UISwitch
        let teachSwitch: UISwitch
    }

    private let context: AccountContext
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    private var appliedLanguageCode: String
    private let apiClient = KislapAPIClient.shared

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let headerCard = UIView()
    private let avatarView = UIImageView()
    private let initialsLabel = UILabel()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let verifiedLabel = UILabel()
    private let photoButton = UIButton(type: .system)
    private let photoHintLabel = UILabel()
    private let basicTitleLabel = UILabel()
    private let fieldsCard = UIView()
    private let displayNameField = UITextField()
    private let goalField = UITextField()
    private let bioView = UITextView()
    private let languagesField = UITextField()
    private let availabilityField = UITextField()
    private let skillsTitleLabel = UILabel()
    private let skillsDetailLabel = UILabel()
    private let skillsCard = UIView()
    private var skillControls: [SkillControl] = []
    private let privacyTitleLabel = UILabel()
    private let privacyCard = UIView()
    private let privacyLabel = UILabel()
    private let datingButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let accountTitleLabel = UILabel()
    private let accountCard = UIView()
    private let disconnectButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private var loadedProfile: KislapProfile?
    private var isSaving = false

    private var strings: KislapProfileStrings {
        return KislapProfileStrings(languageCode: self.presentationData.strings.baseLanguageCode)
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

        self.configureHeader()
        self.configureFields()
        self.configureSkills()
        self.configurePrivacy()
        self.configureAccount()

        self.contentStack.addArrangedSubview(self.headerCard)
        self.contentStack.setCustomSpacing(22.0, after: self.headerCard)
        self.contentStack.addArrangedSubview(self.basicTitleLabel)
        self.contentStack.addArrangedSubview(self.fieldsCard)
        self.contentStack.setCustomSpacing(22.0, after: self.fieldsCard)
        self.contentStack.addArrangedSubview(self.skillsTitleLabel)
        self.contentStack.addArrangedSubview(self.skillsDetailLabel)
        self.contentStack.addArrangedSubview(self.skillsCard)
        self.contentStack.addArrangedSubview(self.saveButton)
        self.contentStack.setCustomSpacing(22.0, after: self.saveButton)
        self.contentStack.addArrangedSubview(self.privacyTitleLabel)
        self.contentStack.addArrangedSubview(self.privacyCard)
        self.contentStack.setCustomSpacing(22.0, after: self.privacyCard)
        self.contentStack.addArrangedSubview(self.accountTitleLabel)
        self.contentStack.addArrangedSubview(self.accountCard)

        self.scrollView.alwaysBounceVertical = true
        self.scrollView.keyboardDismissMode = .interactive
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
        self.loadProfile()
    }

    private func configureHeader() {
        self.styleCard(self.headerCard)
        self.avatarView.layer.cornerRadius = 34.0
        self.avatarView.clipsToBounds = true
        self.avatarView.contentMode = .scaleAspectFill
        self.avatarView.translatesAutoresizingMaskIntoConstraints = false

        self.initialsLabel.font = UIFont.systemFont(ofSize: 24.0, weight: .bold)
        self.initialsLabel.textAlignment = .center
        self.initialsLabel.translatesAutoresizingMaskIntoConstraints = false

        let avatarContainer = UIView()
        avatarContainer.layer.cornerRadius = 34.0
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(self.initialsLabel)
        avatarContainer.addSubview(self.avatarView)

        self.photoButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0, weight: .semibold)
        self.photoButton.contentHorizontalAlignment = .left
        self.photoButton.addTarget(self, action: #selector(self.photoPressed), for: .touchUpInside)
        self.photoHintLabel.font = UIFont.systemFont(ofSize: 12.0)
        self.photoHintLabel.numberOfLines = 0

        self.nameLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .bold)
        self.nameLabel.numberOfLines = 1
        self.subtitleLabel.font = UIFont.systemFont(ofSize: 14.0)
        self.subtitleLabel.numberOfLines = 0
        self.verifiedLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        self.verifiedLabel.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [self.nameLabel, self.subtitleLabel, self.verifiedLabel, self.photoButton, self.photoHintLabel])
        textStack.axis = .vertical
        textStack.spacing = 3.0
        let row = UIStackView(arrangedSubviews: [avatarContainer, textStack, self.activityIndicator])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 14.0
        row.translatesAutoresizingMaskIntoConstraints = false
        self.headerCard.addSubview(row)

        NSLayoutConstraint.activate([
            avatarContainer.widthAnchor.constraint(equalToConstant: 68.0),
            avatarContainer.heightAnchor.constraint(equalToConstant: 68.0),
            self.initialsLabel.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            self.initialsLabel.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            self.initialsLabel.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor),
            self.avatarView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            self.avatarView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            self.avatarView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            self.avatarView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
            row.topAnchor.constraint(equalTo: self.headerCard.topAnchor, constant: 16.0),
            row.leadingAnchor.constraint(equalTo: self.headerCard.leadingAnchor, constant: 16.0),
            row.trailingAnchor.constraint(equalTo: self.headerCard.trailingAnchor, constant: -16.0),
            row.bottomAnchor.constraint(equalTo: self.headerCard.bottomAnchor, constant: -16.0),
        ])
    }

    private func configureFields() {
        self.basicTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        self.styleCard(self.fieldsCard)

        self.configureField(self.displayNameField, contentType: .name)
        self.configureField(self.goalField, contentType: nil)
        self.configureField(self.languagesField, contentType: nil)
        self.configureField(self.availabilityField, contentType: nil)
        self.bioView.font = UIFont.systemFont(ofSize: 16.0)
        self.bioView.layer.cornerRadius = 9.0
        self.bioView.isScrollEnabled = false
        self.bioView.textContainerInset = UIEdgeInsets(top: 9.0, left: 8.0, bottom: 9.0, right: 8.0)
        self.bioView.heightAnchor.constraint(greaterThanOrEqualToConstant: 92.0).isActive = true

        let fields = UIStackView(arrangedSubviews: [
            self.makeFieldGroup(label: self.strings.displayName, view: self.displayNameField),
            self.makeFieldGroup(label: self.strings.learningGoal, view: self.goalField),
            self.makeFieldGroup(label: self.strings.bio, view: self.bioView),
            self.makeFieldGroup(label: self.strings.languages, view: self.languagesField),
            self.makeFieldGroup(label: self.strings.availability, view: self.availabilityField),
        ])
        fields.axis = .vertical
        fields.spacing = 15.0
        fields.translatesAutoresizingMaskIntoConstraints = false
        self.fieldsCard.addSubview(fields)
        NSLayoutConstraint.activate([
            fields.topAnchor.constraint(equalTo: self.fieldsCard.topAnchor, constant: 16.0),
            fields.leadingAnchor.constraint(equalTo: self.fieldsCard.leadingAnchor, constant: 16.0),
            fields.trailingAnchor.constraint(equalTo: self.fieldsCard.trailingAnchor, constant: -16.0),
            fields.bottomAnchor.constraint(equalTo: self.fieldsCard.bottomAnchor, constant: -16.0),
        ])
    }

    private func configureSkills() {
        self.skillsTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        self.skillsDetailLabel.font = UIFont.systemFont(ofSize: 14.0)
        self.skillsDetailLabel.numberOfLines = 0
        self.styleCard(self.skillsCard)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0.0
        let topics = [("english", self.strings.english), ("programming", self.strings.programming), ("singing", self.strings.singing)]
        for (index, topic) in topics.enumerated() {
            let learnSwitch = UISwitch()
            let teachSwitch = UISwitch()
            self.skillControls.append(SkillControl(slug: topic.0, learnSwitch: learnSwitch, teachSwitch: teachSwitch))
            stack.addArrangedSubview(self.makeSkillRow(title: topic.1, learnSwitch: learnSwitch, teachSwitch: teachSwitch))
            if index < topics.count - 1 {
                stack.addArrangedSubview(self.makeSeparator())
            }
        }
        stack.translatesAutoresizingMaskIntoConstraints = false
        self.skillsCard.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: self.skillsCard.topAnchor, constant: 8.0),
            stack.leadingAnchor.constraint(equalTo: self.skillsCard.leadingAnchor, constant: 16.0),
            stack.trailingAnchor.constraint(equalTo: self.skillsCard.trailingAnchor, constant: -16.0),
            stack.bottomAnchor.constraint(equalTo: self.skillsCard.bottomAnchor, constant: -8.0),
        ])

        self.saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        self.saveButton.setTitleColor(.white, for: .normal)
        self.saveButton.layer.cornerRadius = 13.0
        self.saveButton.contentEdgeInsets = UIEdgeInsets(top: 14.0, left: 18.0, bottom: 14.0, right: 18.0)
        self.saveButton.addTarget(self, action: #selector(self.savePressed), for: .touchUpInside)
    }

    private func configurePrivacy() {
        self.privacyTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        self.styleCard(self.privacyCard)
        self.privacyLabel.font = UIFont.systemFont(ofSize: 15.0)
        self.privacyLabel.numberOfLines = 0
        self.datingButton.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
        self.datingButton.contentHorizontalAlignment = .left
        self.datingButton.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        self.datingButton.addTarget(self, action: #selector(self.datingPressed), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [self.privacyLabel, self.datingButton])
        stack.axis = .vertical
        stack.spacing = 8.0
        stack.translatesAutoresizingMaskIntoConstraints = false
        self.privacyCard.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: self.privacyCard.topAnchor, constant: 16.0),
            stack.leadingAnchor.constraint(equalTo: self.privacyCard.leadingAnchor, constant: 16.0),
            stack.trailingAnchor.constraint(equalTo: self.privacyCard.trailingAnchor, constant: -16.0),
            stack.bottomAnchor.constraint(equalTo: self.privacyCard.bottomAnchor, constant: -10.0),
        ])
    }

    private func configureAccount() {
        self.accountTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        self.styleCard(self.accountCard)
        self.disconnectButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        self.disconnectButton.contentHorizontalAlignment = .left
        self.disconnectButton.addTarget(self, action: #selector(self.disconnectPressed), for: .touchUpInside)
        self.deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        self.deleteButton.contentHorizontalAlignment = .left
        self.deleteButton.addTarget(self, action: #selector(self.deletePressed), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [self.disconnectButton, self.makeSeparator(), self.deleteButton])
        stack.axis = .vertical
        stack.spacing = 0.0
        stack.translatesAutoresizingMaskIntoConstraints = false
        self.accountCard.addSubview(stack)
        NSLayoutConstraint.activate([
            self.disconnectButton.heightAnchor.constraint(equalToConstant: 50.0),
            self.deleteButton.heightAnchor.constraint(equalToConstant: 50.0),
            stack.leadingAnchor.constraint(equalTo: self.accountCard.leadingAnchor, constant: 16.0),
            stack.trailingAnchor.constraint(equalTo: self.accountCard.trailingAnchor, constant: -16.0),
            stack.topAnchor.constraint(equalTo: self.accountCard.topAnchor),
            stack.bottomAnchor.constraint(equalTo: self.accountCard.bottomAnchor),
        ])
    }

    private func configureField(_ field: UITextField, contentType: UITextContentType?) {
        field.font = UIFont.systemFont(ofSize: 16.0)
        field.borderStyle = .none
        field.textContentType = contentType
        field.autocorrectionType = .yes
        field.clearButtonMode = .whileEditing
        field.heightAnchor.constraint(equalToConstant: 38.0).isActive = true
    }

    private func makeFieldGroup(label: String, view: UIView) -> UIView {
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        labelView.tag = 700
        let stack = UIStackView(arrangedSubviews: [labelView, view])
        stack.axis = .vertical
        stack.spacing = 3.0
        return stack
    }

    private func makeSkillRow(title: String, learnSwitch: UISwitch, teachSwitch: UISwitch) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        titleLabel.tag = 701
        let learnLabel = UILabel()
        learnLabel.text = self.strings.learn
        learnLabel.font = UIFont.systemFont(ofSize: 12.0)
        learnLabel.tag = 702
        let teachLabel = UILabel()
        teachLabel.text = self.strings.teach
        teachLabel.font = UIFont.systemFont(ofSize: 12.0)
        teachLabel.tag = 702
        let learnStack = UIStackView(arrangedSubviews: [learnLabel, learnSwitch])
        learnStack.axis = .vertical
        learnStack.alignment = .center
        learnStack.spacing = 2.0
        let teachStack = UIStackView(arrangedSubviews: [teachLabel, teachSwitch])
        teachStack.axis = .vertical
        teachStack.alignment = .center
        teachStack.spacing = 2.0
        let row = UIStackView(arrangedSubviews: [titleLabel, learnStack, teachStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12.0
        row.heightAnchor.constraint(equalToConstant: 70.0).isActive = true
        return row
    }

    private func makeSeparator() -> UIView {
        let separator = UIView()
        separator.tag = 703
        separator.heightAnchor.constraint(equalToConstant: UIScreenPixel).isActive = true
        return separator
    }

    private func styleCard(_ view: UIView) {
        view.layer.cornerRadius = 14.0
        view.layer.borderWidth = UIScreenPixel
    }

    private func updateLocalizedStrings() {
        let strings = self.strings
        self.title = strings.title
        self.subtitleLabel.text = strings.subtitle
        self.verifiedLabel.text = "✓ " + strings.verifiedAdult
        self.photoButton.setTitle(strings.photoAction, for: .normal)
        self.photoHintLabel.text = strings.photoHint
        self.basicTitleLabel.text = strings.basicInformation
        self.displayNameField.placeholder = strings.displayName
        self.goalField.placeholder = strings.learningGoal
        self.languagesField.placeholder = strings.languages
        self.availabilityField.placeholder = strings.availability
        self.skillsTitleLabel.text = strings.skillsTitle
        self.skillsDetailLabel.text = strings.skillsDetail
        self.privacyTitleLabel.text = strings.privacyTitle
        self.privacyLabel.text = strings.privacyDetail
        self.datingButton.setTitle(strings.datingSettings, for: .normal)
        self.saveButton.setTitle(self.isSaving ? strings.saving : strings.save, for: .normal)
        self.accountTitleLabel.text = strings.accountTitle
        self.disconnectButton.setTitle(strings.disconnect, for: .normal)
        self.deleteButton.setTitle(strings.deleteAccount, for: .normal)
    }

    private func updateTheme() {
        guard self.isNodeLoaded else { return }
        let theme = self.presentationData.theme
        self.statusBar.statusBarStyle = theme.rootController.statusBarStyle.style
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData, style: .glass), transition: .immediate)
        self.displayNode.backgroundColor = theme.list.blocksBackgroundColor
        for card in [self.headerCard, self.fieldsCard, self.skillsCard, self.privacyCard, self.accountCard] {
            card.backgroundColor = theme.list.itemBlocksBackgroundColor
            card.layer.borderColor = theme.list.itemBlocksSeparatorColor.cgColor
        }
        self.avatarView.backgroundColor = theme.list.controlSecondaryColor
        self.initialsLabel.superview?.backgroundColor = theme.list.itemAccentColor.withAlphaComponent(0.14)
        self.initialsLabel.textColor = theme.list.itemAccentColor
        self.nameLabel.textColor = theme.list.itemPrimaryTextColor
        self.subtitleLabel.textColor = theme.list.itemSecondaryTextColor
        self.verifiedLabel.textColor = KislapBrandPalette.success
        self.photoButton.setTitleColor(theme.list.itemAccentColor, for: .normal)
        self.photoHintLabel.textColor = theme.list.itemSecondaryTextColor
        for title in [self.basicTitleLabel, self.skillsTitleLabel, self.privacyTitleLabel, self.accountTitleLabel] {
            title.textColor = theme.list.itemSecondaryTextColor
        }
        self.skillsDetailLabel.textColor = theme.list.itemSecondaryTextColor
        self.privacyLabel.textColor = theme.list.itemSecondaryTextColor
        self.datingButton.setTitleColor(theme.list.itemAccentColor, for: .normal)
        for field in [self.displayNameField, self.goalField, self.languagesField, self.availabilityField] {
            field.textColor = theme.list.itemPrimaryTextColor
            field.backgroundColor = theme.list.controlSecondaryColor
            field.layer.cornerRadius = 9.0
            field.leftView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 10.0, height: 1.0))
            field.leftViewMode = .always
        }
        self.bioView.textColor = theme.list.itemPrimaryTextColor
        self.bioView.backgroundColor = theme.list.controlSecondaryColor
        self.setColors(in: self.fieldsCard)
        self.setColors(in: self.skillsCard)
        for control in self.skillControls {
            control.learnSwitch.onTintColor = theme.list.itemAccentColor
            control.teachSwitch.onTintColor = KislapBrandPalette.success
        }
        self.saveButton.backgroundColor = theme.list.itemAccentColor
        self.disconnectButton.setTitleColor(theme.list.itemAccentColor, for: .normal)
        self.deleteButton.setTitleColor(theme.list.itemDestructiveColor, for: .normal)
        self.setColors(in: self.accountCard)
    }

    private func setColors(in view: UIView) {
        let theme = self.presentationData.theme
        for subview in view.subviews {
            if let label = subview as? UILabel {
                label.textColor = label.tag == 700 || label.tag == 702 ? theme.list.itemSecondaryTextColor : theme.list.itemPrimaryTextColor
            } else if subview.tag == 703 {
                subview.backgroundColor = theme.list.itemBlocksSeparatorColor
            }
            self.setColors(in: subview)
        }
    }

    private func loadProfile() {
        self.activityIndicator.startAnimating()
        self.setFormEnabled(false)
        self.apiClient.profile { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.activityIndicator.stopAnimating()
                self.setFormEnabled(true)
                switch result {
                case let .success(profile):
                    self.apply(profile: profile)
                case let .failure(error):
                    self.showError(title: self.strings.loadFailed, error: error, retry: true)
                }
            }
        }
    }

    private func apply(profile: KislapProfile) {
        self.loadedProfile = profile
        self.nameLabel.text = profile.displayName
        self.initialsLabel.text = self.initials(for: profile.displayName)
        self.displayNameField.text = profile.displayName
        self.goalField.text = profile.learningGoal
        self.bioView.text = profile.bio
        self.languagesField.text = profile.spokenLanguages.joined(separator: ", ")
        self.availabilityField.text = profile.availability

        for control in self.skillControls {
            control.learnSwitch.isOn = profile.skills.contains(where: { $0.skill.slug == control.slug && $0.role == "LEARNING" })
            control.teachSwitch.isOn = profile.skills.contains(where: { $0.skill.slug == control.slug && $0.role == "TEACHING" })
        }

        let preferredPhoto = profile.photos.first(where: { $0.isMain == true }) ?? profile.photos.first
        self.avatarView.isHidden = true
        if let path = preferredPhoto?.thumbUrl ?? preferredPhoto?.url {
            self.apiClient.loadProfileImage(path: path) { [weak self] image in
                DispatchQueue.main.async {
                    self?.avatarView.image = image
                    self?.avatarView.isHidden = image == nil
                }
            }
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        let result = parts.compactMap(\.first).map(String.init).joined()
        return result.isEmpty ? "K" : result.uppercased()
    }

    @objc private func savePressed() {
        guard !self.isSaving else { return }
        let displayName = self.displayNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !displayName.isEmpty else {
            self.showMessage(title: self.strings.saveFailed, message: self.strings.nameRequired)
            return
        }
        let languages = (self.languagesField.text ?? "")
            .replacingOccurrences(of: "，", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        self.isSaving = true
        self.setFormEnabled(false)
        self.updateLocalizedStrings()
        self.apiClient.updateProfile(
            displayName: displayName,
            bio: self.bioView.text.trimmingCharacters(in: .whitespacesAndNewlines),
            learningGoal: self.goalField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            spokenLanguages: languages,
            availability: self.availabilityField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        ) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.saveSkills()
            case let .failure(error):
                DispatchQueue.main.async { self.finishSaving(error: error) }
            }
        }
    }

    private func saveSkills() {
        var learning: [(String, String)] = []
        var teaching: [(String, String)] = []
        let coreSlugs = Set(self.skillControls.map(\.slug))
        for assignment in self.loadedProfile?.skills ?? [] where !coreSlugs.contains(assignment.skill.slug) {
            if assignment.role == "LEARNING" {
                learning.append((assignment.skill.slug, assignment.level))
            } else if assignment.role == "TEACHING" {
                teaching.append((assignment.skill.slug, assignment.level))
            }
        }
        for control in self.skillControls {
            let existingLearnLevel = self.loadedProfile?.skills.first(where: { $0.skill.slug == control.slug && $0.role == "LEARNING" })?.level ?? "BEGINNER"
            let existingTeachLevel = self.loadedProfile?.skills.first(where: { $0.skill.slug == control.slug && $0.role == "TEACHING" })?.level ?? "INTERMEDIATE"
            if control.learnSwitch.isOn { learning.append((control.slug, existingLearnLevel)) }
            if control.teachSwitch.isOn { teaching.append((control.slug, existingTeachLevel)) }
        }
        self.apiClient.updateSkills(learning: learning, teaching: teaching) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    self.finishSaving(error: nil)
                case let .failure(error):
                    self.finishSaving(error: error)
                }
            }
        }
    }

    private func finishSaving(error: Error?) {
        self.isSaving = false
        self.setFormEnabled(true)
        self.updateLocalizedStrings()
        if let error {
            self.showError(title: self.strings.saveFailed, error: error, retry: false)
        } else {
            self.nameLabel.text = self.displayNameField.text
            self.initialsLabel.text = self.initials(for: self.displayNameField.text ?? "")
            self.showMessage(title: self.strings.saved, message: nil)
            self.loadProfile()
        }
    }

    private func setFormEnabled(_ enabled: Bool) {
        for view in [self.displayNameField, self.goalField, self.bioView, self.languagesField, self.availabilityField, self.photoButton, self.saveButton, self.disconnectButton, self.deleteButton] {
            view.isUserInteractionEnabled = enabled
            view.alpha = enabled ? 1.0 : 0.65
        }
        for control in self.skillControls {
            control.learnSwitch.isEnabled = enabled
            control.teachSwitch.isEnabled = enabled
        }
    }

    @objc private func photoPressed() {
        let alert = UIAlertController(title: self.strings.photoAction, message: self.strings.photoHint, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: self.strings.takePhoto, style: .default, handler: { [weak self] _ in
                self?.openImagePicker(sourceType: .camera)
            }))
        }
        alert.addAction(UIAlertAction(title: self.strings.choosePhoto, style: .default, handler: { [weak self] _ in
            self?.openImagePicker(sourceType: .photoLibrary)
        }))
        alert.addAction(UIAlertAction(title: self.strings.cancel, style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = self.photoButton
            popover.sourceRect = self.photoButton.bounds
        }
        self.present(alert, animated: true)
    }

    private func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        if sourceType == .camera {
            let authorization = AVCaptureDevice.authorizationStatus(for: .video)
            if authorization == .denied || authorization == .restricted {
                self.presentPermissionRecovery(title: self.strings.cameraPermissionTitle)
                return
            }
        } else {
            let authorization: PHAuthorizationStatus
            if #available(iOS 14.0, *) {
                authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            } else {
                authorization = PHPhotoLibrary.authorizationStatus()
            }
            if authorization == .denied || authorization == .restricted {
                self.presentPermissionRecovery(title: self.strings.photoPermissionTitle)
                return
            }
        }

        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.allowsEditing = true
        picker.modalPresentationStyle = .fullScreen
        self.present(picker, animated: true)
    }

    private func presentPermissionRecovery(title: String) {
        let alert = UIAlertController(title: title, message: self.strings.permissionDetail, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.strings.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: self.strings.openSettings, style: .default, handler: { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }))
        self.present(alert, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage,
              let data = self.normalizedPhotoData(from: image) else {
            picker.dismiss(animated: true)
            self.showMessage(title: self.strings.photoUploadFailed, message: nil)
            return
        }

        picker.dismiss(animated: true) { [weak self] in
            self?.uploadProfilePhoto(data)
        }
    }

    private func normalizedPhotoData(from image: UIImage) -> Data? {
        let squareSide = min(image.size.width, image.size.height)
        guard squareSide > 0.0 else { return nil }
        let outputSide = min(CGFloat(1080.0), squareSide)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: outputSide, height: outputSide), format: format)
        let normalized = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0.0, y: 0.0, width: outputSide, height: outputSide))
            let scale = max(outputSide / image.size.width, outputSide / image.size.height)
            let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let drawRect = CGRect(
                x: (outputSide - drawSize.width) * 0.5,
                y: (outputSide - drawSize.height) * 0.5,
                width: drawSize.width,
                height: drawSize.height
            )
            image.draw(in: drawRect)
        }
        return normalized.jpegData(compressionQuality: 0.82)
    }

    private func uploadProfilePhoto(_ data: Data) {
        self.photoButton.setTitle(self.strings.uploadingPhoto, for: .normal)
        self.photoButton.isEnabled = false
        self.activityIndicator.startAnimating()
        self.apiClient.uploadProfilePhoto(data: data) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.activityIndicator.stopAnimating()
                self.photoButton.isEnabled = true
                self.updateLocalizedStrings()
                switch result {
                case .success:
                    self.loadProfile()
                case let .failure(error):
                    self.showError(title: self.strings.photoUploadFailed, error: error, retry: false)
                }
            }
        }
    }

    @objc private func disconnectPressed() {
        let alert = UIAlertController(title: self.strings.disconnect, message: self.strings.disconnectMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.strings.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: self.strings.disconnect, style: .destructive, handler: { [weak self] _ in
            guard let self else { return }
            self.apiClient.disconnect { _ in
                DispatchQueue.main.async {
                    (self.navigationController as? NavigationController)?.filterController(self, animated: true)
                }
            }
        }))
        self.present(alert, animated: true)
    }

    @objc private func datingPressed() {
        (self.navigationController as? NavigationController)?.pushViewController(KislapDatingSettingsController(context: self.context))
    }

    @objc private func deletePressed() {
        let alert = UIAlertController(title: self.strings.deleteAccount, message: self.strings.deleteMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.strings.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: self.strings.deleteConfirm, style: .destructive, handler: { [weak self] _ in
            guard let self else { return }
            self.deleteButton.setTitle(self.strings.deleting, for: .normal)
            self.setFormEnabled(false)
            self.apiClient.deleteLearningAccount { [weak self] result in
                DispatchQueue.main.async {
                    guard let self else { return }
                    switch result {
                    case .success:
                        (self.navigationController as? NavigationController)?.filterController(self, animated: true)
                    case let .failure(error):
                        self.setFormEnabled(true)
                        self.updateLocalizedStrings()
                        self.showError(title: self.strings.deleteFailed, error: error, retry: false)
                    }
                }
            }
        }))
        self.present(alert, animated: true)
    }

    private func showMessage(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.strings.ok, style: .default))
        self.present(alert, animated: true)
    }

    private func showError(title: String, error: Error, retry: Bool) {
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.strings.ok, style: .cancel))
        if retry {
            alert.addAction(UIAlertAction(title: self.strings.retry, style: .default, handler: { [weak self] _ in self?.loadProfile() }))
        }
        self.present(alert, animated: true)
    }
}
