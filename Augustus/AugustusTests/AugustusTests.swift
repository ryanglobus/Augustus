//
//  AugustusTests.swift
//  AugustusTests
//
//  Created by Ryan Globus on 6/22/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Cocoa
import XCTest

private let today = NSDate()
private let thisWeek = AUWeek(containingDate: today)
private let firstDayOfWeek = thisWeek[0]
private let secondDayOfWeek = thisWeek[1]
//private let tomorrow = today.dateByAddingTimeInterval(oneDay)

class AugustusTests: XCTestCase {
    
    private var calendar = AUCalendarInMemory()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let event = AUEvent(description: "10pm Al Dentist", date: firstDayOfWeek)
        let event2 = AUEvent(description: "R Hong Kong", date: secondDayOfWeek)
        calendar.addEvent(event)
        calendar.addEvent(event2)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        calendar.clear()
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
//        XCTAssert(true, "Pass")
        let todayEvents = calendar.eventsForDate(firstDayOfWeek)
        XCTAssert(todayEvents.count == 1, "1 event today")
        XCTAssert(todayEvents[0].description == "10pm Al Dentist", "first day event description matches")
        XCTAssert(todayEvents[0].date == firstDayOfWeek, "first day event is today")
        
        let tomorrowEvents = calendar.eventsForDate(secondDayOfWeek)
        XCTAssert(tomorrowEvents.count == 1, "1 event today")
        XCTAssert(tomorrowEvents[0].description == "R Hong Kong", "second day event description matches")
        XCTAssert(tomorrowEvents[0].date == secondDayOfWeek, "second day event is tomorrow")
        

    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measureBlock() {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
