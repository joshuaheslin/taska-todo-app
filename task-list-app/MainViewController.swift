//
//  ViewController.swift
//  task-list-app
//
//  Created by Joshua Heslin on 7/5/18.
//  Copyright © 2018 Joshua Heslin. All rights reserved.
//

import UIKit
import UserNotifications
import CoreData

class MainViewController: UIViewController, UNUserNotificationCenterDelegate, UITableViewDelegate {
    
    var taskItems: [Tasks] = []
    
    //futura bold 17

    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var overdueTasksSummaryButton: UIButton!
    @IBOutlet weak var todayTasksSummaryButton: UIButton!
    
    @IBOutlet weak var calendarSwitchView: UISwitch!
    @IBOutlet weak var viewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var settingsView: UIView!
    @IBOutlet weak var calendarLabel: UILabel!
    
    var noOfTasksToday = 0
    var noOfOverdueTasks = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        hideNavigationBar()
        
        styleSettingsSidebarView()
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.swipedForSettings(gesture:)))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.swipedForSettings(gesture:)))
        swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
        self.view.addGestureRecognizer(swipeLeft)
        
        let tapped = UITapGestureRecognizer(target: self, action: #selector(self.tapped(gesture:)))
        self.view.addGestureRecognizer(tapped)
        
        
        //-----------LOCAL NOTIFICATION SETUP-----------------
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            // Enable or disable features based on authorization
        }
        
        //only used triggered to remove the "Daily" notification on previous builds
        //createUserNotification(title: "Test", body: "test", identifierNotification: "Daily", triggerDate: Date().addingTimeInterval(24*60*60))
        center.removePendingNotificationRequests(withIdentifiers: ["Daily"]) //only necessary for legacy builds
        
        //remove all UN
        //center.removeAllPendingNotificationRequests()
        
        //print all UN
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: {requests -> () in
            print("\(requests.count) requests -------")
            for request in requests{
                print(request.identifier)
                //print(request.trigger)
            }
            print("end requests -------")
        })
        
        //-----------CALENDAR-----------------
        //TODO
        let ekclass = EKEventsClass()
        
        if let savedCalendarIdentifier = UserDefaults.standard.string(forKey: "EventTrackerPrimaryCalendar") {
            print ("calender identifier VC: \(savedCalendarIdentifier)")
            ekclass.taskCalendarIdentifier = savedCalendarIdentifier
            ekclass.loadCalendars()
            
            ekclass.assignLoadedCalendars()
            
            ekclass.loadEvents()
            //print(UserDefaults.standard.string(forKey: "event1")!)
            //ekclass.createEvent()
            
        }
        
        //deleteAllCoreData() //only for testing to clear current data
        fetchCoreDataOnLaunch() //gets if tasks are empty
        updateTaskButtons(intToday: noOfTasksToday, intOverdue: noOfOverdueTasks)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        fetchCoreDataOnLaunch()
        updateTaskButtons(intToday: noOfTasksToday, intOverdue: noOfOverdueTasks)
    }
    
    //MARK: - Functions
    
    @objc func swipedForSettings(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizer.Direction.right:
                print ("User Swiped Right-Settings")
                
                if self.settingsView.frame.origin.x == 0 {
                    //do nothing
                } else {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.settingsView.frame.origin.x += 270
                    }, completion: nil)
                }
                
            case UISwipeGestureRecognizer.Direction.left:
                if self.settingsView.frame.origin.x == 0 {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.settingsView.frame.origin.x -= 270
                    }, completion: nil)
                } else {
                    //do nothing
                }
                
            default:
                break;
            }
        }
    }
    
    @objc func tapped(gesture: UITapGestureRecognizer) {
        if gesture.location(in: self.view).x >= 270 {
            UIView.animate(withDuration: 0.3, animations: {
                self.settingsView.frame.origin.x -= 270
            }, completion: nil)
        }
    }
    
    func updateTaskButtons(intToday: Int, intOverdue: Int){
        todayTasksSummaryButton.setTitle("you have \(intToday) tasks due today.", for: .normal)
        overdueTasksSummaryButton.setTitle("you have \(intOverdue) tasks overdue.", for: .normal)
        
        if intToday == 0 && intOverdue == 0 {
            summaryLabel.text = "you're all done. 👍"
        } else {
            summaryLabel.text = "get to work."
        }
    }
    
    func styleSettingsSidebarView() {
        
        if let isTrue = UserDefaults.standard.value(forKey: "willSaveToCalendar"){
            if isTrue as! Bool { //if returns true
                calendarSwitchView.isOn = true
                calendarLabel.textColor = UIColor.white
            } else {
                calendarSwitchView.isOn = false
                calendarLabel.textColor = UIColor.lightGray
            }
        }
        
        viewLeadingConstraint.constant = -270
        calendarSwitchView.tintColor = UIColor.white
        calendarSwitchView.onTintColor = UIColor.lightGray

    }
    
    //MARK: - CoreData
    
    func deleteAllCoreData(){
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        //1
        let context = appDelegate.persistentContainer.viewContext
        
        // delete all entries
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tasks")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            
            try context.execute(deleteRequest)
            
        } catch let error as NSError {
            
            print (error)
        }
        
    }
    
    func fetchCoreDataOnLaunch(){
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        //1
        let context = appDelegate.persistentContainer.viewContext
        
        // delete all entries
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tasks")
        
        do {
            
            taskItems = try context.fetch(fetchRequest) as! [Tasks]
            
            noOfTasksToday = countNumberOfTasksToday()
            
            noOfOverdueTasks = countNumberOfTasksOverdue()
            
//            print("Tasks Today CoreData: \(noOfTasksToday)")
//            print("Tasks Overdue CoreData: \(noOfOverdueTasks)")
            
        } catch let error as NSError {
            
            print (error)
            
        }
        
    }
    
//    func fetchCoreDataForToday(){
//
//        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
//            return
//        }
//
//        //1
//        let context = appDelegate.persistentContainer.viewContext
//
//        //2
////        let yesterday = Date().addingTimeInterval(-1*24*60*60)
////        let tomorrow = Date().addingTimeInterval(1*24*60*60)
//
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tasks")
//
//        do {
//
//            taskItems = try context.fetch(fetchRequest) as! [Tasks]
//
//            noOfTasksToday = countNumberOfTasksToday()
//            //print(noOfTasksToday)
//
//        } catch let error as NSError {
//
//            print (error)
//
//        }
//
//    }
    
    func countNumberOfTasksOverdue() -> Int {
        var count = 0
        
        for aTask in taskItems {
            
            let completed = aTask.completed
            
            if let deadline = aTask.deadline {
                let order = TAFunctions().getDateComparisonResultFromToday(dateToTest: deadline)
                if order == .orderedDescending && completed == false { //yesterday (overdue) and not completed
                    count += 1
                }
            }
        }
        return count
    }
    
    func countNumberOfTasksToday() -> Int {
        
        var count = 0
        
        for aTask in taskItems {
            
            let completed = aTask.completed
            
            if let deadline = aTask.deadline {
                
                let order = TAFunctions().getDateComparisonResultFromToday(dateToTest: deadline)
                
                if order == .orderedSame && completed == false { //same day and not completed
                    
                    count += 1
                    
                }
            }
        }
        
        return count
    }
    
    //MARK: - Actions
    
    @IBAction func viewTasksButtonTapped(_ sender: Any) {

//        if taskItems.isEmpty {
//            TKAlert().createAlert(title: "oops.", message: "add a task first.", buttonTitle: "ok.")
//            //self.navigationController?.popViewController(animated: true)
//        } else {
//            //present(ListViewController(), animated: false, completion: nil)
//        }

    }
    
    @IBAction func calendarSwitchSettingsTapped(_ sender: Any) {
        
        if calendarSwitchView.isOn == true {
            UserDefaults.standard.set(true, forKey: "willSaveToCalendar")
            calendarLabel.textColor = UIColor.white
            EKEventsClass().checkCalendarAuthorizationStatus()
            
        } else if calendarSwitchView.isOn == false {
            UserDefaults.standard.set(false, forKey: "willSaveToCalendar")
            calendarLabel.textColor = UIColor.lightGray
        }
        
    }
    
    // MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let detailVC = segue.destination as? DetailViewController {
            
            if segue.identifier == "mainToDetailToday" {
                detailVC.detailQuery = "today"
                detailVC.detailSegmentId = 1
            }
            
            if segue.identifier == "mainToDetailOverdue" {
                detailVC.detailQuery = "overdue"
                detailVC.detailSegmentId = 1
            }
            
        }
        
        
//        if segue.identifier == "mainToDetailToday" {
//
//            if let detailVC = segue.destination as? DetailViewController {
//
//                detailVC.detailQuery = "today"
//                detailVC.detailSegmentId = 1
//
////                detailVC.detailQuery = "today"
////                detailVC.detailSegmentId = 1
//
////                if (detailVC.tableView) != nil {
////                    detailVC.detailQuery = "today"
////                    detailVC.detailSegmentId = 1
////                }
//
//            }
//
//        }
        
    }
}

extension UIViewController {
    
    func hideNavigationBar(){
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    @objc func swiped(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizer.Direction.right:
                print ("User Swiped Right")
                self.navigationController?.popViewController(animated: true)

            default:
                break;
            }
        }
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
}

extension MainViewController {
    
    //MARK: User Notifications Functions
    
    func createUserNotification (title: String, body: String, identifierNotification: String, triggerDate: Date) {
        
        //TODO: create trigger for 9am the day of the deadline for ALL notifications
        
        let center = UNUserNotificationCenter.current()
        
        //Custom actions
        let completeAction = UNNotificationAction(identifier: "\(identifierNotification)+complete", title: "Complete", options: [])
        
        let remindOneHourAction = UNNotificationAction(identifier: "\(identifierNotification)+oneHourReminder", title: "Remind me in 1 hour", options: [])
        
        let remindTomorrowAction = UNNotificationAction(identifier: "\(identifierNotification)+tomorrowReminder", title: "Remind me tomorrow", options: [])
        
        let category = UNNotificationCategory(identifier: "myCategory", actions: [completeAction,remindOneHourAction,remindTomorrowAction], intentIdentifiers: [], options: [])
        
        center.setNotificationCategories([category])
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "myCategory"
        
        //let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        //Set the trigger
        var triggerDate = Calendar.current.dateComponents([.year,.month,.day, .hour, .minute,.second,], from: triggerDate)
        
        //setting dispatch in the morning of the deadline
        triggerDate.hour = 9
        triggerDate.minute = 00 //01
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,repeats: false)
        
        //let identifier = "UYLLocalNotification"
        let request = UNNotificationRequest(identifier: identifierNotification, content: content, trigger: trigger)
        
        center.add(request, withCompletionHandler: { (error) in
            if error != nil { print("something went wrong!") }
            
        })
        
    }
    
    func convertDeadlineToTriggerDate (deadline: Date, triggerAdjustmentInHours: TimeInterval) -> Date {
        
        let dateToTriggerDeadline = deadline.addingTimeInterval(triggerAdjustmentInHours*60*60)
        
        return dateToTriggerDeadline
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let notificationDate = response.notification.date
        
        let notificationIdentifier = response.actionIdentifier
        
        let notificationIdentifierStringArray = notificationIdentifier.split{$0 == "+"}.map(String.init)
        
        let title = notificationIdentifierStringArray[0]
        
        let body = notificationIdentifierStringArray[1]
        
        let actionIdentifierResponseString = notificationIdentifierStringArray[3]
        
        switch actionIdentifierResponseString
        {
        case "complete":
            
            let detailVC = DetailViewController()
            detailVC.saveComplete(notificationID: notificationIdentifier, isComplete: true)
            
            
        case "oneHourReminder":
            
            let newTriggerDate = convertDeadlineToTriggerDate(deadline: notificationDate, triggerAdjustmentInHours: 1)
            
            createUserNotification(title: title, body: body, identifierNotification: "\(title)", triggerDate: newTriggerDate)
            
        case "tomorrowReminder":
            
            let newTriggerDate = convertDeadlineToTriggerDate(deadline: notificationDate, triggerAdjustmentInHours: 24)
            
            createUserNotification(title: title, body: body, identifierNotification: "ew-\(title)", triggerDate: newTriggerDate)
            
        default:
            return
            
        }
        
        completionHandler()
    }
    
    
}

