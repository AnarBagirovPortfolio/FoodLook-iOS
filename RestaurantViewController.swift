//
//  RestaurantViewController.swift
//  FoodLook iOS App
//
//  Created by Faannaka on 27.04.16.
//  Copyright © 2016 Faannaka. All rights reserved.
//

import UIKit
import RealmSwift

class RestaurantViewController: UITableViewController {
    
    var map : Dictionary <Int, Int> = Dictionary()
    var errorOccurred : Bool = false
    var rowsCount : Int = 0
    var backgroundImagesUpdate : UpdateBackgroundImages!
    var detailViewController: RestaurantDetailController? = nil
    
    class UpdateList : NSThread {
        let controller : RestaurantViewController!
        
        init(controller : RestaurantViewController) {
            self.controller = controller
        }
        
        func sendAlert(title : String, message : String, button : String) {
            dispatch_async(dispatch_get_main_queue()) {
                let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: button, style: .Default, handler: nil))
                self.controller.presentViewController(alert, animated: true, completion: nil)
            }
        }
        
        override func main() {
            if Api.restaurantsUrl != nil && !controller!.errorOccurred {
                if !self.controller.refreshControl!.refreshing {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                }
                
                let result = Api.updateRestaurantList()
                
                if self.controller.refreshControl!.refreshing {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.controller.refreshControl!.endRefreshing()
                    }
                }
                
                if result == Constants.FunctionResult.success.rawValue {
                    dispatch_async(dispatch_get_main_queue()) {
                        let realm = try! Realm()
                        realm.refresh()
                        var countBeforeUpdate = self.controller.map.keys.maxElement()
                        
                        if countBeforeUpdate == nil {
                            countBeforeUpdate = -1
                        }
                        
                        self.controller.rowsCount = realm.objects(Restaurant).count
                        
                        for restaurant in realm.objects(Restaurant) {
                            if restaurant.logoUrl != nil && restaurant.logo == nil {
                                objc_sync_enter(self.controller.updateStack)
                                self.controller.updateStack.addObject(restaurant.logoUrl!)
                                objc_sync_exit(self.controller.updateStack)
                            }
                        }
                        
                        if self.controller.updateStack.count != 0 {
                            if !self.controller.backgroundImagesUpdate.executing && !self.controller.backgroundImagesUpdate.finished && !self.controller.backgroundImagesUpdate.cancelled {
                                self.controller.backgroundImagesUpdate.start()
                            } else {
                                self.controller.backgroundImagesUpdate = UpdateBackgroundImages(controller: self.controller)
                                self.controller.backgroundImagesUpdate.start()
                            }
                        }
                        
                        var indexPaths: [NSIndexPath] = []
                        for index in 0..<self.controller!.rowsCount {
                            if countBeforeUpdate < index {
                                indexPaths.append(NSIndexPath(forRow: index, inSection: 0))
                            }
                        }
                        
                        self.controller.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .None)
                    }
                } else {
                    controller!.errorOccurred = true
                    
                    if controller.rowsCount == 0 {
                        let message = result == Constants.FunctionResult.networkError.rawValue ? "Отсутствует подключение" : "Ошибка подключения"
                        self.sendAlert("Ошибка", message: message, button: "Ok")
                    }
                }
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
            
            NSThread.exit()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.addTarget(self, action: #selector(self.beginRefreshing), forControlEvents: .ValueChanged)
        self.tableView?.addSubview(refreshControl!)
        
        UpdateList(controller: self).start()
        backgroundImagesUpdate = UpdateBackgroundImages(controller: self)
    }
    
    func beginRefreshing() {
        self.map = Dictionary()
        let realm = try! Realm()
        try! realm.write({ () -> Void in
            realm.delete(realm.objects(Restaurant))
            realm.refresh()
        })
        
        var indexPaths: [NSIndexPath] = []
        for index in 0..<self.rowsCount {
            indexPaths.append(NSIndexPath(forRow: index, inSection: 0))
        }
        self.rowsCount = 0
        self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .None)
        
        Api.restaurantsUrl = "https://www.foodlook.az/api/restaurants/"
        self.errorOccurred = false
        UpdateList(controller: self).start()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1 //Number of sections
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rowsCount //Number of rows
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("restaurant", forIndexPath: indexPath) as! RestaurantCell
        
        let realm = try! Realm()
        if map.keys.contains(indexPath.row) {
            let restaurant = realm.objectForPrimaryKey(Restaurant.self, key: map[indexPath.row]!)
            cell.content = restaurant
        } else {
            let predicate = NSPredicate(format: "!(id IN %@)", Array(map.values))
            let restaurant = realm.objects(Restaurant).filter(predicate).first
            
            if restaurant != nil {
                cell.content = restaurant
                map[indexPath.row] = restaurant!.id
            }
        }
        
        if self.rowsCount == indexPath.row + 1 {
            UpdateList(controller: self).start()
        }
        
        return cell
    }
    
    @IBAction func buttonClicked(sender : AnyObject) {
        print("Button clicked")
    }
    
    //update backgroud images
    
    var updateStack : NSMutableArray = NSMutableArray()
    
    class UpdateBackgroundImages : NSThread {
        let controller : RestaurantViewController!
        
        init(controller : RestaurantViewController) {
            self.controller = controller
        }
        
        override func main() {
            while (self.controller.updateStack.count != 0) {
                objc_sync_enter(self.controller.updateStack)
                let url : String? = self.controller.updateStack.firstObject as? String
                objc_sync_exit(self.controller.updateStack)
                
                if url != nil {
                    let imageData : NSData? = NSData(contentsOfURL: NSURL(string: url!)!)
                    
                    if imageData != nil {
                        dispatch_async(dispatch_get_main_queue()) {
                            let realm = try! Realm()
                            let restaurants = realm.objects(Restaurant).filter("logoUrl = '\(url!)'")
                            var ids : [Int] = []
                            var indexPaths : [NSIndexPath] = []
                            
                            for restaurant in restaurants {
                                ids.append(restaurant.id)
                            }
                            
                            try! realm.write() {
                                for restaurant in restaurants {
                                    restaurant.logo = imageData
                                }
                                realm.add(restaurants, update: true)
                            }
                            
                            for item in self.controller.map {
                                if ids.contains(item.1) {
                                    indexPaths.append(NSIndexPath(forRow: item.0, inSection: 0))
                                }
                            }
                            
                            self.controller.tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .None)
                        }
                    }
                    
                    objc_sync_enter(self.controller.updateStack)
                    self.controller.updateStack.removeObject(url!)
                    objc_sync_exit(self.controller.updateStack)
                    
                } else {
                    NSThread.exit()
                }
            }
        }
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let realm = try! Realm()
                if let restaurant = realm.objectForPrimaryKey(Restaurant.self, key: map[indexPath.row]!) {
                    if let controller = segue.destinationViewController as? RestaurantDetailController {
                        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
                        controller.item = restaurant
                        controller.navigationItem.leftItemsSupplementBackButton = true
                    }
                }
            }
        }
    }
 

}
