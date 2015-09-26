//
//  AUCoreData.swift
//  Augustus
//
//  Created by Ryan Globus on 9/2/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Foundation
import Cocoa
import CoreData

struct AUCoreData {
    static let instance = AUCoreData()
    
    let context: NSManagedObjectContext
    private let log: AULog
    
    private init?() {
        self.log = AULog.instance
        guard let momdUrl = NSBundle.mainBundle().URLForResource("AUCoreDataModel", withExtension: "momd") else {
            self.log.error?("Could not create momdUrl")
            return nil
        }
        
        let supportDirectories = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        guard supportDirectories.count > 0 else {
            self.log.error?("No support directories found")
            return nil
        }
        // TODO sketchy
        let supportDirectory = supportDirectories[0]
        let augustusDirectory = supportDirectory.URLByAppendingPathComponent("Augustus")
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(augustusDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            self.log.error?(error.debugDescription)
            return nil
        }
        let sqlUrl = supportDirectory.URLByAppendingPathComponent("Augustus/db.sqlite")
        
        guard let model = NSManagedObjectModel(contentsOfURL: momdUrl) else {
            self.log.error?("Could not create NSManagedObjectModel")
            return nil
        }
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: sqlUrl, options: nil)
        } catch let error as NSError {
            // TODO
            self.log.error?(error.debugDescription)
            return nil
        }
        self.context = NSManagedObjectContext()
        self.context.persistentStoreCoordinator = coordinator
        
        self.log.info?("Created AUCoreData")
    
    }
    
    // TODO make this more ORM-y
    func colorForAUEvent(event: AUEvent) -> NSColor? {
        return self.getAUEventInfoForEvent(event)?.color
    }
    
    func setColor(color: NSColor?, forEvent event: AUEvent) -> Bool {
        guard let eventInfo = self.getOrCreateAUEventInfoForEvent(event, commit: false) else {
            return false
        }
        eventInfo.color = color
        return self.commit()
    }
    
    private func getAUEventInfoForEvent(event: AUEvent) -> AUEventInfo? {
        let entityDescription = NSEntityDescription.entityForName("AUEventInfo", inManagedObjectContext: self.context)
        let predicate = NSPredicate(format: "id = %@", event.id)
        
        let request = NSFetchRequest()
        request.entity = entityDescription
        request.predicate = predicate
        
        do {
            let results = try context.executeFetchRequest(request)
            guard results.count != 0 else {
                log.info?("No AUEventInfo found with id \(event.id)")
                return nil
            }
            if results.count > 1 {
                log.warn?("Multiple AUEventInfos found with id \(event.id)")
            }
            guard let result = results[0] as? AUEventInfo else {
                return nil
            }
            return result
        } catch let error as NSError {
            self.log.error?(error.debugDescription)
            return nil
        }
    }
    
    private func getOrCreateAUEventInfoForEvent(event: AUEvent, commit: Bool = true) -> AUEventInfo? { // TODO not thread safe
        if let eventInfo = self.getAUEventInfoForEvent(event) {
            return eventInfo
        }
        
        guard let eventInfo = NSEntityDescription.insertNewObjectForEntityForName("AUEventInfo", inManagedObjectContext: self.context) as? AUEventInfo else {
            self.log.error?("Could not create fresh event info object")
            return nil
        }
        eventInfo.id = event.id
        if commit {
            guard self.commit() else { return nil }
        }
        return eventInfo
        
        // create
        //        let eventInfo: NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("AUEventInfo", inManagedObjectContext: context)
        //        eventInfo.setValue("1", forKey: "id")
        //        eventInfo.setValue(NSColor.redColor(), forKey: "color")
        //        let error = NSErrorPointer()
        //        do {
        //            try context.save()
        //        } catch let error as NSError {
        //            XCTFail(error.debugDescription)
        //        }
    }
    
    private func commit() -> Bool {
        do {
            try self.context.save()
            return true
        } catch let error as NSError {
            self.log.error?("Could not save newly created AUEventInfo")
            self.log.error?(error.debugDescription)
            return false
        }
    }
}
