//
//  DetailViewController.swift
//  task-list-app
//
//  Created by Joshua Heslin on 7/5/18.
//  Copyright © 2018 Joshua Heslin. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

struct DetailCell {
    var title: String
    var date: Date
    var client: String
    var id: String
    var completed: Bool
    var timerIsOn: Bool
    var timerStart: Date?
    var timerEnd: Date?
    var timerSum: Double?
    
    init(title: String, date: Date, client: String, id: String, completed: Bool, timerIsOn: Bool, timerStart: Date? = nil, timerEnd: Date? = nil, timerSum: Double? = nil) {
        self.title = title
        self.date = date
        self.client = client
        self.id = id
        self.completed = completed
        self.timerIsOn = timerIsOn
        self.timerStart = timerStart
        self.timerEnd = timerEnd
        self.timerSum = timerSum
    }
}

struct WeekdayDetailCell {
    var weekdayId: Int
    var detailArr: DetailCell
}

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var showCompletedButton: UIButton!
    @IBOutlet weak var detailHeaderLabel: UILabel!
    @IBOutlet weak var exportButton: UIButton!
    
    let dateFormat = "dd/MM/yy"
    var taskItems: [Tasks] = []
    var taskItemsBuffer: [Tasks] = [] //buffer for sorting taskItems to Dates
    var detailArr: [DetailCell] = []  //for display
    var showingCompleted = false //default button position
    var timer: Timer?
    var detailQuery = ""
    var detailSegmentId = 0
    let weekdaysHeader: [String] = ["monday.","tuesday.","wednesday.","thursday.","friday.","saturday.","sunday."]
    var weekdayArr: [WeekdayDetailCell] = [] //for display when detailQuery = "this week"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //styleTableView()
        tableView.backgroundView = TAFunctions().styleFullBackgroundTableView()
        tableView.backgroundView?.addSubview(TAFunctions().styleTopBackgroundTableView(view: self))
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        exportButton.isHidden = true
        
        setupUIGestures()
        
        detailHeaderLabel.text = detailQuery + "."

        fetchCoreDataWithDetail(detail: detailQuery)
        appendToDetailArray()
        tableView.reloadData()

        //popView.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if detailQuery == "this week" {
            return weekdaysHeader.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if detailQuery == "this week" {
            return weekdaysHeader[section]
        } else {
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.white
        let headerLabel = UILabel(frame: CGRect(x: 30, y: 0, width:
            tableView.bounds.size.width, height: tableView.bounds.size.height))
        headerLabel.font = UIFont(name: "futura", size: 18)
        headerLabel.textColor = UIColor.lightGray
        headerLabel.text = self.tableView(self.tableView, titleForHeaderInSection: section)
        headerLabel.sizeToFit()
        headerView.alpha = 0.7
        headerView.addSubview(headerLabel)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var count = 0
        
        if detailQuery == "this week" {
            
            if !showingCompleted {
                for item in weekdayArr {
                    if section + 1 == item.weekdayId {
                        if item.detailArr.completed == false {
                            count = count + 1
                        }
                    }
                }
                return count

            } else {
                for item in weekdayArr {
                    if section + 1 == item.weekdayId {
                        count = count + 1
                    }
                }
                return count
            }
        }
        
        if !showingCompleted {
            
            for item in detailArr {
                if item.completed == false {
                    count = count + 1
                }
            }
            if count == 0 { //if tasks is zero, display completed tasks so page is not blank
                //tap button
                showCompletedButton.sendActions(for: .touchUpInside)
                exportButton.isHidden = true
                return detailArr.count
            }
            return count
        
        } else {
            
            return detailArr.count //detailArr.count//taskItems.count

        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath) as! DetailTableViewCell
        
        var title = detailArr[indexPath.row].title
        var client = detailArr[indexPath.row].client
        var deadline = detailArr[indexPath.row].date
        var isCompleted = detailArr[indexPath.row].completed
        var timerSum = detailArr[indexPath.row].timerSum
        var timerIsOn = detailArr[indexPath.row].timerIsOn
        
        if let startTime = detailArr[indexPath.row].timerStart,
            let endTime = detailArr[indexPath.row].timerEnd {
            
            let timerIsOn = detailArr[indexPath.row].timerIsOn
            
            let result = Calendar.current.compare(startTime, to: endTime, toGranularity: .second)
            
            if timerIsOn {
                quickStartTimerFor(indexPath: indexPath)
            }
            
            if let savedTime = detailArr[indexPath.row].timerSum {
                //let totalTime = savedTime + endTime.timeIntervalSince(startTime)
                cell.labelTimer.text = TAFunctions().stringFromTimeInterval(interval: savedTime)
                if result == .orderedAscending {
                    cell.labelTimer.text = TAFunctions().stringFromTimeInterval(interval: savedTime)
                } else {
                    print ("end date is less than start date XX")
                    cell.labelTimer.text = TAFunctions().stringFromTimeInterval(interval: savedTime)
                }
            }
            
        }
        if detailQuery == "this week" {
            
            for item in weekdayArr {
                if indexPath.section == item.weekdayId - 1 {
                    title = item.detailArr.title
                    client = item.detailArr.client
                    deadline = item.detailArr.date
                    isCompleted = item.detailArr.completed
                    timerSum = item.detailArr.timerSum
                    
                    if let startTime = item.detailArr.timerStart,
                        let endTime = item.detailArr.timerEnd {
                        
                        let timerIsOn = item.detailArr.timerIsOn
                        
                        let result = Calendar.current.compare(startTime, to: endTime, toGranularity: .second)
                        
                        if timerIsOn {
                            quickStartTimerFor(indexPath: indexPath)
                        }
                        
                        if let savedTime = item.detailArr.timerSum {
                            //let totalTime = savedTime + endTime.timeIntervalSince(startTime)
                            cell.labelTimer.text = TAFunctions().stringFromTimeInterval(interval: savedTime)
                            if result == .orderedAscending {
                                cell.labelTimer.text = TAFunctions().stringFromTimeInterval(interval: savedTime)
                            } else {
                                print ("end date is less than start date XX")
                                cell.labelTimer.text = TAFunctions().stringFromTimeInterval(interval: savedTime)
                            }
                        }
                        
                    }
                    
                }
            }
            
        }
        
        //format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let deadlineStr = dateFormatter.string(from: deadline)
        
        if isCompleted {
            //assign strikeout
            cell.labelTaskTitle.attributedText = attributeStringWithValue(string: title + ".", attributeValue: 2)
            cell.labelDate.attributedText = attributeStringWithValue(string: deadlineStr, attributeValue: 2)
            cell.clientLabel.attributedText = attributeStringWithValue(string: client + ".", attributeValue: 2)
            if timerSum == 0.0 {
                cell.labelTimer.attributedText = attributeStringWithValue(string: "", attributeValue: 2)
            } else {
                cell.labelTimer.attributedText = attributeStringWithValue(string: TAFunctions().stringFromTimeInterval(interval: timerSum ?? 0.0), attributeValue: 2)
            }
            
        } else if !isCompleted {
            
            //remove strikeout
            cell.labelTaskTitle.attributedText = attributeStringWithValue(string: title + ".", attributeValue: 0)
            cell.labelDate.attributedText = attributeStringWithValue(string: deadlineStr, attributeValue: 0)
            cell.clientLabel.attributedText = attributeStringWithValue(string: client + ".", attributeValue: 0)
            if timerSum == 0.0 {
                cell.labelTimer.attributedText = attributeStringWithValue(string: "", attributeValue: 0)
            } else {
                if timerIsOn {
                    cell.labelTimer.attributedText = attributeStringWithValue(string: "ticking..", attributeValue: 0)
                } else {
                    cell.labelTimer.attributedText = attributeStringWithValue(string: TAFunctions().stringFromTimeInterval(interval: timerSum ?? 0.0), attributeValue: 0)
                }
            }
            
        }
        
        if detailSegmentId == 0 { //clients was selected
            cell.clientLabel.text = ""
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath as IndexPath) as! DetailTableViewCell
        
        var title = detailArr[indexPath.row].title
        var client = detailArr[indexPath.row].client
        var deadline = detailArr[indexPath.row].date
        var identifier = detailArr[indexPath.row].id
        var isCompleted = detailArr[indexPath.row].completed
        let timerSum = detailArr[indexPath.row].timerSum
        let timerIsOn = detailArr[indexPath.row].timerIsOn
        
        if detailQuery == "this week" {
            for item in weekdayArr {
                if indexPath.section == item.weekdayId - 1 {
                    title = item.detailArr.title
                    client = item.detailArr.client
                    deadline = item.detailArr.date
                    identifier = item.detailArr.id
                    isCompleted = item.detailArr.completed
                }
            }
        }
    
        //format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let deadlineStr = dateFormatter.string(from: deadline)
        
        if !isCompleted {
            //assign strikeout
            
            if timerIsOn {
                print ("cannot complete task, timer on")
                let alert = UIAlertController(title: "Timer is running", message: "You cannot complete a task when the timer is running", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                    self.tableView.deselectRow(at: indexPath, animated: true)
                })
                alert.addAction(ok)
                self.present(alert, animated: true)
                
                return
            }
            
            cell.labelTaskTitle.attributedText = attributeStringWithValue(string: title + ".", attributeValue: 2)
            cell.labelDate.attributedText = attributeStringWithValue(string: deadlineStr, attributeValue: 2)
            cell.clientLabel.attributedText = attributeStringWithValue(string: client + ".", attributeValue: 2)
            if !timerIsOn {
                if timerSum == 0.0 {
                    cell.labelTimer.attributedText = attributeStringWithValue(string: "", attributeValue: 2)
                } else {
                    cell.labelTimer.attributedText = attributeStringWithValue(string: TAFunctions().stringFromTimeInterval(interval: timerSum ?? 0.0), attributeValue: 2)
                }
            }

            //isCompleted = true
            saveComplete(notificationID: identifier, isComplete: true)
            updateCompletedValueToDetailArray(identifier: identifier, bool: true)
            updateCompletedValueToWeekdayArray(identifier: identifier, bool: true)
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

            
        } else if isCompleted {
            //remove strikeout
            cell.labelTaskTitle.attributedText = attributeStringWithValue(string: title + ".", attributeValue: 0)
            cell.labelDate.attributedText = attributeStringWithValue(string: deadlineStr, attributeValue: 0)
            cell.clientLabel.attributedText = attributeStringWithValue(string: client + ".", attributeValue: 0)
            if !timerIsOn {
                if timerSum == 0.0 {
                    cell.labelTimer.attributedText = attributeStringWithValue(string: "", attributeValue: 0)
                } else {
                    cell.labelTimer.attributedText = attributeStringWithValue(string: TAFunctions().stringFromTimeInterval(interval: timerSum ?? 0.0), attributeValue: 0)
                }
            }
            
            //isCompleted = false
            saveComplete(notificationID: identifier, isComplete: false)
            updateCompletedValueToDetailArray(identifier: identifier, bool: false)
            updateCompletedValueToWeekdayArray(identifier: identifier, bool: false)
            
            let mainVC = MainViewController()
            mainVC.createUserNotification(title: title, body: client, identifierNotification: identifier, triggerDate: deadline)
            
        }
        
        if detailSegmentId == 0 { //clients was selected
            cell.clientLabel.text = ""
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    
    // MARK: - Functions
    
    func attributeStringWithValue(string: String, attributeValue: Int) -> NSMutableAttributedString {
        let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: string)
        attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: attributeValue, range: NSMakeRange(0, attributeString.length))
        return attributeString
    }
    
    func updateCompletedValueToDetailArray(identifier: String, bool: Bool) {
        for index in 0..<detailArr.count {
            if detailArr[index].id == identifier {
                detailArr[index].completed = bool
            }
        }
    }
    
    func updateCompletedValueToWeekdayArray(identifier: String, bool: Bool) {
        for index in 0..<weekdayArr.count {
            if weekdayArr[index].detailArr.id == identifier {
                weekdayArr[index].detailArr.completed = bool
            }
        }
    }
    
    func sortDetailArrToWeekdayArr() {
        
        if detailQuery == "this week" {
            
            for aTask in detailArr {
                //already filtered tasks for 'this week'
                
                let taskWeekday = Calendar.current.component(.weekday, from: aTask.date)
                let weekdays: [Int] = [1,2,3,4,5,6,7] //1=Sunday
                
                switch (taskWeekday) {
                case weekdays[0]: //Sunday
                    print ("Sunday: \(taskWeekday)")
                    weekdayArr.append(WeekdayDetailCell(weekdayId: taskWeekday, detailArr: aTask))
                    
                case weekdays[1]:
                    print ("Monday: \(taskWeekday)")
                    weekdayArr.append(WeekdayDetailCell(weekdayId: taskWeekday, detailArr: aTask))
                    
                case weekdays[2]:
                    print ("Tues: \(taskWeekday)")
                    weekdayArr.append(WeekdayDetailCell(weekdayId: taskWeekday, detailArr: aTask))
                    
                case weekdays[3]:
                    print ("Wed: \(taskWeekday)")
                    weekdayArr.append(WeekdayDetailCell(weekdayId: taskWeekday, detailArr: aTask))
                    
                case weekdays[4]:
                    print ("Thurs: \(taskWeekday)")
                    weekdayArr.append(WeekdayDetailCell(weekdayId: taskWeekday, detailArr: aTask))
                    
                case weekdays[5]:
                    print ("Fri: \(taskWeekday)")
                    weekdayArr.append(WeekdayDetailCell(weekdayId: taskWeekday, detailArr: aTask))
                    
                case weekdays[6]:
                    print ("Sat: \(taskWeekday)")
                    weekdayArr.append(WeekdayDetailCell(weekdayId: taskWeekday, detailArr: aTask))
                    
                default:
                    print ("default")
                    return
                }

            }
            print (weekdayArr)
            
        } else {
            return
        }
        
    }
    
    func appendToDetailArray() {
        detailArr.removeAll()
        
        switch (detailSegmentId){
        case 0: //client
            for aTask in taskItems {
                
                if let task = aTask.task,
                    let client = aTask.client,
                    let deadline = aTask.deadline,
                    let id = aTask.notificationID
                {
                    let timerBool = aTask.timerIsOn
                    let completed = aTask.completed
                    let timerStart = aTask.timerStart
                    let timerEnd = aTask.timerEnd
                    let timerSum = aTask.timerSum
                    detailArr.append(DetailCell(title: task, date: deadline, client: client, id: id, completed: completed, timerIsOn: timerBool, timerStart: timerStart, timerEnd: timerEnd, timerSum: timerSum))
                }
            }
        case 1: //date
            for aTask in taskItemsBuffer {
                
                if let task = aTask.task,
                    let client = aTask.client,
                    let deadline = aTask.deadline,
                    let id = aTask.notificationID
                {
                    let timerBool = aTask.timerIsOn
                    let completed = aTask.completed
                    let timerStart = aTask.timerStart
                    let timerEnd = aTask.timerEnd
                    let timerSum = aTask.timerSum
                    detailArr.append(DetailCell(title: task, date: deadline, client: client, id: id, completed: completed, timerIsOn: timerBool, timerStart: timerStart, timerEnd: timerEnd, timerSum: timerSum))
                }
            }
            //now sort detailArr in weekdayArr, and dispaly WeekdArr in tableview
            sortDetailArrToWeekdayArr()
        default:
            return
        }
        
        if detailArr.count > 1 {
            detailArr.sort(by: { !$0.completed && $1.completed })
        }
            
    }
    
    func filterTaskItemsForDateDetailQuery(detail: String){
        
        taskItemsBuffer.removeAll()
        
        switch (detail)
        {
            case "overdue":
                for aTask in taskItems {
                    
                    if let deadline = aTask.deadline {
                        
                        let order = TAFunctions().getDateComparisonResultFromToday(dateToTest: deadline)
                        
                        if order == .orderedDescending { //overdue
                            
                            taskItemsBuffer.append(aTask)
                            
                        }
                        
                    }
                    
                }
            case "today":
                for aTask in taskItems {
                    
                    if let deadline = aTask.deadline {
                        
                        let order = TAFunctions().getDateComparisonResultFromToday(dateToTest: deadline)
                        
                        if order == .orderedSame { //same day
                            
                            taskItemsBuffer.append(aTask)
                            
                        }
                    }
                }
            case "this week":
                for aTask in taskItems {
                    
                    if let deadline = aTask.deadline {
                        
                        let order = TAFunctions().getDateComparisonResultFromToday(dateToTest: deadline)
                        
                        if (order == .orderedAscending) && (deadline < Date().addingTimeInterval(7*24*60*60)) { // tomorrow and less than 7 days
                            
                            taskItemsBuffer.append(aTask)
                            
                        }
                    }
                }
            case "future":
                for aTask in taskItems {
    
                    if let deadline = aTask.deadline {
    
                        let order = TAFunctions().getDateComparisonResultFromToday(dateToTest: deadline)
    
                        if (order == .orderedAscending) && (deadline > Date().addingTimeInterval(7*24*60*60))  { // greater than 7 days
    
                            taskItemsBuffer.append(aTask)
    
                        }
                    }
                }
            default:
                return
        }
        
    }

    
    func fetchCoreDataWithDetail(detail: String) {
        
        //1
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        let context = appDelegate.persistentContainer.viewContext

        //2
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Tasks")

        if detailSegmentId == 0 { //fetch for clients
            
            fetchRequest.predicate = NSPredicate(format: "client == %@", detail)
            
        } else if detailSegmentId == 1 { //fetch for dates
            
            //no predicate required
    
        }

        //3
        do {

            taskItems = try context.fetch(fetchRequest) as! [Tasks]
        
            if taskItems.count > 2 {
                taskItems.sort(by: { ($0.deadline! < $1.deadline!) }) //sorts in ascending order
            }
            
            filterTaskItemsForDateDetailQuery(detail: detail)

        } catch let error as NSError {

            print ("Could not fetch. \(error), \(error.userInfo)")

        }
        
    }
    
    func saveComplete(notificationID: String, isComplete: Bool){
        
        //1
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Tasks")
        
        fetchRequest.predicate = NSPredicate(format: "notificationID = %@", notificationID)
        
        //3
        do {
            
            taskItems = try context.fetch(fetchRequest) as! [Tasks]
            
            if taskItems.count > 0 { //only proceed if found a task with notificationID
                
                for aTask in taskItems {
                    
                    //MARK: update result
                    aTask.setValue(isComplete, forKey: "completed")
                    
                    do {
                        
                        try context.save()
                        
                        //print("completed mark set in core data")
                        
                    } catch let error as NSError {
                        
                        print("Could not save. \(error), \(error.userInfo)")
                        
                    }
                    
                }
                
            }
            
        } catch let error as NSError {
            
            print ("Could not fetch. \(error), \(error.userInfo)")
            
        }
        
    }
    
    func restartTimerForWeekdayDetailArr(detailItem: DetailCell){
        let identifier = detailItem.id
        for index in 0..<weekdayArr.count {
            if weekdayArr[index].detailArr.id == identifier {
                weekdayArr[index].detailArr.timerSum = 0
            }
        }
    }
    
    func updateWeekDayDetailArr(identifier: String, forKey: String, time: Date, totalTimeIntervalOnStop: Double? = nil) {
        for index in 0..<weekdayArr.count {
            if weekdayArr[index].detailArr.id == identifier {
                if forKey == "start" {
                    weekdayArr[index].detailArr.timerStart = time
                } else if forKey == "end" {
                    weekdayArr[index].detailArr.timerEnd = time
                    weekdayArr[index].detailArr.timerSum = totalTimeIntervalOnStop
                } else {
                    print ("wrong key passed to update detailArry for timer")
                }
            }
        }
    }
    
    func restartTimerForDetailArr(detailItem: DetailCell){
        let identifier = detailItem.id
        for index in 0..<detailArr.count {
            if detailArr[index].id == identifier {
                detailArr[index].timerSum = 0
            }
        }
    }
    
    func updateDetailArr(identifier: String, forKey: String, time: Date, totalTimeIntervalOnStop: Double? = nil, timerIsOn: Bool) {
        for index in 0..<detailArr.count {
            if detailArr[index].id == identifier {
                if forKey == "start" {
                    detailArr[index].timerStart = time
                } else if forKey == "end" {
                    detailArr[index].timerEnd = time
                    detailArr[index].timerSum = totalTimeIntervalOnStop
                } else {
                    print ("wrong key passed to update detailArry for timer")
                }
                detailArr[index].timerIsOn = timerIsOn
            }
        }
    }
    
    func getTaskForActiveTimer() -> Tasks? {
        
        //1
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }
        let context = appDelegate.persistentContainer.viewContext
        //2
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Tasks")
        
        fetchRequest.predicate = NSPredicate(format: "timerIsOn = YES")
        
        //3
        do {
            taskItems = try context.fetch(fetchRequest) as! [Tasks]
            //print ("do try getActiveTimer")
            if taskItems.count > 0 { //only proceed if found a task with timerIsOn
                for aTask in taskItems {
                    if aTask.timerIsOn {
                        print ("there is an active timer")
                        //only returning the first timer.
                        return aTask
                    }
                }
            }
        } catch let error as NSError {
            print ("Could not fetch. \(error), \(error.userInfo)")
        }
        return nil
    }
    
    func deleteTimerInfoCoreData(detailItem: DetailCell){
        let taskId = detailItem.id
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Tasks")
        fetchRequest.predicate = NSPredicate(format: "notificationID = %@", taskId)
        do {
            taskItems = try context.fetch(fetchRequest) as! [Tasks]
            if taskItems.count > 0 { //only proceed if found a task with notificationID
                for aTask in taskItems {
                    //MARK: update result
                    aTask.setValue(0.00, forKey: "timerSum")
                    aTask.setValue(nil, forKey: "timerStart")
                    aTask.setValue(nil, forKey: "timerEnd")
                    
                    do {
                        try context.save()
                        print("completed delete timer info in core data")
                    } catch let error as NSError {
                        print("Could not save. \(error), \(error.userInfo)")
                    }
                }
            }
        } catch let error as NSError {
            print ("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func updateTimerTimeIntervalCoreData(detailItemId: String, timerSum: Double){

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Tasks")
        fetchRequest.predicate = NSPredicate(format: "notificationID = %@", detailItemId)
        do {
            taskItems = try context.fetch(fetchRequest) as! [Tasks]
            
            if taskItems.count > 0 { //only proceed if found a task with notificationID
                for aTask in taskItems {
                    
                    let storedTimerSum = aTask.timerSum
                    let timerSumToSave = timerSum + storedTimerSum
                    
                    //MARK: update result
                    aTask.setValue(timerSumToSave, forKey: "timerSum")
                    
                    do {
                        try context.save()
                        print("completed save timerSum interval in core data")
                        
                    } catch let error as NSError {
                        print("Could not save. \(error), \(error.userInfo)")
                    }
                }
            }
        } catch let error as NSError {
            print ("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func saveTimerForTaskCoreData(attributeKey: String, detailItemId: String, timerIsOn: Bool, time: Date) {
        
        //1
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        //2
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Tasks")
        
        fetchRequest.predicate = NSPredicate(format: "notificationID = %@", detailItemId)
        
        //3
        do {
            taskItems = try context.fetch(fetchRequest) as! [Tasks]
            
            if taskItems.count > 0 { //only proceed if found a task with notificationID
                for aTask in taskItems {
                    
                    //MARK: update result
                    aTask.setValue(timerIsOn, forKey: "timerIsOn")
                    aTask.setValue(time, forKey: attributeKey)

                    do {
                        try context.save()
                        print("completed save timer bool/timer in core data")
                        
                    } catch let error as NSError {
                        print("Could not save. \(error), \(error.userInfo)")
                    }
                }
            }
        } catch let error as NSError {
            print ("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func calculateTimeIntervalForIndexPath(indexPath: IndexPath) -> Double? {
        let cell = tableView.cellForRow(at: indexPath) as! DetailTableViewCell
        if detailQuery == "this week" {
            for item in weekdayArr {
                if cell.labelTaskTitle.text == "\(item.detailArr.title)." {
                    if let ti = item.detailArr.timerStart?.timeIntervalSinceNow {
                        print ("timeinterval: \(ti)")
                        if let timerSum = item.detailArr.timerSum {
                            print ("original sum: \(timerSum)")
                            return abs(timerSum) + abs(ti)
                        } else {
                            return abs(ti)
                        }
                    }
                }
            }
        } else {
            for item in detailArr {
                if cell.labelTaskTitle.text == "\(item.title)." {
                    if let ti = item.timerStart?.timeIntervalSinceNow {
                        print ("timeinterval: \(ti)")
                        if let timerSum = item.timerSum {
                            print ("original sum: \(timerSum)")
                            return abs(timerSum) + abs(ti)
                        } else {
                            return abs(ti)
                        }
                    }
                }
            }
        }
        return nil
    }
    
    @objc func fireTimer(timer: Timer) {
        //print("fireTimer fired")
        guard let indexPath = timer.userInfo as? IndexPath else { return }

        print("Timer fired by \(indexPath)")
        
        let cell = tableView.cellForRow(at: indexPath) as! DetailTableViewCell
        //TODO may crash here because time fired on completed cell that doesn't exist
        
        if let timeInterval = calculateTimeIntervalForIndexPath(indexPath: indexPath) {
            cell.labelTimer.text = TAFunctions().stringFromTimeInterval(interval: timeInterval)
        }
    }
    
    func startTimerFor(detailItem: DetailCell, indexPath: IndexPath) {
        //let taskId = detailItem.id
        //let context: [String : IndexPath] = [taskId : indexPath]
        
        saveTimerForTaskCoreData(attributeKey: "timerStart", detailItemId: detailItem.id, timerIsOn: true, time: Date())
        updateDetailArr(identifier: detailItem.id, forKey: "start", time: Date(), timerIsOn: true)
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: indexPath, repeats: true)
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    func quickStartTimerFor(indexPath: IndexPath) {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: indexPath, repeats: true)
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    func stopTimerFor(detailItem: DetailCell, tappedIndexPath: IndexPath){
        //let taskId = detailItem.id
        //let context: [String : IndexPath] = [taskId : indexPath]
        print ("stoping timer for \(tappedIndexPath)")
        guard let indexPath = timer?.userInfo as? IndexPath else { return }
        if tappedIndexPath == indexPath {
            timer!.invalidate()
            print ("timer stopped")
            saveTimerForTaskCoreData(attributeKey: "timerEnd", detailItemId: detailItem.id, timerIsOn: false, time: Date())
            if let dateStart = detailItem.timerStart {
                let timeIntervalOnStop = Double(Date().timeIntervalSince1970 - dateStart.timeIntervalSince1970)
                updateTimerTimeIntervalCoreData(detailItemId: detailItem.id, timerSum: timeIntervalOnStop)
                let originalTimerSum = detailItem.timerSum ?? 0.0
                if detailQuery == "this week"{
                    updateWeekDayDetailArr(identifier: detailItem.id, forKey: "end", time: Date(), totalTimeIntervalOnStop: timeIntervalOnStop + originalTimerSum)
                } else {
                    updateDetailArr(identifier: detailItem.id, forKey: "end", time: Date(), totalTimeIntervalOnStop: timeIntervalOnStop + originalTimerSum, timerIsOn: false)
                }
            }
        }
    }
    
    func stopTimersWhenNotDisplayedOnTable(activeTask: Tasks){
        if let taskID = activeTask.notificationID,
            let dateStart = activeTask.timerStart,
            let id = activeTask.notificationID {
            
            timer?.invalidate()
            
            saveTimerForTaskCoreData(attributeKey: "timerEnd", detailItemId: taskID, timerIsOn: false, time: Date())
                
            let timeIntervalOnStop = Double(Date().timeIntervalSince1970 - dateStart.timeIntervalSince1970)
            updateTimerTimeIntervalCoreData(detailItemId: id, timerSum: timeIntervalOnStop)
            
            let originalTimerSum = activeTask.timerSum
            updateDetailArr(identifier: id, forKey: "end", time: Date(), totalTimeIntervalOnStop: timeIntervalOnStop + originalTimerSum, timerIsOn: false)
        }
    }
    
    func restartTimer(detailItem: DetailCell, indexPath: IndexPath) {
        deleteTimerInfoCoreData(detailItem: detailItem)
        if detailQuery == "this week" {
            restartTimerForWeekdayDetailArr(detailItem: detailItem)
        } else {
            restartTimerForDetailArr(detailItem: detailItem)
        }
        //updateDetailArr(identifier: detailItem.id, forKey: "start", time: nil, totalTimeIntervalOnStop: 0.00)
        //updateDetailArr(identifier: detailItem.id, forKey: "end", time: nil)
        let cell = tableView.cellForRow(at: indexPath) as! DetailTableViewCell
        cell.labelTimer.text = TAFunctions().stringFromTimeInterval(interval: 0)
        
        startTimerFor(detailItem: detailItem, indexPath: indexPath)
    }

    func showTimerAlert(tappedDetailItem: DetailCell, tappedIndexPath: IndexPath) {
        
        guard detailQuery != "this week" else {
            let alert = UIAlertController(title: "Sorry", message: "The app does not support timers for tasks in 'this week' yet.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true)
            return
        }

        
        if let activeTask = getTaskForActiveTimer() { //there could be none
            
            //first check if the same cell was tapped, if so, show option to stop time
            if (activeTask.notificationID == tappedDetailItem.id) {
                
                print ("timer is already on")
                let alert = UIAlertController(title: tappedDetailItem.title + ".", message: "Timer is already on. Stop Timer?", preferredStyle: .alert)
                let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let stopTimer = UIAlertAction(title: "Stop Timer", style: .default) { _ in
                    print ("stoping timer...")
                    self.stopTimerFor(detailItem: tappedDetailItem, tappedIndexPath: tappedIndexPath)
                }
                alert.addAction(cancel)
                alert.addAction(stopTimer)
                
                self.present(alert, animated: true)
                
            } else { //a new cell was tapped and there cannot be two times, show alert
                let alert = UIAlertController(title: "Timer is already running. You cannot run two timers at once.", message: "Stop current timer and start new timer on this task?", preferredStyle: .alert)
                let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
//                let startTimer = UIAlertAction(title: "Start New Timer", style: .default) { _ in
//                    print ("starting new timer...")
//                    self.startTimerFor(detailItem: tappedDetailItem, indexPath: tappedIndexPath)
//                }
                let stopAllTimers = UIAlertAction(title: "Stop All Timers", style: .default) { _ in
                    print ("stoping all timers...")
                    
                    self.stopTimersWhenNotDisplayedOnTable(activeTask: activeTask)
                }
                alert.addAction(cancel)
                //alert.addAction(startTimer)
                alert.addAction(stopAllTimers)
                
                self.present(alert, animated: true)
                
            }
            
        } else { // no active timer's running for Tasks, start the time
            
            //check is there is a previous time, allow for restart or append new time here
            
            let alert = UIAlertController(title: tappedDetailItem.title + ".", message: "Start Timer?", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.addAction(cancel)
            
            if tappedDetailItem.timerStart != nil {
                print("start date exists")
                let continueTimer = UIAlertAction(title: "Continue Timer", style: .default) { _ in
                    print ("continue timer...")
                    if tappedDetailItem.completed {
                        TAAlerts().createAlert(title: "Cannot start timer on completed task", message: "Please uncomplete the task to restart timer", buttonTitle: "OK", view: self)
                    } else {
                        self.startTimerFor(detailItem: tappedDetailItem, indexPath: tappedIndexPath)
                    }
                    
                }
                let restartTimer = UIAlertAction(title: "Restart Timer", style: .default) { _ in
                    print ("clearing start date time")
                    //clear timerSum and startTime
                    if tappedDetailItem.completed {
                        TAAlerts().createAlert(title: "Cannot start timer on completed task", message: "Please uncomplete the task to restart timer", buttonTitle: "OK", view: self)
                    } else {
                            self.restartTimer(detailItem: tappedDetailItem, indexPath: tappedIndexPath)
                    }
                }
                alert.addAction(continueTimer)
                alert.addAction(restartTimer)
                
            } else {
                print("start date does not exist")
                let startTimer = UIAlertAction(title: "Start Timer", style: .default) { _ in
                    print ("starting timer...")
                    if tappedDetailItem.completed {
                        TAAlerts().createAlert(title: "Cannot start timer on completed task", message: "Please uncomplete the task to start timer", buttonTitle: "OK", view: self)
                    } else {
                        self.startTimerFor(detailItem: tappedDetailItem, indexPath: tappedIndexPath)
                    }
                }
                alert.addAction(startTimer)
            }
            self.present(alert, animated: true)
            
        }
    
    }
    
    @objc func longPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            
            let touchPoint = longPressGestureRecognizer.location(in: self.tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
                
                print ("long press fired for \(indexPath)")
                print (detailArr[indexPath.row])
                
                showTimerAlert(tappedDetailItem: detailArr[indexPath.row], tappedIndexPath: indexPath)
                
            }
        }
    }
    
    func setupUIGestures() {
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped(gesture:)))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        self.view.addGestureRecognizer(swipeRight)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        longPressRecognizer.minimumPressDuration = 1.0
        self.tableView.addGestureRecognizer(longPressRecognizer)
    }
    
    //MARK: - Actions
    
    @IBAction func showCompletedButtonTapped(_ sender: Any) {
        
        if !showingCompleted {
            //should show completed
            showCompletedButton.setTitle("hide completed.", for: .normal)
            showingCompleted.negate()
            
            exportButton.isHidden = false
            
        } else if showingCompleted {
            //should hide completed
            showCompletedButton.setTitle("show completed.", for: .normal)
            showingCompleted.negate()
            
            exportButton.isHidden = true
        }
        
        tableView.reloadData()
        
    }
    
    @IBAction func exportButtonTapped(_ sender: Any) {
        
        //format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        
        var activityItems: String = """
            TASKA Export \n
            Tasks for: \(detailQuery) \n
            Tasks:\n
            """
        
        for task in detailArr {
            let deadline = dateFormatter.string(from: task.date)
            var timeTaken = ""
            var completed = ""
            if let timerSum = task.timerSum {
                timeTaken = TAFunctions().stringFromTimeInterval(interval: timerSum)
            }
            if task.completed {
                completed = "Completed"
            } else {
                completed = "Uncompleted"
            }
            activityItems.append("""
                \(task.title),  \(task.client), \(deadline), \(completed), Time taken: \(timeTaken) \n
                """)
        }
        
        let activityViewController = UIActivityViewController(activityItems: [activityItems as Any], applicationActivities: [])
        present(activityViewController, animated: true, completion: {})
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension Bool {
    mutating func negate() {
        self = !self
    }
}
