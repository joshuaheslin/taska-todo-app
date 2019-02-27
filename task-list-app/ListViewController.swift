//
//  ListViewController.swift
//  task-list-app
//
//  Created by Joshua Heslin on 7/5/18.
//  Copyright © 2018 Joshua Heslin. All rights reserved.
//

import UIKit
import CoreData

struct ClientItems {
    var qtyUncompleted: Int
    var client: String
}

struct ClientCountList {
    var client: String
    var completed: Bool
}

struct DateItems {
    var qty: Int
    var type: String
}

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
    var taskItems: [Tasks] = []
    
    var clientItems: [ClientItems] = [] //for Display
    
    var dateItems: [DateItems] = [] //for Display
    
    var clientCountList: [ClientCountList] = [] //for filtering from taskItems
    
    var segmentControlIndex = 0 //bc it's initally set to 0 in custom class
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var showCompletedButton: UIButton!
    
    var showingCompleted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        styleTableView()
        
        fetchCoreData() //must call fetchCoreData before sortDate
        sortDateItems()
        sortClientItems()
        tableView.reloadData()
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped(gesture:)))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        self.view.addGestureRecognizer(swipeRight)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        fetchCoreData()
        sortDateItems()
        sortClientItems()
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table View
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (segmentControlIndex) {
        case 0:
            if !showingCompleted {
                var count = 0
                for item in clientItems {
                    if item.qtyUncompleted != 0 {
                        count = count + 1
                    }
                }
                return count
            } else {
                return clientItems.count
            }
        case 1:
            return dateItems.count
        default:
            return 1;
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "listCell", for: indexPath) as! ListTableViewCell
        
        switch (segmentControlIndex) {
        case 0:
            if clientItems[indexPath.row].qtyUncompleted == 0 {
                cell.labelTop.textColor = UIColor.darkGray
                cell.labelBottom.textColor = UIColor.darkGray
            } else {
                cell.labelTop.textColor = UIColor.black
                cell.labelBottom.textColor = UIColor.black
            }
            cell.labelTop.text = "you have \(clientItems[indexPath.row].qtyUncompleted) tasks for"
            cell.labelBottom.text = clientItems[indexPath.row].client + "."
            
        case 1:
            // do the by date. part
            if dateItems[indexPath.row].qty == 0 {
                cell.labelTop.textColor = UIColor.darkGray
                cell.labelBottom.textColor = UIColor.darkGray
            } else {
                cell.labelTop.textColor = UIColor.black
                cell.labelBottom.textColor = UIColor.black
            }
            cell.labelTop.text = "you have \(dateItems[indexPath.row].qty) tasks due"
            cell.labelBottom.text = dateItems[indexPath.row].type + "."
            
            if dateItems[indexPath.row].type == "future" {
                cell.labelBottom.text = "in more than a week."
            }
        default:
            break;
        }
        
        
        
        /*
         by date.
         
         you have 2 tasks due
         overdue.
         
         today.
         
         tomorrow.
         
         this week.
         
         more than a week.
         
        */
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
    }
    

    
    // MARK: - Functions
    
    @IBAction func segmentControlChanged(_ sender: CustomSegementControl) {
        
        segmentControlIndex = sender.selectedSegementIndex
        
        UIView.transition(with: tableView,
                                  duration: 0.35,
                                  options: .transitionCrossDissolve,
                                  animations:
            { () -> Void in
                self.tableView.reloadData()
        },
                                  completion: nil);
        if segmentControlIndex == 1 {
            showCompletedButton.isEnabled = false
        } else {
            showCompletedButton.isEnabled = true
        }
        
    }
    
    func fetchCoreData() {
        
        taskItems.removeAll()
        
        //1
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Tasks")
        
        //3
        do {
            
            taskItems = try context.fetch(fetchRequest) as! [Tasks]
            
        } catch let error as NSError {
            
            print ("Could not fetch. \(error), \(error.userInfo)")
            
        }
        
    }
    
    func sortClientItems(){
        
        clientCountList.removeAll()
        clientItems.removeAll()
        
        var clientList: [String] = []
        var counts: [String: Int] = [:]
        
        //put all tasks into a simple array for counting
        for task in taskItems {
            if let client = task.client{
                let isCompleted = task.completed
                clientCountList.append(ClientCountList(client: client, completed: isCompleted))
                clientList.append(client)
            }
        }
        
        for item in clientList {
            counts[item] = (counts[item] ?? 0) + 1
        }
        
        for (client, count) in counts {
            //print("\(client) occurs \(count) time(s)") //count is total number of tasks for client
            
            var countUncompletedTasks = 0
            
            for clientLong in clientCountList {
                
                if client == clientLong.client {
                    
                    if !clientLong.completed {
                        countUncompletedTasks = countUncompletedTasks + 1
                    }
                    
                }
                
            }
            //print ("client: " + client)
            //print ("uncom-count: \(countUncompletedTasks)")
            clientItems.append(ClientItems(qtyUncompleted: countUncompletedTasks, client: client))
        }
        
        clientItems.sort { Int($0.qtyUncompleted) > Int($1.qtyUncompleted)  }
        
//        let arr = [["id": 2], ["id": 59], ["id": 31]]
//
//        let sortedArr = arr.sort { Int($0["id"]!) > Int($1["id"]!) }
        
    }
    
    func sortDateItems(){
        
        dateItems.removeAll()

        var overdue: [TimeInterval] = []
        var today: [TimeInterval] = []
        var thisWeek: [TimeInterval] = []
        var future: [TimeInterval] = []
        
        for task in taskItems {
            
            if let deadline = task.deadline?.timeIntervalSinceNow {
                
                if let deadlineDate = task.deadline {
                    
                    let order = TAFunctions().getDateComparisonResultFromToday(dateToTest: deadlineDate)
                    
                    let dateInSevenDaysTime = Calendar.current.date(byAdding: .day, value: 6, to: deadlineDate)
                    
                    if task.completed { //TODO
                        //do nothing atm
                    } else if (order == .orderedDescending) { //overdue
                        //print("elif: overdue")
                        overdue.append(deadline)
                        
                    } else if (order == .orderedSame) {  //today
                        //print("elif: today")
                        today.append(deadline)
                        
                    } else if (order == .orderedAscending) && (deadlineDate < dateInSevenDaysTime!) { //due in 7 days //(deadlineDate > Date().addingTimeInterval(24*60*60)
                        //print("elif: this week")
                        thisWeek.append(deadline)
                        
                    } else if (order == .orderedAscending) && (deadlineDate > dateInSevenDaysTime!) { //due in future
                        //print("future")
                        future.append(deadline)
                        
                    } else {
                        //print("nothing")
                    }
                    
                }
                
            }
            
        }
        
        dateItems.append(DateItems(qty: overdue.count, type: "overdue"))
        dateItems.append(DateItems(qty: today.count, type: "today"))
        dateItems.append(DateItems(qty: thisWeek.count, type: "this week"))
        dateItems.append(DateItems(qty: future.count, type: "future"))
        //note: dateItems.type will be the displayed label also
        
    }
    
    
    @IBAction func showCompletedButtonTapped(_ sender: Any) {
        
        if !showingCompleted {
            //should show completed
            showCompletedButton.setTitle("hide completed.", for: .normal)
            showingCompleted.negate()
            
        } else if showingCompleted {
            //should hide completed
            showCompletedButton.setTitle("show completed.", for: .normal)
            showingCompleted.negate()
        }
        
        tableView.reloadData()
        
    }
    
    func styleTableView(){
        
        let fullBackgroundView = UIView() //it will resize regardless
        fullBackgroundView.backgroundColor = UIColor.white
        
        let topBackgroundRect = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height/9)
        let topBackgroundView = UIView(frame: topBackgroundRect)
        
        let color = UIColor(white: 0.90, alpha: 0.2)
        topBackgroundView.backgroundColor = color
        
        self.tableView.backgroundView = fullBackgroundView
        self.tableView.backgroundView?.addSubview(topBackgroundView)
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "toDetail" ,
            let detailVC = segue.destination as? DetailViewController ,
            let indexPath = self.tableView.indexPathForSelectedRow
            {
            
            var detail = ""
            var detailID = 0
            
            switch (segmentControlIndex) {
            case 0:
                detail = clientItems[indexPath.row].client
                detailID = 0
            case 1:
                detail = dateItems[indexPath.row].type
                detailID = 1
            default:
                return ;
            }

            detailVC.detailQuery = detail
            detailVC.detailSegmentId = detailID
            
        }
     
    }
    
}

extension UIViewController {
    
//    func getDateOrderingFromToday(dateToTest: Date)-> ComparisonResult {
//
//        let nowDate = Date()
//
//        //for comparing if deadline is today
//        let result = Calendar.current.compare(nowDate, to: dateToTest, toGranularity: .day)
//
////        switch result {
////        case .orderedAscending:
////            print("\(dateToTest) is after \(nowDate)")
////        case .orderedDescending:
////            print("\(dateToTest) is before \(nowDate)")
////        default:
////            print("\(dateToTest) is the same as \(nowDate)")
////            //append to today array
////            //today.append(deadline)
////        }
//
//        return result
//    }
    
}
