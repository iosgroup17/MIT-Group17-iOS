import UIKit

/// Dismissible "Complete your profile" card shown at the top of the Discover
/// (home) screen. Built programmatically. The card itself carries all of its
/// margins so the section can use zero insets and collapse cleanly when hidden.
final class ProfileNudgeCell: UICollectionViewCell {

    static let reuseID = "ProfileNudgeCell"

    /// Called when the user taps the small dismiss (x) button.
    var dismissAction: (() -> Void)?

    private let card = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let progressLabel = UILabel()
    private let chevron = UIImageView()
    private let dismissButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    func configure(completed: Int, total: Int) {
        let remaining = max(total - completed, 0)
        subtitleLabel.text = remaining == 1
            ? "1 step left for the best suggestions"
            : "Finish setup for the best suggestions"
        progressLabel.text = "\(completed) of \(total) done"
        let fraction = total > 0 ? Float(completed) / Float(total) : 0
        progressBar.setProgress(fraction, animated: false)
    }

    private func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Card container
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.systemGray5.cgColor
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.layer.shadowRadius = 8
        card.layer.masksToBounds = false
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        // Icon
        iconView.image = UIImage(systemName: "person.crop.circle.badge.exclamationmark")
        iconView.tintColor = UIColor.systemTeal
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iconView)

        // Title
        titleLabel.text = "Complete your profile"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1

        // Subtitle
        subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        // Progress bar
        progressBar.progressTintColor = UIColor.systemTeal
        progressBar.trackTintColor = UIColor.systemGray5
        progressBar.layer.cornerRadius = 2
        progressBar.clipsToBounds = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.heightAnchor.constraint(equalToConstant: 4).isActive = true

        // Progress count label
        progressLabel.font = .preferredFont(forTextStyle: .caption2)
        progressLabel.textColor = .secondaryLabel
        progressLabel.setContentHuggingPriority(.required, for: .horizontal)

        let progressRow = UIStackView(arrangedSubviews: [progressBar, progressLabel])
        progressRow.axis = .horizontal
        progressRow.alignment = .center
        progressRow.spacing = 8

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, progressRow])
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 4
        textStack.setCustomSpacing(8, after: subtitleLabel)
        textStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(textStack)

        // Chevron affordance
        chevron.image = UIImage(systemName: "chevron.right")
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(chevron)

        // Dismiss button (top-trailing)
        dismissButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        dismissButton.tintColor = .tertiaryLabel
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        card.addSubview(dismissButton)

        NSLayoutConstraint.activate([
            // Card carries its own margins (16 sides, 10/6 vertical).
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            textStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),

            chevron.leadingAnchor.constraint(equalTo: textStack.trailingAnchor, constant: 8),
            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),

            dismissButton.topAnchor.constraint(equalTo: card.topAnchor, constant: 6),
            dismissButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -6),
            dismissButton.widthAnchor.constraint(equalToConstant: 28),
            dismissButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    @objc private func dismissTapped() {
        dismissAction?()
    }
}
