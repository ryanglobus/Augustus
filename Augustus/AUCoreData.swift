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
    // TODO 0.3 => 0.4, lose colors????
    static let instance = AUCoreData()
    
    let context: NSManagedObjectContext
    fileprivate let log: AULog
    
    fileprivate init?() {
        self.log = AULog.instance
        guard let momdUrl = Bundle.main.url(forResource: "AUCoreDataModel", withExtension: "momd") else {
            self.log.error("Could not create momdUrl")
            return nil
        }
        
        let supportDirectories = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard supportDirectories.count > 0 else {
            self.log.error("No support directories found")
            return nil
        }
        // TODO sketchy
        let supportDirectory = supportDirectories[0]
        let augustusDirectory = supportDirectory.appendingPathComponent("Augustus")
        do {
            try FileManager.default.createDirectory(at: augustusDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            self.log.error(error.debugDescription)
            return nil
        }
        let sqlUrl = supportDirectory.appendingPathComponent("Augustus/db.sqlite")
        
        guard let model = NSManagedObjectModel(contentsOf: momdUrl) else {
            self.log.error("Could not create NSManagedObjectModel")
            return nil
        }
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: sqlUrl, options: nil)
        } catch let error as NSError {
            // TODO
            self.log.error(error.debugDescription)
            return nil
        }
        self.context = NSManagedObjectContext()
        self.context.persistentStoreCoordinator = coordinator
        
        self.log.info("Created AUCoreData")
    
    }
    
    // TODO make this more ORM-y
    func colorForAUEvent(_ event: AUEvent) -> NSColor? {
        return self.getAUEventInfoForEvent(event)?.color
    }
    
    func setColor(_ color: NSColor?, forEvent event: AUEvent) -> Bool {
        guard let eventInfo = self.getOrCreateAUEventInfoForEvent(event, commit: false) else {
            return false
        }
        eventInfo.color = color
        return self.commit()
    }
    
    fileprivate func getAUEventInfoForEvent(_ event: AUEvent) -> AUEventInfo? {
        let entityDescription = NSEntityDescription.entity(forEntityName: "AUEventInfo", in: self.context)
        let predicate = NSPredicate(format: "id = %@", event.id)
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entityDescription
        request.predicate = predicate
        
        do {
            let results = try context.fetch(request)
            guard results.count != 0 else {
                self.log.info("No AUEventInfo found with id \(event.id)")
                return nil
            }
            if results.count > 1 {
                self.log.warn("Multiple AUEventInfos found with id \(event.id)")
            }
            guard let result = results[0] as? AUEventInfo else {
                return nil
            }
            return result
        } catch let error as NSError {
            self.log.error(error.debugDescription)
            return nil
        }
    }
    
    fileprivate func getOrCreateAUEventInfoForEvent(_ event: AUEvent, commit: Bool = true) -> AUEventInfo? { // TODO not thread safe
        if let eventInfo = self.getAUEventInfoForEvent(event) {
            return eventInfo
        }
        
        guard let eventInfo = NSEntityDescription.insertNewObject(forEntityName: "AUEventInfo", into: self.context) as? AUEventInfo else {
            self.log.error("Could not create fresh event info object")
            return nil
        }
        eventInfo.id = event.id
        if commit {
            guard self.commit() else { return nil }
        }
        return eventInfo
    }
    
    fileprivate func commit() -> Bool {
        do {
            try self.context.save()
            return true
        } catch let error as NSError {
            self.log.error("Could not save newly created AUEventInfo")
            self.log.error(error.debugDescription)
            return false
        }
    }
}
