//
//  IntelligenceViewModel.swift
//  AgentHub
//
//  Created by Assistant on 1/15/26.
//

import Foundation
import ClaudeCodeSDK
import Combine

/// View model for the Intelligence feature.
/// Manages communication with Claude Code SDK and handles streaming responses.
@Observable
@MainActor
public final class IntelligenceViewModel {

  // MARK: - Properties

  /// The Claude Code client for SDK communication
  private var claudeClient: ClaudeCode

  /// Stream processor for handling responses
  private let streamProcessor = IntelligenceStreamProcessor()

  /// Orchestration service for parallel worktree operations
  private var orchestrationService: WorktreeOrchestrationService?

  /// Current loading state
  public private(set) var isLoading: Bool = false

  /// Last assistant response text
  public private(set) var lastResponse: String = ""

  /// Error message if any
  public private(set) var errorMessage: String?

  /// Working directory for Claude operations
  public var workingDirectory: String?

  /// Orchestration progress message
  public private(set) var orchestrationProgress: String?

  /// Detailed worktree creation progress
  public private(set) var worktreeProgress: WorktreeCreationProgress?

  /// Pending orchestration plan to execute after stream completes
  private var pendingOrchestrationPlan: OrchestrationPlan?

  // MARK: - Initialization

  /// Creates a new IntelligenceViewModel with a Claude Code client
  public init(
    claudeClient: ClaudeCode? = nil,
    gitService: GitWorktreeService? = nil,
    monitorService: CLISessionMonitorService? = nil
  ) {
    // Create Claude client
    if let client = claudeClient {
      self.claudeClient = client
    } else {
      // Create client with NVM support and local Claude path
      do {
        var config = ClaudeCodeConfiguration.withNvmSupport()
        config.enableDebugLogging = true

        let homeDir = NSHomeDirectory()

        // Add local Claude installation path (highest priority)
        let localClaudePath = "\(homeDir)/.claude/local"
        if FileManager.default.fileExists(atPath: localClaudePath) {
          config.additionalPaths.insert(localClaudePath, at: 0)
        }

        // Add common development tool paths
        config.additionalPaths.append(contentsOf: [
          "/usr/local/bin",
          "/opt/homebrew/bin",
          "/usr/bin",
          "\(homeDir)/.bun/bin",
          "\(homeDir)/.deno/bin",
          "\(homeDir)/.cargo/bin",
          "\(homeDir)/.local/bin"
        ])

        self.claudeClient = try ClaudeCodeClient(configuration: config)
      } catch {
        fatalError("Failed to create ClaudeCodeClient: \(error)")
      }
    }

    // Create orchestration service if dependencies provided
    if let gitService = gitService, let monitorService = monitorService {
      self.orchestrationService = WorktreeOrchestrationService(
        gitService: gitService,
        monitorService: monitorService,
        claudeClient: self.claudeClient
      )

      self.orchestrationService?.onProgress = { [weak self] progress in
        Task { @MainActor in
          self?.orchestrationProgress = progress.message
        }
      }

      self.orchestrationService?.onWorktreeProgress = { [weak self] progress in
        Task { @MainActor in
          self?.worktreeProgress = progress
        }
      }
    }

    setupStreamCallbacks()
  }

  private func setupStreamCallbacks() {
    streamProcessor.onTextReceived = { [weak self] text in
      self?.lastResponse += text
    }

    streamProcessor.onToolUse = { toolName, input in
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
      print("🔧 TOOL: \(toolName)")
      print("📥 INPUT: \(input.prefix(500))\(input.count > 500 ? "..." : "")")
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    streamProcessor.onToolResult = { result in
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
      print("📤 RESULT: \(result.prefix(500))\(result.count > 500 ? "..." : "")")
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    streamProcessor.onComplete = { [weak self] in
      guard let self = self else { return }
      Task { @MainActor in
        // Execute pending orchestration AFTER stream completes (avoids race condition)
        if let plan = self.pendingOrchestrationPlan {
          self.pendingOrchestrationPlan = nil
          await self.executeOrchestrationPlan(plan)
        }
        self.isLoading = false
        self.orchestrationProgress = nil
        self.worktreeProgress = nil
      }
    }

    streamProcessor.onError = { [weak self] error in
      Task { @MainActor in
        self?.isLoading = false
        self?.orchestrationProgress = nil
        self?.worktreeProgress = nil
        self?.errorMessage = error.localizedDescription
      }
    }

    // Store orchestration plan for execution after stream completes (avoid race condition)
    streamProcessor.onOrchestrationPlan = { [weak self] plan in
      self?.pendingOrchestrationPlan = plan
    }
  }

  private func executeOrchestrationPlan(_ plan: OrchestrationPlan) async {
    guard let orchestrationService = orchestrationService else {
      print("❌ Orchestration service not available")
      return
    }

    print("════════════════════════════════════════")
    print("🎯 EXECUTING ORCHESTRATION PLAN")
    print("📁 Module: \(plan.modulePath)")
    print("📋 Sessions: \(plan.sessions.count)")
    print("════════════════════════════════════════")

    do {
      let createdPaths = try await orchestrationService.executePlan(plan)
      print("✅ Created \(createdPaths.count) worktrees")
    } catch {
      print("❌ Orchestration failed: \(error.localizedDescription)")
      self.errorMessage = "Orchestration failed: \(error.localizedDescription)"
    }
  }

  // MARK: - Public Methods

  /// Send a message to Claude Code
  /// - Parameter text: The user's prompt
  public func sendMessage(_ text: String) {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    guard !isLoading else { return }

    // Reset state
    lastResponse = ""
    errorMessage = nil
    orchestrationProgress = nil
    worktreeProgress = nil
    pendingOrchestrationPlan = nil
    isLoading = true

    // Determine if we're in orchestration mode (working directory selected)
    let isOrchestrationMode = workingDirectory != nil && orchestrationService != nil

    print("════════════════════════════════════════")
    print("🧠 INTELLIGENCE REQUEST")
    print("📝 Prompt: \(text)")
    if isOrchestrationMode {
      print("🎯 Mode: Orchestration")
      print("📁 Working Directory: \(workingDirectory ?? "")")
    }
    print("════════════════════════════════════════")

    Task {
      do {
        // Configure working directory if set
        if let workingDir = workingDirectory {
          claudeClient.configuration.workingDirectory = workingDir
        }

        // Create options
        var options = ClaudeCodeOptions()
        // Use default permission mode for simple operations
        options.permissionMode = .default

        // Use orchestration system prompt if in orchestration mode
        if isOrchestrationMode, let workingDir = workingDirectory {
          options.systemPrompt = """
            \(WorktreeOrchestrationTool.systemPrompt)

            CONTEXT:
            - Working directory: \(workingDir)
            - Use this path as the modulePath in your orchestration plan
            """

          // Use disallowedTools to prevent file modifications during orchestration
          options.disallowedTools = ["Edit", "MultiEdit", "Write", "AskUserQuestion", "Bash"]
        }

        // Send the prompt
        let result = try await claudeClient.runSinglePrompt(
          prompt: text,
          outputFormat: .streamJson,
          options: options
        )

        // Process the result
        await processResult(result)
      } catch {
        print("❌ ERROR: \(error.localizedDescription)")
        await MainActor.run {
          self.isLoading = false
          self.errorMessage = error.localizedDescription
        }
      }
    }
  }

  /// Cancel the current request
  public func cancelRequest() {
    print("⛔ Request cancelled by user")
    streamProcessor.cancelStream()
    claudeClient.cancel()
    isLoading = false
  }

  /// Update the Claude client
  public func updateClient(_ client: ClaudeCode) {
    self.claudeClient = client
  }

  // MARK: - Private Methods

  private func processResult(_ result: ClaudeCodeResult) async {
    switch result {
    case .stream(let publisher):
      await streamProcessor.processStream(publisher)

    case .text(let text):
      print("[Intelligence] Text result: \(text)")
      lastResponse = text
      isLoading = false

    case .json(let resultMessage):
      print("[Intelligence] JSON result - Cost: $\(String(format: "%.4f", resultMessage.totalCostUsd))")
      lastResponse = resultMessage.result ?? ""
      isLoading = false
    }
  }
}
