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
    
    private var calendar = AUEventStoreInMemory() // TODO rename
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        calendar.addEventOnDate(firstDayOfWeek, description: "10pm Al Dentist")
        calendar.addEventOnDate(secondDayOfWeek, description: "R Hong Kong")
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
    
    func testCoreData() {
        // setup
        let model = NSManagedObjectModel.mergedModelFromBundles(NSBundle.allBundles())
        XCTAssert(model != nil, "model is not nil")
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
        let store = try? coordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
        XCTAssert(store != nil, "store is not nil")
        let context: NSManagedObjectContext = NSManagedObjectContext()
        context.persistentStoreCoordinator = coordinator
        
        // create
        let eventInfo: NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("AUEventInfo", inManagedObjectContext: context)
        eventInfo.setValue("1", forKey: "id")
        eventInfo.setValue(NSColor.redColor(), forKey: "color")
        let error = NSErrorPointer()
        do {
            try context.save()
        } catch let error as NSError {
            XCTFail(error.debugDescription)
        }
        
        // read
        let request = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("AUEventInfo", inManagedObjectContext: context)
        request.entity = entityDescription
        let results = try? context.executeFetchRequest(request)
        if results == nil {
            XCTFail(error.debugDescription)
        }
        for result in results! {
            XCTAssert(result is AUEventInfo, "result is AUEventInfo")
            XCTAssert((result as! AUEventInfo).color == NSColor.redColor(), "color is red")
        }
//        XCTAssert(<#expression: BooleanType#>, <#message: String#>)
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measureBlock() {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
