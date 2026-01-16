//
//  WorktreeOrchestrationService.swift
//  AgentHub
//
//  Created by Assistant on 1/15/26.
//

import Foundation
import ClaudeCodeSDK

/// Service for orchestrating parallel worktree creation and Claude session launching.
@MainActor
public final class WorktreeOrchestrationService {

  // MARK: - Properties

  private let gitService: GitWorktreeService
  private let monitorService: CLISessionMonitorService
  private let claudeClient: ClaudeCode

  /// Callback for progress updates
  public var onProgress: ((OrchestrationProgress) -> Void)?

  /// Callback for detailed worktree creation progress
  public var onWorktreeProgress: ((WorktreeCreationProgress) -> Void)?

  // MARK: - Initialization

  public init(
    gitService: GitWorktreeService,
    monitorService: CLISessionMonitorService,
    claudeClient: ClaudeCode
  ) {
    self.gitService = gitService
    self.monitorService = monitorService
    self.claudeClient = claudeClient
  }

  // MARK: - Public Methods

  /// Execute an orchestration plan - creates worktrees and launches Claude sessions
  /// - Parameter plan: The orchestration plan from Claude
  /// - Returns: Array of created worktree paths
  public func executePlan(_ plan: OrchestrationPlan) async throws -> [String] {
    print("[Orchestration] Starting execution for \(plan.sessions.count) sessions")
    onProgress?(.starting(sessionCount: plan.sessions.count))

    // Ensure the repository is added to the monitor service
    let repository = await monitorService.addRepository(plan.modulePath)
    if repository == nil {
      print("[Orchestration] Warning: Could not add repository to monitor")
    }

    var createdPaths: [String] = []
    var errors: [String] = []

    // Create worktrees sequentially to avoid git conflicts
    for (index, session) in plan.sessions.enumerated() {
      onProgress?(.creatingWorktree(
        index: index + 1,
        total: plan.sessions.count,
        branchName: session.branchName
      ))

      do {
        let worktreePath = try await createWorktreeForSession(
          session: session,
          modulePath: plan.modulePath
        )
        createdPaths.append(worktreePath)
        print("[Orchestration] Created worktree: \(worktreePath)")

        // Launch terminal with Claude immediately
        onProgress?(.launchingSession(
          index: index + 1,
          total: plan.sessions.count,
          branchName: session.branchName
        ))

        launchClaudeSession(
          path: worktreePath,
          branchName: session.branchName,
          prompt: session.prompt
        )

        // Delay between terminal launches to prevent macOS race condition
        if index < plan.sessions.count - 1 {
          try? await Task.sleep(for: .milliseconds(800))
        }

        // Refresh UI after each session (progressive updates)
        await monitorService.refreshSessions()

      } catch {
        print("[Orchestration] Failed to create worktree for \(session.branchName): \(error)")
        errors.append("\(session.branchName): \(error.localizedDescription)")
      }
    }

    // Expand the repository in the UI
    let repositories = await monitorService.getSelectedRepositories()
    if let repo = repositories.first(where: { $0.path == plan.modulePath }) {
      await expandRepository(repo)
    }

    onProgress?(.completed(
      successCount: createdPaths.count,
      errorCount: errors.count
    ))

    if !errors.isEmpty {
      print("[Orchestration] Completed with \(errors.count) errors: \(errors)")
    }

    return createdPaths
  }

  // MARK: - Private Methods

  private func createWorktreeForSession(
    session: OrchestrationSession,
    modulePath: String
  ) async throws -> String {
    // Capture callback for use in Sendable closure
    let progressCallback = onWorktreeProgress

    // Create worktree with the session's branch name
    let worktreePath = try await gitService.createWorktreeWithNewBranch(
      at: modulePath,
      newBranchName: session.branchName,
      directoryName: session.branchName,
      startPoint: nil
    ) { progress in
      print("[Orchestration] Worktree progress: \(progress.statusMessage)")
      // Forward detailed progress to callback on MainActor
      Task { @MainActor in
        progressCallback?(progress)
      }
    }

    return worktreePath
  }

  private func launchClaudeSession(
    path: String,
    branchName: String,
    prompt: String
  ) {
    // Launch terminal with Claude and initial prompt
    let error = TerminalLauncher.launchTerminalInPath(
      path,
      branchName: branchName,
      isWorktree: true,
      skipCheckout: true,
      claudeClient: claudeClient,
      initialPrompt: prompt
    )

    if let error = error {
      print("[Orchestration] Failed to launch terminal: \(error.localizedDescription)")
    } else {
      print("[Orchestration] Launched Claude session for \(branchName)")
    }
  }

  private func expandRepository(_ repository: SelectedRepository) async {
    // Get current repositories and find the one to expand
    var repositories = await monitorService.getSelectedRepositories()

    if let index = repositories.firstIndex(where: { $0.id == repository.id }) {
      repositories[index].isExpanded = true

      // Expand all worktrees
      for i in repositories[index].worktrees.indices {
        repositories[index].worktrees[i].isExpanded = true
      }

      // Update the repositories in the monitor service
      await monitorService.setSelectedRepositories(repositories)
    }
  }
}

// MARK: - Progress Enum

/// Progress updates during orchestration
public enum OrchestrationProgress {
  case starting(sessionCount: Int)
  case creatingWorktree(index: Int, total: Int, branchName: String)
  case launchingSession(index: Int, total: Int, branchName: String)
  case completed(successCount: Int, errorCount: Int)

  public var message: String {
    switch self {
    case .starting(let count):
      return "Spawning \(count) sessions..."
    case .creatingWorktree(let index, let total, let branch):
      return "Creating worktree \(index)/\(total): \(branch)"
    case .launchingSession(let index, let total, let branch):
      return "Launching session \(index)/\(total): \(branch)"
    case .completed(let success, let errors):
      if errors > 0 {
        return "Completed: \(success) sessions, \(errors) failed"
      }
      return "Completed: \(success) sessions launched"
    }
  }
}
