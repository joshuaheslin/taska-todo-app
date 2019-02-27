//
//  ClientViewController.swift
//  task-list-app
//
//  Created by Joshua Heslin on 7/5/18.
//  Copyright © 2018 Joshua Heslin. All rights reserved.
//

import UIKit
import CoreData

class ClientViewController: UIViewController {
    
    var clients: [Clients] = []
    
    @IBOutlet weak var clientField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //loadCD()

        // Do any additional setup after loading the view.
        self.hideKeyboardWhenTappedAround()
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped(gesture:)))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        self.view.addGestureRecognizer(swipeRight)
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - FUNCTIONS
    
    func addClientsToCoreData(client: String){
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        //1
        let context = appDelegate.persistentContainer.viewContext
        
        //2
        if let entity = NSEntityDescription.entity(forEntityName: "Clients", in: context) {
            
            let tasks = NSManagedObject(entity: entity, insertInto: context) as! Clients
            
            //3
            tasks.setValue(client, forKeyPath: "client")
            
            //4
            do {
                
                try context.save()
                
            } catch let error as NSError {
                
                print("Could not save. \(error), \(error.userInfo)")
                
            }
        }
        
    }
    
    func createAlert(title: String, message: String, buttonTitle: String){
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let button = UIAlertAction(title: buttonTitle, style: .cancel, handler: nil)
        
        alert.addAction(button)
        
        self.present(alert, animated: true, completion: nil)
        
    }

    @IBAction func addClientTapped(_ sender: Any) {
        
        if clientField.text == "" {
            createAlert(title: "go find some clients.", message: "add a client name.", buttonTitle: "ok.")
        } else {
            if let client = clientField.text {
                
                addClientsToCoreData(client: client)
                
                clientsArr.append(client) //store in CD and Arr for now
            }
        }
        
        self.navigationController?.popViewController(animated: true)
        
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
