//
//  RestaurantRxViewController.swift
//  FoodLook iOS App
//
//  Created by Faannaka on 22.05.16.
//  Copyright © 2016 Faannaka. All rights reserved.
//

import UIKit
import RxSwift
import RxBlocking
import RxCocoa
import RealmSwift

class RestaurantRxViewController : UITableViewController {
    
    var restaurants = Variable([Restaurant]())
    let disposeBag = DisposeBag()
    var updateRestaurantList: UpdateRestaurantList?
    var updateLogos: UpdateLogos?
    var logoURLStack : NSMutableArray = NSMutableArray()
    
    override func viewDidLoad() {
        self.configureController()
        self.configureRefreshController()
        super.viewDidLoad()
        self.beginUpdate()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func beginUpdate() {
        if updateRestaurantList == nil {
            updateRestaurantList = UpdateRestaurantList(controller: self)
        }
        
        if !self.updateRestaurantList!.executing {
            if self.updateRestaurantList!.finished || self.updateRestaurantList!.cancelled {
                self.updateRestaurantList = UpdateRestaurantList(controller: self)
            }
            
            self.updateRestaurantList!.start()
        }
    }
    
    func beginUpdateLogos() {
        if self.updateLogos == nil {
            self.updateLogos = UpdateLogos(controller: self)
        }
        
        if !self.updateLogos!.executing {
            if self.updateLogos!.finished || self.updateLogos!.cancelled {
                self.updateLogos = UpdateLogos(controller: self)
            }
            
            self.updateLogos!.start()
        }
    }
    
    func setActivityIndicators(value: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = value
        }
        
        if !value {
            if let refreshControl = self.refreshControl {
                refreshControl.endRefreshing()
            }
        }
    }
    
    func addMissingElements() {
        dispatch_async(dispatch_get_main_queue()) {
            let realm = try! Realm()
            realm.refresh()
            let restaurants = realm.objects(Restaurant)
            
            for restaurant in restaurants {
                if !self.restaurants.value.contains({ $0.id == restaurant.id}) {
                    self.restaurants.value.append(restaurant)
                }
                
                if restaurant.logo == nil && restaurant.logoUrl != nil {
                    self.logoURLStack.safelyAddObject(restaurant.logoUrl!)
                    self.beginUpdateLogos()
                }
            }
        }
    }
    
    func configureController() {
        self.restaurants.asObservable().subscribe().addDisposableTo(self.disposeBag)
        self.restaurants.asObservable().bindTo(self.tableView.rx_itemsWithCellIdentifier("restaurant", cellType: RestaurantCell.self)) { (row, element, cell) in
            cell.content = element
            if row == self.restaurants.value.count - 1 && row != 0 {
                self.beginUpdate()
            }
        }.addDisposableTo(disposeBag)
    }
    
    func configureRefreshController() {
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.addTarget(self, action: #selector(self.resreshView), forControlEvents: .ValueChanged)
        self.tableView?.addSubview(refreshControl!)
    }
    
    func resreshView() {
        self.updateRestaurantList?.cancel()
        self.updateLogos?.cancel()
        
        let realm = try! Realm()
        try! realm.write() {
            self.restaurants.value.removeAll()
            realm.delete(realm.objects(Restaurant))
        }
        
        Api.restaurantsUrl = "https://www.foodlook.az/api/restaurants/"
        self.beginUpdate()
    }
    
    func updateLogo(logoUrl : String) {
        if let imageData = NSData(contentsOfURL: NSURL(string: URLWithSizeValue(logoUrl, heigth: 150, width: 150))!) {
            dispatch_async(dispatch_get_main_queue()) {
                let realm = try! Realm()
                for restaurant in self.restaurants.value.filter({ $0.logoUrl == logoUrl && $0.logo == nil }) {
                    try! realm.write() {
                        restaurant.logo = imageData
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    
    func URLWithSizeValue(url: String, heigth : Int, width: Int) -> String {
        if url.substringFromIndex(url.endIndex.predecessor()) == "/" {
            return url + heigth.description + "x" + width.description + "/"
        } else {
            return url + "/" + heigth.description + "x" + width.description + "/"
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let controller = segue.destinationViewController as? RestaurantDetailController {
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    let restaurant = self.restaurants.value[indexPath.row]
                    controller.item = restaurant
                }
            }
        }
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        segue.destinationViewController.navigationItem.leftItemsSupplementBackButton = true
    }
    
}

class UpdateRestaurantList : NSThread {
    let controller: RestaurantRxViewController!
    
    init(controller : RestaurantRxViewController) {
        self.controller = controller
    }
    
    override func main() {
        if Api.restaurantsUrl == nil {
            return
        }
        
        controller.setActivityIndicators(true)
        let updateResult = Api.updateRestaurantList()
        controller.setActivityIndicators(false)
        
        if updateResult == Constants.FunctionResult.success.rawValue {
            controller.addMissingElements()
        }
    }
}

class UpdateLogos : NSThread {
    let controller: RestaurantRxViewController!
    
    init(controller : RestaurantRxViewController) {
        self.controller = controller
    }
    
    override func main() {
        while (self.controller.logoURLStack.count != 0) {
            if let url = self.controller.logoURLStack.safelyGetFirstObject() {
                self.controller.updateLogo(url as! String)
                self.controller.logoURLStack.safelyRemoveObject(url)
            }
        }
    }
}