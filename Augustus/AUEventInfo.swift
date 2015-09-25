//
//  AUEventInfo.swift
//  Augustus
//
//  Created by Ryan Globus on 9/2/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Foundation
import CoreData
import Cocoa

@objc(AUEventInfo)
class AUEventInfo: NSManagedObject {

    @NSManaged var color: NSColor?
    @NSManaged var id: String

}
