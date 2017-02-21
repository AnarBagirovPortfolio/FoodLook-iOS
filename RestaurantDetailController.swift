//
//  RestaurantDetailController.swift
//  FoodLook iOS App
//
//  Created by Faannaka on 11.05.16.
//  Copyright © 2016 Faannaka. All rights reserved.
//

import UIKit

class RestaurantDetailController: UIViewController {

    var item: Restaurant? {
        didSet {
            // Update the view.
            self.navigationItem.title = item?.label
            self.configureView()
        }
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goBackManually() {
        self.navigationController?.popViewControllerAnimated(true)
    }
}
