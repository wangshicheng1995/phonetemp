//
//  Item.swift
//  PhoneTemp
//
//  Created by Echo Wang on 2025/7/12.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
