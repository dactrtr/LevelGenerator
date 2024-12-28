//
//  Item.swift
//  LevelGenerator
//
//  Created by Dactrtr on 2024/12/28.
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
