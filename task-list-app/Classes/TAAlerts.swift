//
//  Extensions.swift
//  task-list-app
//
//  Created by Joshua Heslin on 13/9/18.
//  Copyright © 2018 Joshua Heslin. All rights reserved.
//

import Foundation
import UIKit

class TAAlerts {
    
    public func createAlert(title: String, message: String, buttonTitle: String, view: UIViewController){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let button = UIAlertAction(title: buttonTitle, style: .cancel, handler: nil)
        alert.addAction(button)
        view.present(alert, animated: true, completion: {
            view.navigationController?.popViewController(animated: true)
        })
    }
    
}
