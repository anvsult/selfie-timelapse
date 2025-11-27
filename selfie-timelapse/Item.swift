//
//  Item.swift
//  selfie-timelapse
//
//  Created by Anvar Sultanov on 2025-11-27.
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
