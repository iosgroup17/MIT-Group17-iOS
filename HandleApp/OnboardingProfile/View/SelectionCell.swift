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
        // Make it look like a card
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray4.cgColor
        containerView.backgroundColor = .white
    }
    
    override var isSelected: Bool {
        didSet {
            containerView.layer.borderColor = isSelected ? UIColor.systemTeal.cgColor : UIColor.systemGray4.cgColor
            containerView.backgroundColor = isSelected ? UIColor.systemTeal.withAlphaComponent(0.1) : .white
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
