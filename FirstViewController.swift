//
//  FirstViewController.swift
//  FoodLook iOS App
//
//  Created by Faannaka on 09.04.16.
//  Copyright © 2016 Faannaka. All rights reserved.
//

import UIKit
import RealmSwift

class FirstViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //"Sherlock", password: "Strange"
        //Api.getToken("Sherlock", password: "Strange")
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func goToLogin() {
        print(Api.updateRestaurantList())
        //print(Api.isCreditialsExists())
        
        let realm = try! Realm()
        let restaurants = realm.objects(Restaurant)
        
        for restaurant in restaurants {
            print(restaurant.id.description + " | " + restaurant.label!)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

