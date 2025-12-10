//
//  PlatformFilterViewController.swift
//  OnboardingScreens
//
//  Created by SDC_USER on 28/11/25.
//

import UIKit
protocol PlatformMenuDelegate: AnyObject {
    func didSelectPlatform(_ platform: String)
}
class PlatformFilterViewController: UIViewController {
    weak var delegate: PlatformMenuDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 250, height: 300)
            view.backgroundColor = .white
        // Do any additional setup after loading the view.
    }
    

    @IBAction func platformButtonTapped(_ sender: UIButton) {
        let tag = sender.tag
            var platform: String?
            
            // Map the tag integer to the platform string
            switch tag {
            case 1:
                platform = "All"
                print("all")
            case 2:
                platform = "LinkedIn"
            case 3:
                platform = "Instagram"
            case 4:
                platform = "X"
            default:
                print("Error: Unknown button tag.")
                return
            }
            
            // Pass the mapped platform string
            if let selectedPlatform = platform {
                delegate?.didSelectPlatform(selectedPlatform)
            }
        dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
