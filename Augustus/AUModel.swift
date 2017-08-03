//
//  AUModel.swift
//  Augustus
//
//  Created by Ryan Globus on 6/22/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Foundation
import Cocoa

struct AUModel {
    static let calendar = AUModel.getCurrentCalendar()
    static let oneHour: TimeInterval = 60 * 60
    static let oneDay: TimeInterval = 60 * 60 * 24
    static let notificationName = "AUModelNotification"
    static var eventStore: AUEventStore = AUEventStoreInEK()
    
    static func beginningOfDate(_ date: Date) -> Date {
        let components = (AUModel.calendar as NSCalendar).components([NSCalendar.Unit.year, NSCalendar.Unit.month, NSCalendar.Unit.day], from: date)
        return AUModel.calendar.date(from: components)!
    }
    
    fileprivate static func getCurrentCalendar() -> Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday TODO make configurable
        return calendar
    }
}



protocol AUEvent {
    var id: String { get }
    var description: String { get }
    var date: Date { get }
    var creationDate: Date? { get }
    var color: NSColor {get set}
}

struct AUWeek { // TODO let user choose start on Sunday/Monday
    let firstDate: Date
    static let numDaysInWeek = 7
    var lastDate: Date {
        get {
            return self[AUWeek.numDaysInWeek - 1]
        }
    }
    
    init() {
        self.init(containingDate: Date())
    }
    
    init(containingDate date: Date) {
        var firstDate = date
        while (AUModel.calendar as NSCalendar).component(NSCalendar.Unit.weekday, from: firstDate) != AUModel.calendar.firstWeekday {
            firstDate = firstDate.addingTimeInterval(-1 * AUModel.oneDay)
        }
        self.firstDate = firstDate
    }
    
    func dates() -> [Date] {
        var dates: [Date] = [firstDate]
        var date = self.firstDate.addingTimeInterval(AUModel.oneDay)
        while (AUModel.calendar as NSCalendar).component(NSCalendar.Unit.weekday, from: date) != AUModel.calendar.firstWeekday {
            dates.append(date)
            date = date.addingTimeInterval(AUModel.oneDay)
        }
        return dates
    }
    
    func plusNumWeeks(_ numWeeks: Int) -> AUWeek {
        let numDays = Double(numWeeks * AUWeek.numDaysInWeek)
        let date = self.firstDate.addingTimeInterval(AUModel.oneDay * numDays)
        return AUWeek(containingDate: date)
    }
    
    func plusNumMonths(_ numMonths: Int) -> AUWeek {
        if let newDate = (AUModel.calendar as NSCalendar).date(byAdding: NSCalendar.Unit.month, value: numMonths, to: self.firstDate, options: NSCalendar.Options()) {
            return AUWeek(containingDate: newDate)
        } else {
            AULog.instance.error("Cannot add one month to \(self.firstDate). Returning self.")
            return self
        }
    }
    
    subscript(index: Int) -> Date {
        get {
            return self.dates()[index] // TODO make more efficient
        }
    }
}

func ==(lhs: AUWeek, rhs: AUWeek) -> Bool {
    return lhs.firstDate == rhs.firstDate
}

func !=(lhs: AUWeek, rhs: AUWeek) -> Bool {
    return !(lhs == rhs)
}

enum AUEventStorePermission {
    case granted, pending, denied
}

protocol AUEventStore {
    
    var permission: AUEventStorePermission { get }
    
    /// returns true upon success, false upon failure
    mutating func addEventOnDate(_ date: Date, description: String) -> AUEvent?
    
    /// returns true if an event is removed, false upon failure or if no event is removed
    mutating func removeEvent(_ event: AUEvent) -> Bool
    
    /// returns true upon success, false upon failure (e.g., event is not in the AUEventStore)
    mutating func editEvent(_ event: AUEvent, newDate: Date, newDescription: String) -> Bool
    
    func eventsForDate(_ date: Date) -> [AUEvent]
    
}

extension AUEventStore {
    func eventsForWeek(_ week: AUWeek) -> [Date : [AUEvent]] {
        var dateEvents = Dictionary<Date, Array<AUEvent>>()
        for date in week.dates() {
            dateEvents[date] = self.eventsForDate(date)
        }
        return dateEvents
    }
}


struct AUEventStoreInMemory: AUEventStore {
    fileprivate struct AUEventInMemory: AUEvent {
        let id: String
        let description: String
        let date: Date
        let creationDate: Date?
        var color: NSColor
        
        init(id: String, description: String, date: Date, creationDate: Date?) {
            self.id = id
            self.description = description
            self.date = date
            self.creationDate = creationDate
            self.color = NSColor.black
        }
    }
    
    fileprivate var dateEventDictionary = Dictionary<Date, Array<AUEvent>>()
    
    let permission: AUEventStorePermission = .granted
    
    mutating func addEventOnDate(_ date: Date, description: String) -> AUEvent? {
        let event = AUEventInMemory(id: UUID().uuidString, description: description, date: date, creationDate: Date())
        return self.addEvent(event)
    }
    
    fileprivate mutating func addEvent(_ event: AUEvent) -> AUEvent? {
        let date = AUModel.beginningOfDate(event.date)
        if var events = dateEventDictionary[date] {
            events.append(event)
            dateEventDictionary.updateValue(events, forKey: date)
        } else {
            dateEventDictionary.updateValue([event], forKey: date)
        }
        return event
    }
    
    // inefficient, but whatever
    mutating func editEvent(_ event: AUEvent, newDate: Date, newDescription: String) -> Bool {
        for (date, var events) in dateEventDictionary {
            for i in 0..<events.count {
                let e = events[i]
                if e.id == event.id {
                    // TODO modification while iterating?
                    let newEvent = AUEventInMemory(id: event.id, description: newDescription, date: newDate, creationDate: event.creationDate)
                    events.remove(at: i)
                    if date == AUModel.beginningOfDate(newDate) { // put back in same place
                        events.insert(newEvent, at: i)
                    } else { // add to another [AUEvent] in Dictionary
                        self.addEvent(newEvent)
                    }
                    dateEventDictionary[date] = events
                    return true
                }
            }
        }
        return false
    }
    
    mutating func removeEvent(_ event: AUEvent) -> Bool {
        for (date, var events) in dateEventDictionary {
            for i in 0..<events.count {
                if event.id == events[i].id {
                    events.remove(at: i)
                    dateEventDictionary.updateValue(events, forKey: date)
                    return true
                }
            }
        }
        return false
    }
    
    func eventsForDate(_ date: Date) -> [AUEvent] {
        var date = date
        date = AUModel.beginningOfDate(date)
        if let events = dateEventDictionary[date] {
            return events
        } else {
            return []
        }
    }
    
    mutating func clear() {
        dateEventDictionary.removeAll()
    }
}


