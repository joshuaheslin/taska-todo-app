//
//  EKEventsClass.swift
//  task-list-app
//
//  Created by Joshua Heslin on 29/5/18.
//  Copyright © 2018 Joshua Heslin. All rights reserved.
//

import Foundation
import EventKit
import UIKit

class EKEventsClass {
    
    var calendars: [EKCalendar]? //load calendars
    
    var events: [EKEvent]?      //load events from calendar
    var calendar: EKCalendar!
    
    var taskCalendarIdentifier = ""
    
    var assignedCalendarIdentifier = ""
    
    //**** authorise*****
    
    func checkCalendarAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
        
        switch (status) {
        case EKAuthorizationStatus.notDetermined:
            // This happens on first-run
            requestAccessToCalendar()
     
        case EKAuthorizationStatus.authorized:
            // Things are in line with being able to show the calendars in the table view
            
            loadCalendarsOrAddNewCalendar()

        //refreshTableView()
        case EKAuthorizationStatus.restricted, EKAuthorizationStatus.denied:
            // We need to help them give us permission
            //needPermissionView.fadeIn()
            print("you need permission")
 
        }
        
    }
    
    func loadCalendarsOrAddNewCalendar(){
        if let savedCalendarIdentifier = UserDefaults.standard.string(forKey: "EventTrackerPrimaryCalendar") {
            print ("calender identifier VC: \(savedCalendarIdentifier)")
            taskCalendarIdentifier = savedCalendarIdentifier
            loadCalendars()
            
            assignLoadedCalendars()
            
            loadEvents()
            //print(UserDefaults.standard.string(forKey: "event1")!)
            
            //ekclass.createEvent()
            print("isAuthorised: calendar loaded")
        } else {
            addNewCalender()
            print("isAuthroised: new calendar added")
        }
    }
    
    func requestAccessToCalendar() {
        EKEventStore().requestAccess(to: .event, completion: {
            (accessGranted: Bool, error: Error?) in
            
            if accessGranted == true {
                DispatchQueue.main.async(execute: {
                    
                    self.loadCalendarsOrAddNewCalendar()
                    
                })
            } else {
                DispatchQueue.main.async(execute: {
                    print("dispatch you need permission")
                })
            }
        })
    }
    
    func loadCalendars() {
        self.calendars = EKEventStore().calendars(for: EKEntityType.event).sorted() { (cal1, cal2) -> Bool in
            return cal1.title < cal2.title
        }
        print (calendars)
        
    }
    
    func assignLoadedCalendars(){
        for aCalendar in calendars! {
            if aCalendar.calendarIdentifier == taskCalendarIdentifier {
                calendar = aCalendar
                print(calendar)
                print(calendar.calendarIdentifier)
                assignedCalendarIdentifier = calendar.calendarIdentifier
                print("assigned to calendar!")
            }
        }
    }
    
    //**** create calendar***** ONLY DONE ONCE
    
    func addNewCalender(){
        let eventStore = EKEventStore();
        
        // Use Event Store to create a new calendar instance
        // Configure its title
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        
        // Probably want to prevent someone from saving a calendar
        // if they don't type in a name...
        newCalendar.title = "task."
        //newCalendar.cgColor = UIColor.black.cgColor
        newCalendar.cgColor = UIColor.blue.cgColor
        
        // Access list of available sources from the Event Store
        let sourcesInEventStore = eventStore.sources
        
        // Filter the available sources and select the "Local" source to assign to the new calendar's
        // source property
        newCalendar.source = sourcesInEventStore.filter{
            (source: EKSource) -> Bool in
            source.sourceType.rawValue == EKSourceType.local.rawValue
            }.first!
        
        // Save the calendar using the Event Store instance
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            UserDefaults.standard.set(newCalendar.calendarIdentifier, forKey: "EventTrackerPrimaryCalendar")
            print("calendar added")
            //delegate?.calendarDidAdd()
            //self.dismiss(animated: true, completion: nil)
        } catch {
            let alert = UIAlertController(title: "Calendar could not save", message: (error as NSError).localizedDescription, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(OKAction)
            
            //self.present(alert, animated: true, completion: nil)
        }
    }
    
    //**** load events*****
    
    func loadEvents() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let startDate = dateFormatter.date(from: "2018-01-01")
        let endDate = dateFormatter.date(from: "2018-12-31")
        
        if let startDate = startDate, let endDate = endDate {
            let eventStore = EKEventStore()
            
            
            if let isTrue = UserDefaults.standard.value(forKey: "willSaveToCalendar"){
                if isTrue as! Bool { //if returns true
                    //calendar is on
                    
                    //TODO: This below IF statement is incorrect and will cause 1 crash.
                    if let calendar = calendar {
                        
                        let eventsPredicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
                        
                        self.events = eventStore.events(matching: eventsPredicate).sorted {
                            (e1: EKEvent, e2: EKEvent) in
                            
                            return e1.startDate.compare(e2.startDate) == ComparisonResult.orderedAscending
                        }
                        print (events)
                        
                    } else {
                        //this condition is met when user deletes calendar from calendar app and tries to relaunch app, the 'calendar' instance is removed and need to create a new calendar
                        addNewCalender()
                        //now load it into 'calendar'
                        loadCalendars()
                        assignLoadedCalendars()
                        //now proceed to load events from calendar
                    }
                    
                }
                    
                }
            }
        
    }
    
    //**** create events*****
    
    func createEvent(title: String, notes: String, deadline: Date){
        
        // Create an Event Store instance
        let eventStore = EKEventStore();
        
        // Use Event Store to create a new calendar instance
        if let calendarForEvent = eventStore.calendar(withIdentifier: assignedCalendarIdentifier)
        {
            let newEvent = EKEvent(eventStore: eventStore)
            
            newEvent.calendar = calendarForEvent
            newEvent.title = title
            newEvent.startDate = deadline.addingTimeInterval(60*30) // subtract 30 minutes as default
            newEvent.endDate = deadline
            newEvent.notes = notes
            
            
            let alarm = EKAlarm()
            let date = Date().addingTimeInterval(5) //60secs
            alarm.absoluteDate = date
            
            
            
            //alarm.structuredLocation = location
            
            newEvent.addAlarm(alarm)
            
            
            // Save the event using the Event Store instance
            do {
                try eventStore.save(newEvent, span: .thisEvent, commit: true)
                //UserDefaults.standard.set(newEvent.eventIdentifier, forKey: "event1")
                //delegate?.eventDidAdd()
                print("ADDED!")
                //self.dismiss(animated: true, completion: nil)
            } catch {
                let alert = UIAlertController(title: "Event could not save", message: (error as NSError).localizedDescription, preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(OKAction)
                print ("ERROR")
                //self.present(alert, animated: true, completion: nil)
            }
        }
        
    }

}
