//
//  ContentView.swift
//  MyToDoApp
//
//  Created by NTB on 23/4/2026.
//

import SwiftUI
import SwiftData

enum FilterType: CaseIterable {
    case all, active, completed
    
    var localizedName: LocalizedStringKey {
        switch self {
        case .all: return "All"
        case .active: return "Active"
        case .completed: return "Completed"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.creationDate, order: .reverse) private var items: [TodoItem]
    
    // UI State
    @State private var newTaskTitle: String = ""
    @State private var selectedPriority: Priority = .medium
    @State private var currentFilter: FilterType = .all
    @State private var searchText: String = "" // NEW: Search State
    
    // NEW: Due Date State
    @State private var includeDueDate: Bool = false
    @State private var selectedDueDate: Date = Date()

    // NEW: Filter logic now includes Search text
    var filteredItems: [TodoItem] {
        let filteredByTab = items.filter { item in
            switch currentFilter {
            case .all: return true
            case .active: return !item.isCompleted
            case .completed: return item.isCompleted
            }
        }
        
        if searchText.isEmpty {
            return filteredByTab
        } else {
            return filteredByTab.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var emptyStateMessage: LocalizedStringKey {
        if !searchText.isEmpty { return "No results found." }
        switch currentFilter {
        case .all: return "You have no tasks right now."
        case .active: return "You have no active tasks right now."
        case .completed: return "You have no completed tasks right now."
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Filter", selection: $currentFilter) {
                    ForEach(FilterType.allCases, id: \.self) { filter in
                        Text(filter.localizedName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                // REDESIGNED ADD TASK SECTION
                VStack(spacing: 12) {
                    HStack {
                        TextField("Add a new task...", text: $newTaskTitle)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { addTask() }
                        
                        Button(action: addTask) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                        }
                        .disabled(newTaskTitle.isEmpty)
                    }
                    
                    HStack {
                        Menu {
                            Picker("Priority", selection: $selectedPriority) {
                                Text("High Priority").tag(Priority.high)
                                Text("Medium Priority").tag(Priority.medium)
                                Text("Low Priority").tag(Priority.low)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "flag.fill")
                                Text("Priority")
                            }
                            .font(.caption)
                            .foregroundColor(color(for: selectedPriority))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(color(for: selectedPriority).opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        // DUE DATE PICKER
                        Toggle("Date", isOn: $includeDueDate)
                            .toggleStyle(.button)
                            .font(.caption)
                            .tint(.blue)
                        
                        if includeDueDate {
                            DatePicker("", selection: $selectedDueDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))

                // TASK LIST
                if filteredItems.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No Tasks",
                        systemImage: searchText.isEmpty ? "checklist" : "magnifyingglass",
                        description: Text(emptyStateMessage)
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            @Bindable var editableItem = item
                            
                            HStack {
                                Image(systemName: editableItem.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(editableItem.isCompleted ? .green : color(for: editableItem.priority))
                                    .font(.title2)
                                    .onTapGesture {
                                        withAnimation { editableItem.isCompleted.toggle() }
                                    }
                                
                                VStack(alignment: .leading) {
                                    TextField("Task Title", text: $editableItem.title)
                                        .strikethrough(editableItem.isCompleted, color: .gray)
                                        .foregroundColor(editableItem.isCompleted ? .gray : .primary)
                                    
                                    // SHOW DUE DATE IF IT EXISTS
                                    if let dueDate = editableItem.dueDate {
                                        Text(dueDate, style: .date)
                                            .font(.caption)
                                            .foregroundColor(editableItem.isCompleted ? .gray : .red)
                                    }
                                }
                            }
                            // NEW: Swipe left-to-right to complete
                            .swipeActions(edge: .leading) {
                                Button {
                                    withAnimation { editableItem.isCompleted.toggle() }
                                } label: {
                                    Label(editableItem.isCompleted ? "Undo" : "Complete", systemImage: editableItem.isCompleted ? "arrow.u-turn.backward" : "checkmark")
                                }
                                .tint(editableItem.isCompleted ? .orange : .green)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                    // NEW: Search Bar
                    .searchable(text: $searchText, prompt: "Search tasks...")
                }
            }
            .navigationTitle("My Tasks")
        }
    }

    private func addTask() {
        guard !newTaskTitle.isEmpty else { return }
        let dateToSave = includeDueDate ? selectedDueDate : nil
        let newItem = TodoItem(title: newTaskTitle, priority: selectedPriority, dueDate: dateToSave)
        
        withAnimation { modelContext.insert(newItem) }
        
        newTaskTitle = ""
        includeDueDate = false
        selectedDueDate = Date()
        selectedPriority = .medium
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let itemToDelete = filteredItems[index]
                modelContext.delete(itemToDelete)
            }
        }
    }
    
    private func color(for priority: Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
