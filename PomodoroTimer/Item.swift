//
//  Item.swift
//  PomodoroTimer
//
//  Created by Tsubasa on 2026/09/03.
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
