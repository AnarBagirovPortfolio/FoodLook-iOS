//
//  LoginViewController.swift
//  FoodLook iOS App
//
//  Created by Faannaka on 10.04.16.
//  Copyright © 2016 Faannaka. All rights reserved.
//

import UIKit
import RealmSwift

class LoginViewController: UIViewController {

    @IBOutlet weak var logoTopMargin: NSLayoutConstraint!
    @IBOutlet weak var usernameTextField : UITextField!
    @IBOutlet weak var passwordTextField : UITextField!
    
    private let screenHeight = UIScreen.mainScreen().bounds.height
    private let screenWidth = UIScreen.mainScreen().bounds.width
    
    private enum TopMarginValues : CGFloat {
        case small = 32
        case medium = 64
        case large = 96
        case veryLarge = 128
    }
    
    private enum ScreenHeights : CGFloat {
        case small = 480.0
        case medium = 568.0
        case large = 667.0
        case veryLarge = 736.0
    }
    
    private func setStandardTopMargin() {
        switch self.screenHeight {
        case ScreenHeights.small.rawValue :
            self.logoTopMargin.constant = TopMarginValues.small.rawValue
        case ScreenHeights.medium.rawValue :
            self.logoTopMargin.constant = TopMarginValues.medium.rawValue
        case ScreenHeights.large.rawValue :
            self.logoTopMargin.constant = TopMarginValues.large.rawValue
        case ScreenHeights.veryLarge.rawValue :
            self.logoTopMargin.constant = TopMarginValues.veryLarge.rawValue
        default :
            self.logoTopMargin.constant = 0
        }
    }
    
    private func setSmallTopMargin() {
        if self.screenHeight == ScreenHeights.small.rawValue {
            self.logoTopMargin.constant = -140
        }
        else if self.screenHeight == ScreenHeights.medium.rawValue {
            self.logoTopMargin.constant = -50
        }
        else {
            self.logoTopMargin.constant = 0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setStandardTopMargin()
        
        Api.clearDataBase(deleteCreditials: true)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification:NSNotification) {
        UIView.animateWithDuration(0.5, animations: {
            self.setSmallTopMargin()
            self.view.layoutIfNeeded()
        })
    }
    
    func keyboardWillHide(notification:NSNotification) {
        UIView.animateWithDuration(0.5, animations: {
            self.setStandardTopMargin()
            self.view.layoutIfNeeded()
        })
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func loginButtonClicked(sender : AnyObject) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let username = self.usernameTextField.text!
        let password = self.passwordTextField.text!
        
        if username.isEmpty || password.isEmpty {
            let alert = UIAlertController(title: "Ошибка", message: "Имя пользователя и/или пароль не введены", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            let tokenRequest = Api.getToken(username, password: password)
            
            if tokenRequest == Constants.FunctionResult.accessError.rawValue {
                let alert = UIAlertController(title: "Ошибка", message: "Имя пользователя или пароль не верны", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            else if tokenRequest == Constants.FunctionResult.networkError.rawValue {
                let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключение", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            else if tokenRequest == Constants.FunctionResult.success.rawValue {
                Api.AddCreditials(username, password: password)
                self.performSegueWithIdentifier("GoToTabView", sender: nil)
            }
            else {
                let alert = UIAlertController(title: "Ошибка", message: "Внутренняя ошибка приложения", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    @IBAction func registerButtonClicked(sender : AnyObject) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = !UIApplication.sharedApplication().networkActivityIndicatorVisible
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "GoToTabView" {
            
        }
    }
}
