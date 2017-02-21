//
//  Api.swift
//  FoodLook iOS App
//
//  Created by Faannaka on 09.04.16.
//  Copyright © 2016 Faannaka. All rights reserved.
//

import Foundation
import RealmSwift

class Token : Object {
    dynamic var type : String?
    dynamic var creationTime : NSDate?
    dynamic var value : String?
    
    override static func primaryKey() -> String? {
        return "type"
    }
}

class UserCreditials : Object {
    dynamic var name : String?
    dynamic var password : String?
}

class Restaurant : Object {
    dynamic var id : Int = -1
    dynamic var label : String?
    dynamic var backgroundImage : NSData?
    dynamic var logo : NSData?
    dynamic var backgroundImageUrl : String?
    dynamic var logoUrl : String?
    dynamic var cuisine : String?
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

//New Objects 27.05.2016

class RestaurantExtension : Object {
    dynamic var id : Int = -1
    dynamic var desc : String?
    dynamic var open : String?
    dynamic var close : String?
    dynamic var kitchenOpeningTime : String?
    dynamic var kitchenClosingTime : String?
    
    dynamic var liveMusic : Bool = false
    dynamic var parking : Bool = false
    dynamic var cardPayment : Bool = false
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class RestaurantCommunication : Object {
    dynamic var id : Int = -1
    dynamic var telephone : String?
    dynamic var email : String?
    dynamic var website : String?
    dynamic var facebook : String?
    dynamic var instagram : String?
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class RestaurantMenu : Object {
    dynamic var id : Int = -1
    dynamic var restaurantId : Int = -1
    dynamic var label : String?
}

//End of 27.05.2016

class Api {
    static var restaurantsUrl : String? = "https://www.foodlook.az/api/restaurants/"
    
    private static func getData(url : String) -> (response : Int, data : NSData?) {
        let tokenUpdateResult = self.updateTokenIfNeeded()
        if tokenUpdateResult != Constants.FunctionResult.success.rawValue {
            return (tokenUpdateResult, nil)
        }
        
        let accessToken = self.AccessToken()
        
        if accessToken == nil {
            return (Constants.FunctionResult.accessError.rawValue, nil)
        }
        
        let semaphore = dispatch_semaphore_create(0)
        var result : Int = Constants.FunctionResult.success.rawValue
        var answer : NSData?
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = "GET"
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "ContentType")
        request.setValue("ru", forHTTPHeaderField: "Accept-Language")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            guard error == nil && data != nil else {
                result = Constants.FunctionResult.networkError.rawValue
                dispatch_semaphore_signal(semaphore)
                return
            }
            
            if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {
                result = Constants.FunctionResult.accessError.rawValue
            }
            else {
                answer = data!
                result = Constants.FunctionResult.success.rawValue
            }
            
            dispatch_semaphore_signal(semaphore)
        }
        
        task.resume()
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        return (result, answer)
    }
    
    static func updateRestaurantList() -> Int {
        if self.restaurantsUrl == nil {
            return Constants.FunctionResult.success.rawValue
        }
        
        let request = self.getData(self.restaurantsUrl!)
        
        if request.response != Constants.FunctionResult.success.rawValue || request.data == nil {
            return request.response
        }
        
        if let json = try? NSJSONSerialization.JSONObjectWithData(request.data!, options: .AllowFragments) {
            if let url = json["next"] as? String {
                self.restaurantsUrl = url
            } else {
                self.restaurantsUrl = nil
            }
            
            let realm = try! Realm()
            
            if let results = json["results"] as? [[String : AnyObject]] {
                for result in results {
                    let restaurant = Restaurant()
                    
                    if let id = result["id"] as? Int {
                        restaurant.id = id
                    }
                    if let label = result["label"] as? String {
                        restaurant.label = label
                    }
                    
                    if let backgroundImageUrl = result["background_image"] as? String {
                        restaurant.backgroundImageUrl = backgroundImageUrl
                    }
                    
                    if let logoUrl = result["logo"] as? String {
                        restaurant.logoUrl = logoUrl
                    }
                    
                    if let cuisine = result["cuisine"] as? String {
                        restaurant.cuisine = cuisine
                    }
                    
                    if !restaurant.isEmpty() {
                        try! realm.write({
                            realm.add(restaurant, update: true)
                        })
                    }
                }
            }
        }
        
        return Constants.FunctionResult.success.rawValue
    }
    
    private static func updateTokenIfNeeded() -> Int {
        if !self.isTokenAlive(Constants.TokenType.accessToken.rawValue) {
            return self.getToken()
        } else {
            return Constants.FunctionResult.success.rawValue
        }
    }
    
    private static func AccessToken() -> String? {
        let realm = try! Realm()
        realm.refresh()
        let tokens = realm.objects(Token).filter("type = '\(Constants.TokenType.accessToken.rawValue)'")
        
        return tokens.first?.value
    }
    
    private static func isTokenAlive(type : String) -> Bool {
        let realm = try! Realm()
        
        let tokens = realm.objects(Token).filter("type = '\(type)'")
        
        if tokens.count > 1 {
            try! realm.write({ () -> Void in
                realm.delete(tokens)
            })
        } else if tokens.count == 1 {
            if type.equals(Constants.TokenType.accessToken.rawValue) {
                //Script for Access Token
                let creationTime = tokens.first?.creationTime
                
                if creationTime != nil {
                    let tokenLivingtime = Constants.TokenLivingtime.accessToken.rawValue
                    let nullableTime = NSDate(timeIntervalSinceNow: (-1) * tokenLivingtime)
                    let compareResult = creationTime!.compare(nullableTime).rawValue
                    if compareResult == 1 {
                        return true
                    }
                }
            } else if type.equals(Constants.TokenType.refreshToken.rawValue) {
                //Script for Refresh Token
                let creationTime = tokens.first?.creationTime
                
                if creationTime != nil {
                    let tokenLivingtime = Constants.TokenLivingtime.refreshToken.rawValue
                    let nullableTime = NSDate(timeIntervalSinceNow: (-1) * tokenLivingtime)
                    let compareResult = creationTime!.compare(nullableTime).rawValue
                    if compareResult == 1 {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    static func getToken(username : String, password : String) -> Int {
        let url = NSURL(string: "https://www.foodlook.az/api/oauth2/token/")!
        var answer = Constants.FunctionResult.otherError.rawValue
        let body = NSString(string: "client_id=\(Constants.UserAuth.id.rawValue)&client_secret=\(Constants.UserAuth.secret.rawValue)&grant_type=password&username=\(username)&password=\(password)")
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)
        
        let semaphore = dispatch_semaphore_create(0)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            guard error == nil && data != nil else {
                answer = Constants.FunctionResult.networkError.rawValue
                dispatch_semaphore_signal(semaphore)
                return
            }
            
            if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                answer = Constants.FunctionResult.accessError.rawValue
            } else {
                var accessTokenValue : String?
                var refreshTokenValue : String?
                
                if let json = try? NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) {
                    if let token = json["access_token"] as? String {
                        accessTokenValue = token
                    }
                    if let token = json["refresh_token"] as? String {
                        refreshTokenValue = token
                    }
                }
                
                if accessTokenValue != nil && refreshTokenValue != nil {
                    let now = NSDate()
                    
                    let accessToken = Token()
                    accessToken.type = Constants.TokenType.accessToken.rawValue
                    accessToken.creationTime = now
                    accessToken.value = accessTokenValue
                    
                    let refreshToken = Token()
                    refreshToken.type = Constants.TokenType.refreshToken.rawValue
                    refreshToken.creationTime = now
                    refreshToken.value = refreshTokenValue
                    
                    let realm = try! Realm()
                    
                    try! realm.write({ () -> Void in
                        realm.add([accessToken, refreshToken], update: true)
                    })
                    
                    answer = Constants.FunctionResult.success.rawValue
                } else {
                    answer = Constants.FunctionResult.accessError.rawValue
                }
            }
            
            dispatch_semaphore_signal(semaphore)
        }
        
        task.resume()
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        return answer
    }
    
    static func getToken() -> Int {
        let realm = try! Realm()
        let creditials = realm.objects(UserCreditials)
        
        if creditials.count == 1 {
            let username = creditials.first?.name
            let password = creditials.first?.password
            
            if username != nil && password != nil {
                return self.getToken(username!, password: password!)
            }
        }
        
        realm.beginWrite()
        realm.delete(creditials)
        try! realm.commitWrite()
        
        return Constants.FunctionResult.accessError.rawValue
    }
    
    static func clearDataBase(deleteCreditials deleteCreditials : Bool) {
        let realm = try! Realm()
        
        if deleteCreditials {
            realm.beginWrite()
            realm.deleteAll()
            try! realm.commitWrite()
        }
        else {
            try! realm.write({ () -> Void in
                realm.delete(realm.objects(Restaurant))
            })
        }
    }
    
    static func isCreditialsExists() -> Bool {
        let realm = try! Realm()
        if realm.objects(UserCreditials).count == 1 {
            return true
        }
        
        print(realm.objects(UserCreditials).count)
        
        return false
    }
    
    static func AddCreditials(username : String, password : String) {
        let creditials : UserCreditials = UserCreditials()
        creditials.name = username
        creditials.password = password
        
        let realm = try! Realm()
        realm.beginWrite()
        realm.add(creditials)
        try! realm.commitWrite()
    }
}


