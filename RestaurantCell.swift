//
//  RestaurantCell.swift
//  FoodLook iOS App
//
//  Created by Faannaka on 27.04.16.
//  Copyright © 2016 Faannaka. All rights reserved.
//

import UIKit

class RestaurantCell: UITableViewCell {
    
    @IBOutlet weak var label : UILabel!
    @IBOutlet weak var cuisine : UILabel!
    @IBOutlet weak var logo : UIImageView!
    @IBOutlet weak var labelTopConstraint: NSLayoutConstraint!
    
    var content : Restaurant! {
        didSet {
            label.text = content.label
            cuisine.text = content.cuisine
            
            if content.logo != nil {
                logo.image = UIImage(data: content.logo!)
            } else {
                self.logo.image = nil
            }
            
            labelTopConstraint.constant = (logo.frame.size.height - label.frame.size.height - cuisine.frame.size.height) / 2
            
            self.logo.layer.masksToBounds = false
            self.logo.layer.cornerRadius = self.logo.frame.size.height / 2
            self.logo.clipsToBounds = true
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
