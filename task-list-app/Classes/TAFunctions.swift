//
//  TKConstants.swift
//  task-list-app
//
//  Created by Joshua Heslin on 13/9/18.
//  Copyright © 2018 Joshua Heslin. All rights reserved.
//

import Foundation
import UIKit

class TAFunctions {
    
    public func getDateComparisonResultFromToday(dateToTest: Date)-> ComparisonResult {
        
        let nowDate = Date()
        
        //for comparing if deadline is greater than or less than today
        
        //OrderedAscending = deadline is first, today is second
        //OrderedDecending = today is first, deadline is second
        
        let result = Calendar.current.compare(nowDate, to: dateToTest, toGranularity: .day)
    
        return result
    }

    public func styleFullBackgroundTableView() -> UIView {
        let fullBackgroundView = UIView() //it will resize regardless
        fullBackgroundView.backgroundColor = UIColor.white
        return fullBackgroundView
    }
    
    public func styleTopBackgroundTableView(view: UIViewController) -> UIView {
        let topBackgroundRect = CGRect(x: 0, y: 0, width: view.view.frame.width, height: view.view.frame.height/12)
        let topBackgroundView = UIView(frame: topBackgroundRect)
        let color = UIColor(white: 0.90, alpha: 0.2)
        topBackgroundView.backgroundColor = color
        return topBackgroundView
    }
    
    public func stringFromTimeInterval(interval: TimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    
    
    
}
