//
//  TodoItem.swift
//  MyToDoApp
//
//  Created by NTB on 23/4/2026.
//

import Foundation
import SwiftData

// Define our priority levels
enum Priority: Int, Codable {
    case low = 1
    case medium = 2
    case high = 3
}

@Model
final class TodoItem {
    var title: String
    var isCompleted: Bool
    var creationDate: Date
    var priority: Priority // Priority level
    var dueDate: Date? // Optional due date
    
    init(title: String, isCompleted: Bool = false, priority: Priority = .medium, dueDate:Date? = nil) {
        self.title = title
        self.isCompleted = isCompleted
        self.creationDate = Date()
        self.priority = priority
        self.dueDate = dueDate
    }
}
