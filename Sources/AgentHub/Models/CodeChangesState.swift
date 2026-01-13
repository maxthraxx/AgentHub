//
//  CodeChangesState.swift
//  AgentHub
//
//  Created by Assistant on 1/13/26.
//

import Foundation

// MARK: - CodeChangesState

/// Aggregated state of all code changes in a session
public struct CodeChangesState: Equatable, Sendable {
  /// All code change entries from the session
  public let changes: [CodeChangeEntry]

  /// Files affected by changes
  public var affectedFiles: [String] {
    Array(Set(changes.map { $0.input.filePath })).sorted()
  }

  /// Total number of changes
  public var changeCount: Int {
    changes.count
  }

  public init(changes: [CodeChangeEntry]) {
    self.changes = changes
  }

  /// Create from session monitor state's recent activities
  public static func from(activities: [ActivityEntry]) -> CodeChangesState {
    let codeChanges = activities.compactMap { activity -> CodeChangeEntry? in
      guard case .toolUse(let name) = activity.type,
            ["Edit", "Write", "MultiEdit"].contains(name),
            let input = activity.toolInput else {
        return nil
      }
      return CodeChangeEntry(
        id: activity.id,
        timestamp: activity.timestamp,
        input: input
      )
    }
    return CodeChangesState(changes: codeChanges)
  }
}

// MARK: - CodeChangeEntry

/// A single code change entry
public struct CodeChangeEntry: Identifiable, Equatable, Sendable {
  public let id: UUID
  public let timestamp: Date
  public let input: CodeChangeInput

  public var fileName: String {
    input.fileName
  }

  public init(
    id: UUID,
    timestamp: Date,
    input: CodeChangeInput
  ) {
    self.id = id
    self.timestamp = timestamp
    self.input = input
  }
}
