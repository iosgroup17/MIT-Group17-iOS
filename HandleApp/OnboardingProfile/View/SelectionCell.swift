import UIKit

class SelectionCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupStyle()
    }

    func setupStyle() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.handleCardBorder.resolvedColor(with: traitCollection).cgColor
        containerView.backgroundColor = .secondarySystemGroupedBackground

        titleLabel.textColor = .label
        subtitleLabel?.textColor = .secondaryLabel
        iconImageView.tintColor = .label
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !isSelected {
            containerView.layer.borderColor = UIColor.handleCardBorder.resolvedColor(with: traitCollection).cgColor
        }
    }

    override var isSelected: Bool {
        didSet {
            containerView.layer.borderColor = isSelected ? UIColor.systemTeal.cgColor : UIColor.handleCardBorder.resolvedColor(with: traitCollection).cgColor
            containerView.backgroundColor = isSelected ? UIColor.systemTeal.withAlphaComponent(0.1) : .secondarySystemGroupedBackground
        }
    }

    func configure(with option: OnboardingOption) {
        titleLabel.text = option.title
        subtitleLabel?.text = option.subtitle

        if let iconName = option.iconName {
            iconImageView.image = UIImage(named: iconName)
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }

        subtitleLabel?.isHidden = (option.subtitle == nil)
    }
}
