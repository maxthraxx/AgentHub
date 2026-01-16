//
//  SessionObservationService.swift
//  AgentHub
//
//  Created by Assistant on 1/16/26.
//

import Foundation
import Combine

/// Service for programmatic session observation
/// Tracks which sessions should be observed and provides auto-observe functionality
public actor SessionObservationService {

  // MARK: - Publishers

  /// Subject is nonisolated(unsafe) because CurrentValueSubject is thread-safe
  /// and we need to expose it from a nonisolated context for Combine subscriptions
  private nonisolated(unsafe) let observedSessionIdsSubject = CurrentValueSubject<Set<String>, Never>([])

  /// Publisher for observed session IDs changes
  public nonisolated var observedSessionIdsPublisher: AnyPublisher<Set<String>, Never> {
    observedSessionIdsSubject.eraseToAnyPublisher()
  }

  // MARK: - State

  /// All session IDs we've ever seen (for detecting new sessions)
  private var knownSessionIds: Set<String> = []

  /// Session IDs currently being observed
  public private(set) var observedSessionIds: Set<String> = [] {
    didSet {
      observedSessionIdsSubject.send(observedSessionIds)
    }
  }

  // MARK: - Initialization

  public init() {}

  // MARK: - Public Methods

  /// Observe a session by ID
  public func observe(sessionId: String) {
    observedSessionIds.insert(sessionId)
  }

  /// Observe multiple sessions
  public func observe(sessionIds: Set<String>) {
    observedSessionIds.formUnion(sessionIds)
  }

  /// Stop observing a session
  public func stopObserving(sessionId: String) {
    observedSessionIds.remove(sessionId)
  }

  /// Check if a session is being observed
  public func isObserving(sessionId: String) -> Bool {
    observedSessionIds.contains(sessionId)
  }

  /// Process a list of sessions, auto-observing any new ones
  /// Returns the set of newly observed session IDs
  @discardableResult
  public func processAndAutoObserve(sessions: [CLISession]) -> Set<String> {
    let currentIds = Set(sessions.map(\.id))
    let newIds = currentIds.subtracting(knownSessionIds)

    // Update known sessions
    knownSessionIds.formUnion(currentIds)

    // Auto-observe new sessions
    if !newIds.isEmpty {
      observe(sessionIds: newIds)
    }

    return newIds
  }

  /// Reset known sessions (e.g., on app restart)
  public func resetKnownSessions() {
    knownSessionIds.removeAll()
  }

  /// Get current count of observed sessions
  public func observedCount() -> Int {
    observedSessionIds.count
  }
}
