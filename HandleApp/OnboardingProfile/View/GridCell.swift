import UIKit

class GridCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpStyle()
    }
    
    func setUpStyle() {
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray5.cgColor
        containerView.backgroundColor = .white
    }
    
    override var isSelected: Bool{
        didSet {
            containerView.layer.borderColor = isSelected ? UIColor.systemTeal.cgColor : UIColor.systemGray5.cgColor
            containerView.backgroundColor = isSelected ? UIColor.systemTeal.withAlphaComponent(0.1) : .white
        }
    }
    
    func configure(with option: OnboardingOption) {
            titleLabel.text = option.title
            if let iconName = option.iconName {
                iconImageView.image = UIImage(named: iconName)
        }
    }
}
