//
//  AUModel.swift
//  Augustus
//
//  Created by Ryan Globus on 6/22/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Foundation

let calendar = NSCalendar.currentCalendar()
let oneDay: NSTimeInterval = 60 * 60 * 24

struct AUEvent {
    let id: String
    let description: String
    let date: NSDate
    
    init(description: String, date: NSDate) {
        self.id = NSUUID().UUIDString
        self.description = description
        self.date = date
    }
}

struct AUWeek { // TODO let user choose start on Sunday/Monday
    let firstDate: NSDate
    
    init(containingDate date: NSDate) {
        var firstDate = date
        while calendar.component(NSCalendarUnit.WeekdayCalendarUnit, fromDate: firstDate) != calendar.firstWeekday { // TODO deprecated?
            firstDate = firstDate.dateByAddingTimeInterval(-1 * oneDay)
        }
        self.firstDate = firstDate
    }
    
    func dates() -> [NSDate] {
        var dates: [NSDate] = [firstDate]
        var date = firstDate.dateByAddingTimeInterval(oneDay)
        while calendar.component(NSCalendarUnit.WeekdayCalendarUnit, fromDate: date) != calendar.firstWeekday { // TODO deprecated?
            dates.append(date)
            date = date.dateByAddingTimeInterval(oneDay)
        }
        return dates
    }
}

protocol AUCalendar {
    /// returns true upon success, false upon failure
    mutating func addEvent(event: AUEvent) -> Bool
    
    /// returns true if an event is removed, false upon failure or if no event is removed
    mutating func removeEvent(event: AUEvent) -> Bool
    
    func eventsForDate(date: NSDate) -> [AUEvent]
    
    func eventsForWeek(week: AUWeek) -> [NSDate: [AUEvent]]
}


struct AUCalendarInMemory: AUCalendar {
    private var dateEventDictionary = Dictionary<NSDate, Array<AUEvent>>()
    
     mutating func addEvent(event: AUEvent) -> Bool { // TODO don't add if already there
        let date = event.date
        if var events = dateEventDictionary[date] {
            events.append(event)
            dateEventDictionary.updateValue(events, forKey: date)
        } else {
            dateEventDictionary.updateValue([event], forKey: date)
        }
        return true
    }
    
    mutating func removeEvent(event: AUEvent) -> Bool {
        for (date, var events) in dateEventDictionary {
            for i in 0..<events.count {
                if event.id == events[i].id {
                    events.removeAtIndex(i)
                    dateEventDictionary.updateValue(events, forKey: date)
                    return true
                }
            }
        }
        return false
    }
    
    func eventsForDate(date: NSDate) -> [AUEvent] {
        if let events = dateEventDictionary[date] {
            return events
        } else {
            return []
        }
    }
    
    func eventsForWeek(week: AUWeek) -> [NSDate : [AUEvent]] {
        var dateEvents = Dictionary<NSDate, Array<AUEvent>>()
        for date in week.dates() {
            dateEvents[date] = eventsForDate(date)
        }
        return dateEvents
    }
    
    mutating func clear() {
        dateEventDictionary.removeAll()
    }
}
