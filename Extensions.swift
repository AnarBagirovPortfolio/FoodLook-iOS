//
//  Extensions.swift
//  FoodLook iOS App
//
//  Created by Faannaka on 09.04.16.
//  Copyright © 2016 Faannaka. All rights reserved.
//

import Foundation

extension String {
    func equals(other : String) -> Bool {
        if self == other {
            return true
        }
        else {
            return false
        }
    }
}

extension Restaurant {
    func isEmpty() -> Bool {
        if self.id == -1 || self.label == nil {
            return true
        }
        else {
            return false
        }
    }
}

extension NSMutableArray {
    func safelyAddObject(object: AnyObject) {
        objc_sync_enter(self)
        self.addObject(object)
        objc_sync_exit(self)
    }
    
    func safelyRemoveObject(object: AnyObject) {
        objc_sync_enter(self)
        self.removeObject(object)
        objc_sync_exit(self)
    }
    
    func safelyGetFirstObject() -> AnyObject? {
        objc_sync_enter(self)
        let result = self.firstObject
        objc_sync_exit(self)
        return result
    }
}