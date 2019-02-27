//
//  TaskViewController.swift
//  task-list-app
//
//  Created by Joshua Heslin on 7/5/18.
//  Copyright © 2018 Joshua Heslin. All rights reserved.
//

import UIKit
import CoreData

var titleArr = ["do your chores","make a video"]

var clientsArr = ["josh heslin","kiel wode","napa","harbour town","harbour town sarah","harbour town","harbour town","harbour town","harbour town"]

class TaskViewController: UIViewController, UITextFieldDelegate {
    
    let ekclass = EKEventsClass()
    
    var tasks: [Tasks] = []
    
    var titleArray: [String] = []
    
    var autoCompletionPossibilities2 = [""]
    var autoCompleteCharacterCount2 = 0
    var timer2 = Timer()
    
    var clientsArray: [String] = []
    
    var autoCompletionPossibilities = [""]
    var autoCompleteCharacterCount = 0
    var timer = Timer()
    
    @IBOutlet weak var titleField: UITextField!

    @IBOutlet weak var clientField: UITextField!
    
    @IBOutlet weak var dateField: UITextField!
    
    var dateBuffer = Date()
    
    var pickerView = UIPickerView()
    
    var toolbar = UIToolbar()
    
    var datePicker = UIDatePicker()
    
    let taskDateFormat = "dd/MM/yy h:mm"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.hideKeyboardWhenTappedAroundCustom()
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped(gesture:)))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        self.view.addGestureRecognizer(swipeRight)
        
        fetchCoreData() //must call Fetch before Sort

        sortCoreDataIntoArrays() //string arrays for auto complete text fields
        
        //TODO assign textfield autocomplete string arrary from core data

        autoCompletionPossibilities = clientsArray
        autoCompletionPossibilities2 = titleArray
        
        let now = Date()
        
        dateField.inputView = datePicker
        datePicker.date = now
        datePicker.addTarget(self, action: #selector(datePickerChanged(picker:)), for: .valueChanged)
        datePicker.minimumDate = now
        datePicker.minuteInterval = 15

    }
    
    func hideKeyboardWhenTappedAroundCustom() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboardCustom))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboardCustom() {
        clientField.textColor = UIColor.darkGray
        titleField.textColor = UIColor.darkGray
        view.endEditing(true)
    }
    
    
    @objc func datePickerChanged(picker: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = taskDateFormat
        dateField.text = dateFormatter.string(from: picker.date)
        dateBuffer = picker.date //prepare for coredata save
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        clientField.textColor = UIColor.darkGray
        titleField.textColor = UIColor.darkGray
        return true
    }
    
    // MARK: - Textfield delegate for client field
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool { //1
        if textField == titleField {
            
            var subString2 = (textField.text!.capitalized as NSString).replacingCharacters(in: range, with: string) // 2
            subString2 = formatSubstring2(subString: subString2)
            
            if subString2.count == 0 { // 3 when a user clears the textField
                resetValues2()
            } else {
                searchAutocompleteEntriesWIthSubstring2(substring: subString2) //4
            }

            
        } else if textField == clientField {
            var subString = (textField.text!.capitalized as NSString).replacingCharacters(in: range, with: string) // 2
            subString = formatSubstring(subString: subString)
            
            if subString.count == 0 { // 3 when a user clears the textField
                resetValues()
            } else {
                searchAutocompleteEntriesWIthSubstring(substring: subString) //4
            }
            
        } else {
            return true
        }
        return true
    }
    
    func formatSubstring(subString: String) -> String {
        let formatted = String(subString.dropLast(autoCompleteCharacterCount)).lowercased()//.capitalised //5
        return formatted
    }
    func formatSubstring2(subString: String) -> String {
        let formatted = String(subString.dropLast(autoCompleteCharacterCount2)).lowercased()//.capitalised //5
        return formatted
    }

    func resetValues() {
        autoCompleteCharacterCount = 0
        clientField.text = ""
    }
    func resetValues2() {
        autoCompleteCharacterCount2 = 0
        titleField.text = ""
    }
    
    func searchAutocompleteEntriesWIthSubstring(substring: String) {
        let userQuery = substring
        let suggestions = getAutocompleteSuggestions(userText: substring) //1
        
        if suggestions.count > 0 {
            timer = .scheduledTimer(withTimeInterval: 0.01, repeats: false, block: { (timer) in //2
                let autocompleteResult = self.formatAutocompleteResult(substring: substring, possibleMatches: suggestions) // 3
                self.putColourFormattedTextInTextField(autocompleteResult: autocompleteResult, userQuery : userQuery) //4
                self.moveCaretToEndOfUserQueryPosition(userQuery: userQuery) //5
            })
        } else {
            timer = .scheduledTimer(withTimeInterval: 0.01, repeats: false, block: { (timer) in //7
                self.clientField.text = substring
            })
            autoCompleteCharacterCount = 0
        }
    }
    func searchAutocompleteEntriesWIthSubstring2(substring: String) {
        let userQuery = substring
        let suggestions = getAutocompleteSuggestions2(userText: substring) //1
        
        if suggestions.count > 0 {
            timer2 = .scheduledTimer(withTimeInterval: 0.01, repeats: false, block: { (timer) in //2
                let autocompleteResult = self.formatAutocompleteResult2(substring: substring, possibleMatches: suggestions) // 3
                self.putColourFormattedTextInTextField2(autocompleteResult: autocompleteResult, userQuery : userQuery) //4
                self.moveCaretToEndOfUserQueryPosition2(userQuery: userQuery) //5
            })
        } else {
            timer2 = .scheduledTimer(withTimeInterval: 0.01, repeats: false, block: { (timer) in //7
                self.titleField.text = substring
            })
            autoCompleteCharacterCount2 = 0
        }
    }
    
    
    func getAutocompleteSuggestions(userText: String) -> [String]{
        var possibleMatches: [String] = []
        for item in autoCompletionPossibilities { //2
            let myString:NSString! = item as NSString
            let substringRange :NSRange! = myString.range(of: userText)
            
            if (substringRange.location == 0)
            {
                possibleMatches.append(item)
            }
        }
        return possibleMatches
    }
    func getAutocompleteSuggestions2(userText: String) -> [String]{
        var possibleMatches: [String] = []
        for item in autoCompletionPossibilities2 { //2
            let myString:NSString! = item as NSString
            let substringRange :NSRange! = myString.range(of: userText)
            
            if (substringRange.location == 0)
            {
                possibleMatches.append(item)
            }
        }
        return possibleMatches
    }
    
    func putColourFormattedTextInTextField(autocompleteResult: String, userQuery : String) {
        let colouredString: NSMutableAttributedString = NSMutableAttributedString(string: userQuery + autocompleteResult)
        colouredString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.lightGray /*was green*/, range: NSRange(location: userQuery.count,length:autocompleteResult.count))
        self.clientField.attributedText = colouredString
    }
    func moveCaretToEndOfUserQueryPosition(userQuery : String) {
        if let newPosition = self.clientField.position(from: self.clientField.beginningOfDocument, offset: userQuery.count) {
            self.clientField.selectedTextRange = self.clientField.textRange(from: newPosition, to: newPosition)
        }
        let selectedRange: UITextRange? = clientField.selectedTextRange
        clientField.offset(from: clientField.beginningOfDocument, to: (selectedRange?.start)!)
    }
    func formatAutocompleteResult(substring: String, possibleMatches: [String]) -> String {
        var autoCompleteResult = possibleMatches[0]
        autoCompleteResult.removeSubrange(autoCompleteResult.startIndex..<autoCompleteResult.index(autoCompleteResult.startIndex, offsetBy: substring.count))
        autoCompleteCharacterCount = autoCompleteResult.count
        return autoCompleteResult
    }
    
    
    func putColourFormattedTextInTextField2(autocompleteResult: String, userQuery : String) {
        let colouredString: NSMutableAttributedString = NSMutableAttributedString(string: userQuery + autocompleteResult)
        colouredString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.lightGray /*was green*/, range: NSRange(location: userQuery.count,length:autocompleteResult.count))
        self.titleField.attributedText = colouredString
    }
    func moveCaretToEndOfUserQueryPosition2(userQuery : String) {
        if let newPosition = self.titleField.position(from: self.titleField.beginningOfDocument, offset: userQuery.count) {
            self.titleField.selectedTextRange = self.titleField.textRange(from: newPosition, to: newPosition)
        }
        let selectedRange: UITextRange? = titleField.selectedTextRange
        titleField.offset(from: titleField.beginningOfDocument, to: (selectedRange?.start)!)
    }
    func formatAutocompleteResult2(substring: String, possibleMatches: [String]) -> String {
        var autoCompleteResult = possibleMatches[0]
        autoCompleteResult.removeSubrange(autoCompleteResult.startIndex..<autoCompleteResult.index(autoCompleteResult.startIndex, offsetBy: substring.count))
        autoCompleteCharacterCount2 = autoCompleteResult.count
        return autoCompleteResult
    }
    

    
    // MARK: - Functions
    
    func createAlert(title: String, message: String, buttonTitle: String){
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let button = UIAlertAction(title: buttonTitle, style: .cancel, handler: nil)
        
        alert.addAction(button)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func sortCoreDataIntoArrays() {
        
        titleArray.removeAll()
        clientsArray.removeAll()
        
        for task in tasks {
            if let task = task.task {
                titleArray.append(task)
            }
            if let client = task.client {
                clientsArray.append(client)
            }
        }

    }
    
    func fetchCoreData(){
        //1
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Tasks")
        
        //3
        do {
            
            tasks = try context.fetch(fetchRequest) as! [Tasks]
            
        } catch let error as NSError {
            
            print ("Could not fetch. \(error), \(error.userInfo)")
            
        }
    }
    
    func addTaskToCoreData(taskTitle: String, client: String, date: Date, completed: Bool, notificatonID: String){
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        //1
        let context = appDelegate.persistentContainer.viewContext
        
        //2
        if let entity = NSEntityDescription.entity(forEntityName: "Tasks", in: context) {
            
            let tasks = NSManagedObject(entity: entity, insertInto: context) as! Tasks
            
            //3
            tasks.setValue(taskTitle, forKeyPath: "task")
            tasks.setValue(client, forKeyPath: "client")
            tasks.setValue(date, forKeyPath: "deadline")
            tasks.setValue(completed, forKeyPath: "completed")
            tasks.setValue(notificatonID, forKey: "notificationID")
            
            //4
            do {
                
                try context.save()
                
            } catch let error as NSError {
                
                print("Could not save. \(error), \(error.userInfo)")
                
            }
        }
        
    }
    
    func validateTextFields() -> Bool{
        
        if titleField.text == ""  {
            
            createAlert(title: "", message: "add a task title.", buttonTitle: "ok.")
            
            return true
            
        } else if clientField.text == "" {
            
            createAlert(title: "", message: "add a client name.", buttonTitle: "ok.")
            
            return true
            
        } else if dateField.text == "" {
            
            createAlert(title: "", message: "add a deadline.", buttonTitle: "ok.")
            
            return true
            
        } else {
            
            return false
                
        }
        
    }
    
    func reloadViewAfterStayTapped(){
        
        fetchCoreData() //must call Fetch before Sort
        sortCoreDataIntoArrays()
        autoCompletionPossibilities = clientsArray
        autoCompletionPossibilities2 = titleArray
        
        titleField.text = ""
        clientField.text = ""
        
    }
    
    func createCalendarEvent(title: String, notes: String, deadline: Date) {
        //let calendar = ekclass.calendar
        //delegate access
        
        if let savedCalendarIdentifier = UserDefaults.standard.string(forKey: "EventTrackerPrimaryCalendar") {
            
            ekclass.assignedCalendarIdentifier = savedCalendarIdentifier
            
            ekclass.createEvent(title: title, notes: notes, deadline: deadline)
            print("created event for calendar")
            
        }
        print ("no event created")
        
    }
    
    
    @IBAction func addTaskTapped(_ sender: Any) {
        
        if validateTextFields() {
            
        } else {
            //add data
            //.lowercased()
            let taskTitle = titleField.text!.lowercased()
            let clientTitle = clientField.text!.lowercased()
            let notificationIdentifier = "\(taskTitle)+\(clientTitle)+\(dateBuffer)"
            
            addTaskToCoreData(taskTitle: taskTitle, client: clientTitle, date: dateBuffer, completed: false, notificatonID: notificationIdentifier)
            
            let mainVC = MainViewController()
            mainVC.createUserNotification(title: taskTitle, body: clientTitle, identifierNotification: notificationIdentifier, triggerDate: dateBuffer) //currently triggering on the actual date. without adjustment
            
            
            if let isTrue = UserDefaults.standard.value(forKey: "willSaveToCalendar"){
                if isTrue as! Bool { //if returns true
                    createCalendarEvent(title: taskTitle, notes: clientTitle, deadline: dateBuffer)
                }
            }
            
            self.navigationController?.popViewController(animated: true)
            
            
        }

    }
    
    @IBAction func addTaskStayTapped(_ sender: Any) {
        
        if validateTextFields() {
            
        } else {
            //add data
            //.lowercased()
            let taskTitle = titleField.text!.lowercased()
            let clientTitle = clientField.text!.lowercased()
            let notificationIdentifier = "\(taskTitle)+\(clientTitle)+\(dateBuffer)"
            
            addTaskToCoreData(taskTitle: taskTitle, client: clientTitle, date: dateBuffer, completed: false, notificatonID: notificationIdentifier)
            
            let mainVC = MainViewController()
            mainVC.createUserNotification(title: taskTitle, body: clientTitle, identifierNotification: notificationIdentifier, triggerDate: dateBuffer)
            
            if let isTrue = UserDefaults.standard.value(forKey: "willSaveToCalendar"){
                if isTrue as! Bool { //if returns true
                    createCalendarEvent(title: taskTitle, notes: clientTitle, deadline: dateBuffer)
                }
            }
            
            createAlert(title: "add complete.", message: "now enter another task.", buttonTitle: "ok")
            
            reloadViewAfterStayTapped()
        
        }
        
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
