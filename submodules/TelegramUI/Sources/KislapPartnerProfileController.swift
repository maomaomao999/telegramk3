import Foundation
import UIKit
import TelegramPresentationData

/// A focused, learning-first profile sheet for Nearby.
///
/// The surrounding surfaces use Telegram presentation colors while Kislap
/// accents are limited to status, learning roles and the primary action.
final class KislapPartnerProfileController: UIViewController {
    private let partner: KislapLearningPartner
    private let selectedSkill: String
    private let presentationData: PresentationData
    private let strings: KislapNearbyStrings
    private let apiClient = KislapAPIClient.shared

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let avatarView = UIImageView()
    private let initialsLabel = UILabel()
    private let connectButton = UIButton(type: .system)
    private let safetyButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    var onSafety: (() -> Void)?

    init(partner: KislapLearningPartner, selectedSkill: String, presentationData: PresentationData) {
        self.partner = partner
        self.selectedSkill = selectedSkill
        self.presentationData = presentationData
        self.strings = KislapNearbyStrings(languageCode: presentationData.strings.baseLanguageCode)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.buildView()
        self.loadAvatar()
    }

    private var theme: PresentationTheme {
        return self.presentationData.theme
    }

    private func buildView() {
        self.view.backgroundColor = self.theme.list.blocksBackgroundColor

        self.contentStack.axis = .vertical
        self.contentStack.spacing = 18.0
        self.contentStack.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.alwaysBounceVertical = true
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.scrollView)
        self.scrollView.addSubview(self.contentStack)

        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            self.contentStack.topAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.topAnchor, constant: 16.0),
            self.contentStack.leadingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.leadingAnchor, constant: 16.0),
            self.contentStack.trailingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.trailingAnchor, constant: -16.0),
            self.contentStack.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor, constant: -24.0),
        ])

        self.contentStack.addArrangedSubview(self.makeTopBar())
        self.contentStack.addArrangedSubview(self.makeIdentityCard())

        let learningSkills = self.partner.skills.filter { $0.role == "LEARNING" }
        let teachingSkills = self.partner.skills.filter { $0.role == "TEACHING" }
        if !learningSkills.isEmpty {
            self.contentStack.addArrangedSubview(self.makeSkillsSection(title: self.strings.wantsToLearn, skills: learningSkills, tint: self.theme.list.itemAccentColor))
        }
        if !teachingSkills.isEmpty {
            self.contentStack.addArrangedSubview(self.makeSkillsSection(title: self.strings.canTeach, skills: teachingSkills, tint: KislapBrandPalette.success))
        }
        if learningSkills.isEmpty && teachingSkills.isEmpty && !self.partner.interests.isEmpty {
            self.contentStack.addArrangedSubview(self.makeInterestSection())
        }

        self.contentStack.addArrangedSubview(self.makeAboutSection())
        self.contentStack.addArrangedSubview(self.makeSafetyNote())
        self.contentStack.addArrangedSubview(self.makeActions())
    }

    private func makeTopBar() -> UIView {
        let title = UILabel()
        title.text = self.strings.viewProfile
        title.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        title.textColor = self.theme.list.itemPrimaryTextColor

        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
        close.tintColor = self.theme.list.itemPrimaryTextColor
        close.backgroundColor = self.theme.list.controlSecondaryColor
        close.layer.cornerRadius = 16.0
        close.accessibilityLabel = self.strings.close
        close.addTarget(self, action: #selector(self.closePressed), for: .touchUpInside)
        close.translatesAutoresizingMaskIntoConstraints = false

        let spacer = UIView()
        let row = UIStackView(arrangedSubviews: [title, spacer, close])
        row.axis = .horizontal
        row.alignment = .center
        NSLayoutConstraint.activate([
            close.widthAnchor.constraint(equalToConstant: 32.0),
            close.heightAnchor.constraint(equalToConstant: 32.0),
        ])
        return row
    }

    private func makeIdentityCard() -> UIView {
        let card = self.makeCard()

        let avatarContainer = UIView()
        avatarContainer.backgroundColor = self.theme.list.itemAccentColor.withAlphaComponent(0.14)
        avatarContainer.layer.cornerRadius = 44.0
        avatarContainer.clipsToBounds = true
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false

        self.initialsLabel.text = self.initials(for: self.partner.displayName)
        self.initialsLabel.font = UIFont.systemFont(ofSize: 28.0, weight: .bold)
        self.initialsLabel.textColor = self.theme.list.itemAccentColor
        self.initialsLabel.textAlignment = .center
        self.initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(self.initialsLabel)

        self.avatarView.contentMode = .scaleAspectFill
        self.avatarView.clipsToBounds = true
        self.avatarView.isHidden = true
        self.avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(self.avatarView)

        let activityDot = UIView()
        activityDot.backgroundColor = self.partner.activityStatus == "active_now" ? KislapBrandPalette.success : KislapBrandPalette.success.withAlphaComponent(0.55)
        activityDot.layer.cornerRadius = 8.0
        activityDot.layer.borderWidth = 3.0
        activityDot.layer.borderColor = self.theme.list.itemBlocksBackgroundColor.cgColor
        activityDot.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(activityDot)

        NSLayoutConstraint.activate([
            avatarContainer.widthAnchor.constraint(equalToConstant: 88.0),
            avatarContainer.heightAnchor.constraint(equalToConstant: 88.0),
            self.initialsLabel.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            self.initialsLabel.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            self.initialsLabel.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor),
            self.avatarView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            self.avatarView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            self.avatarView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            self.avatarView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
            activityDot.widthAnchor.constraint(equalToConstant: 16.0),
            activityDot.heightAnchor.constraint(equalToConstant: 16.0),
            activityDot.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor, constant: -2.0),
            activityDot.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: -2.0),
        ])

        let name = UILabel()
        name.text = "\(self.partner.displayName), \(self.partner.age)"
        name.font = UIFont.systemFont(ofSize: 23.0, weight: .bold)
        name.textColor = self.theme.list.itemPrimaryTextColor
        name.numberOfLines = 0

        let statusText = self.partner.activityStatus == "active_now" ? self.strings.activeNow : self.strings.activeRecently
        let status = self.makeCapsule(text: statusText, icon: "circle.fill", tint: self.partner.activityStatus == "active_now" ? KislapBrandPalette.success : self.theme.list.itemSecondaryTextColor)
        let location = self.makeCapsule(text: self.locationText(), icon: self.partner.isDemo == true ? "sparkles" : "location.fill", tint: self.theme.list.itemAccentColor)

        let metadata = UIStackView(arrangedSubviews: [status, location])
        metadata.axis = .vertical
        metadata.alignment = .leading
        metadata.spacing = 7.0

        let verified = self.makeCapsule(
            text: self.partner.verificationStatus == "UNVERIFIED" ? self.strings.learningProfile : self.strings.verifiedAdult,
            icon: self.partner.verificationStatus == "UNVERIFIED" ? "person.crop.circle" : "checkmark.seal.fill",
            tint: self.partner.verificationStatus == "UNVERIFIED" ? self.theme.list.itemSecondaryTextColor : KislapBrandPalette.success
        )

        let stack = UIStackView(arrangedSubviews: [avatarContainer, name, verified, metadata])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 11.0
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20.0),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16.0),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16.0),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20.0),
        ])
        return card
    }

    private func makeSkillsSection(title: String, skills: [KislapLearningSkill], tint: UIColor) -> UIView {
        let card = self.makeCard()
        let titleLabel = self.makeSectionTitle(title)
        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 0.0
        for (index, skill) in skills.enumerated() {
            rows.addArrangedSubview(self.makeSkillRow(skill: skill, tint: tint))
            if index < skills.count - 1 {
                rows.addArrangedSubview(self.makeSeparator())
            }
        }
        let stack = UIStackView(arrangedSubviews: [titleLabel, rows])
        stack.axis = .vertical
        stack.spacing = 8.0
        self.pin(stack, in: card)
        return card
    }

    private func makeInterestSection() -> UIView {
        let card = self.makeCard()
        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 0.0
        for (index, interest) in self.partner.interests.prefix(4).enumerated() {
            let skill = KislapLearningSkill(slug: interest, name: interest, role: "LEARNING", level: "")
            rows.addArrangedSubview(self.makeSkillRow(skill: skill, tint: self.theme.list.itemAccentColor))
            if index < min(self.partner.interests.count, 4) - 1 {
                rows.addArrangedSubview(self.makeSeparator())
            }
        }
        let stack = UIStackView(arrangedSubviews: [self.makeSectionTitle(self.strings.learningInterests), rows])
        stack.axis = .vertical
        stack.spacing = 8.0
        self.pin(stack, in: card)
        return card
    }

    private func makeSkillRow(skill: KislapLearningSkill, tint: UIColor) -> UIView {
        let iconContainer = UIView()
        iconContainer.backgroundColor = tint.withAlphaComponent(0.13)
        iconContainer.layer.cornerRadius = 10.0
        iconContainer.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: self.skillIcon(slug: skill.slug)))
        icon.tintColor = tint
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(icon)

        let name = UILabel()
        name.text = self.skillName(name: skill.name, slug: skill.slug)
        name.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        name.textColor = self.theme.list.itemPrimaryTextColor

        let level = UILabel()
        level.text = skill.level.replacingOccurrences(of: "_", with: " ").capitalized
        level.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        level.textColor = self.theme.list.itemSecondaryTextColor
        level.isHidden = skill.level.isEmpty

        let text = UIStackView(arrangedSubviews: [name, level])
        text.axis = .vertical
        text.spacing = 2.0

        let row = UIStackView(arrangedSubviews: [iconContainer, text])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12.0
        row.layoutMargins = UIEdgeInsets(top: 9.0, left: 0.0, bottom: 9.0, right: 0.0)
        row.isLayoutMarginsRelativeArrangement = true
        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 38.0),
            iconContainer.heightAnchor.constraint(equalToConstant: 38.0),
            icon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 19.0),
            icon.heightAnchor.constraint(equalToConstant: 19.0),
        ])
        return row
    }

    private func makeAboutSection() -> UIView {
        let card = self.makeCard()
        let body = UILabel()
        let trimmedBio = self.partner.bio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        body.text = trimmedBio.isEmpty ? self.strings.noProfileDetails : trimmedBio
        body.font = UIFont.systemFont(ofSize: 15.0)
        body.textColor = trimmedBio.isEmpty ? self.theme.list.itemSecondaryTextColor : self.theme.list.itemPrimaryTextColor
        body.numberOfLines = 0
        let stack = UIStackView(arrangedSubviews: [self.makeSectionTitle(self.strings.profileAbout), body])
        stack.axis = .vertical
        stack.spacing = 8.0
        self.pin(stack, in: card)
        return card
    }

    private func makeSafetyNote() -> UIView {
        let card = self.makeCard()
        card.backgroundColor = self.theme.list.itemAccentColor.withAlphaComponent(0.08)
        card.layer.borderColor = self.theme.list.itemAccentColor.withAlphaComponent(0.18).cgColor

        let icon = UIImageView(image: UIImage(systemName: "checkmark.shield.fill"))
        icon.tintColor = self.theme.list.itemAccentColor
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = self.strings.profileSafetyNote
        label.font = UIFont.systemFont(ofSize: 13.0)
        label.textColor = self.theme.list.itemSecondaryTextColor
        label.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 10.0
        self.pin(row, in: card)
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 22.0),
            icon.heightAnchor.constraint(equalToConstant: 22.0),
        ])
        return card
    }

    private func makeActions() -> UIView {
        self.connectButton.setTitle(self.strings.requestStudySession, for: .normal)
        self.connectButton.setTitleColor(.white, for: .normal)
        self.connectButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        self.connectButton.backgroundColor = self.theme.list.itemAccentColor
        self.connectButton.layer.cornerRadius = 13.0
        self.connectButton.addTarget(self, action: #selector(self.connectPressed), for: .touchUpInside)

        self.safetyButton.setTitle(self.strings.safety, for: .normal)
        self.safetyButton.setImage(UIImage(systemName: "shield.fill"), for: .normal)
        self.safetyButton.tintColor = self.theme.list.itemAccentColor
        self.safetyButton.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
        self.safetyButton.backgroundColor = self.theme.list.controlSecondaryColor
        self.safetyButton.layer.cornerRadius = 13.0
        self.safetyButton.addTarget(self, action: #selector(self.safetyPressed), for: .touchUpInside)

        self.activityIndicator.hidesWhenStopped = true
        self.connectButton.addSubview(self.activityIndicator)
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.activityIndicator.centerYAnchor.constraint(equalTo: self.connectButton.centerYAnchor),
            self.activityIndicator.trailingAnchor.constraint(equalTo: self.connectButton.trailingAnchor, constant: -16.0),
        ])

        let row = UIStackView(arrangedSubviews: [self.connectButton, self.safetyButton])
        row.axis = .horizontal
        row.spacing = 10.0
        NSLayoutConstraint.activate([
            self.connectButton.heightAnchor.constraint(equalToConstant: 50.0),
            self.safetyButton.widthAnchor.constraint(equalToConstant: 104.0),
        ])
        return row
    }

    private func makeCard() -> UIView {
        let card = UIView()
        card.backgroundColor = self.theme.list.itemBlocksBackgroundColor
        card.layer.cornerRadius = 16.0
        card.layer.borderWidth = UIScreen.main.scale > 0.0 ? 1.0 / UIScreen.main.scale : 0.5
        card.layer.borderColor = self.theme.list.itemBlocksSeparatorColor.cgColor
        return card
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .semibold)
        label.textColor = self.theme.list.itemSecondaryTextColor
        return label
    }

    private func makeCapsule(text: String, icon iconName: String, tint: UIColor) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = tint
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .semibold)
        label.textColor = tint

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 5.0
        row.layoutMargins = UIEdgeInsets(top: 5.0, left: 9.0, bottom: 5.0, right: 9.0)
        row.isLayoutMarginsRelativeArrangement = true
        row.backgroundColor = tint.withAlphaComponent(0.11)
        row.layer.cornerRadius = 12.0
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 12.0),
            icon.heightAnchor.constraint(equalToConstant: 12.0),
        ])
        return row
    }

    private func makeSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = self.theme.list.itemBlocksSeparatorColor
        separator.heightAnchor.constraint(equalToConstant: UIScreen.main.scale > 0.0 ? 1.0 / UIScreen.main.scale : 0.5).isActive = true
        return separator
    }

    private func pin(_ stack: UIStackView, in card: UIView) {
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 15.0),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16.0),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16.0),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -15.0),
        ])
    }

    private func initials(for displayName: String) -> String {
        let value = displayName.split(whereSeparator: { $0.isWhitespace }).prefix(2).compactMap(\.first).map(String.init).joined()
        return value.isEmpty ? "K" : value.uppercased()
    }

    private func locationText() -> String {
        if self.partner.isDemo == true {
            return self.strings.reviewDemoProfile
        }
        let distance: String
        switch self.partner.distanceLabel {
        case "nearby":
            distance = self.strings.distanceNearby
        case "far":
            distance = self.strings.distanceFar
        default:
            distance = self.strings.distanceAbout(self.partner.distanceLabel)
        }
        let city = self.partner.city.map { " · \($0)" } ?? ""
        return "\(distance)\(city) · \(self.strings.approximateAreaOnly)"
    }

    private func skillName(name: String, slug: String) -> String {
        guard self.strings.isChinese else { return name }
        let value = slug.lowercased()
        if value.contains("english") { return "英语口语" }
        if value.contains("program") || value.contains("coding") { return "编程" }
        if value.contains("sing") { return "唱歌" }
        if value.contains("music") { return "音乐" }
        return name
    }

    private func skillIcon(slug: String) -> String {
        let value = slug.lowercased()
        if value.contains("english") || value.contains("language") { return "text.bubble.fill" }
        if value.contains("program") || value.contains("coding") { return "chevron.left.forwardslash.chevron.right" }
        if value.contains("sing") || value.contains("music") { return "music.mic" }
        return "sparkles"
    }

    private func loadAvatar() {
        let preferredPhoto = self.partner.photos.first(where: { $0.isMain == true }) ?? self.partner.photos.first
        guard let path = preferredPhoto?.url ?? preferredPhoto?.thumbUrl else { return }
        self.apiClient.loadProfileImage(path: path) { [weak self] image in
            DispatchQueue.main.async {
                self?.avatarView.image = image
                self?.avatarView.isHidden = image == nil
            }
        }
    }

    @objc private func closePressed() {
        self.dismiss(animated: true)
    }

    @objc private func connectPressed() {
        guard self.connectButton.isEnabled else { return }
        self.connectButton.isEnabled = false
        self.activityIndicator.startAnimating()
        self.apiClient.requestStudyConnection(userId: self.partner.userId, skill: self.selectedSkill) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.activityIndicator.stopAnimating()
                switch result {
                case .success:
                    self.connectButton.setTitle(self.strings.requestSent, for: .normal)
                case let .failure(error):
                    self.connectButton.isEnabled = true
                    let alert = UIAlertController(title: self.strings.couldNotSendRequest, message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: self.presentationData.strings.Common_OK, style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    @objc private func safetyPressed() {
        let action = self.onSafety
        self.dismiss(animated: true) {
            action?()
        }
    }
}
