//
//  MonitoringCardView.swift
//  AgentHub
//
//  Created by Assistant on 1/11/26.
//

import SwiftUI

// MARK: - MonitoringCardView

/// Card view for displaying a monitored session in the monitoring panel
public struct MonitoringCardView: View {
  let session: CLISession
  let state: SessionMonitorState?
  let onStopMonitoring: () -> Void
  let onConnect: () -> Void

  public init(
    session: CLISession,
    state: SessionMonitorState?,
    onStopMonitoring: @escaping () -> Void,
    onConnect: @escaping () -> Void
  ) {
    self.session = session
    self.state = state
    self.onStopMonitoring = onStopMonitoring
    self.onConnect = onConnect
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Header with session info and actions
      header

      // Project path (full path to distinguish worktrees)
      Text(session.projectPath)
        .font(.caption2)
        .foregroundColor(.secondary)
        .lineLimit(1)
        .truncationMode(.middle)
        .help(session.projectPath)

      Divider()

      // Monitoring panel content (reuses existing component)
      SessionMonitorPanel(state: state)
    }
    .padding(12)
    .background(Color.gray.opacity(0.05))
    .cornerRadius(8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(statusBorderColor, lineWidth: 1)
    )
  }

  // MARK: - Header

  private var header: some View {
    HStack {
      // Session ID
      Text(session.shortId)
        .font(.system(.caption, design: .monospaced))
        .foregroundColor(.brandPrimary)
        .fontWeight(.medium)

      // Branch name
      if let branch = session.branchName {
        Text("[\(branch)]")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      // Connect button
      Button(action: onConnect) {
        Image(systemName: "terminal")
          .font(.caption)
          .foregroundColor(.brandPrimary)
      }
      .buttonStyle(.plain)
      .help("Open in Terminal")

      // Stop monitoring button
      Button(action: onStopMonitoring) {
        Image(systemName: "xmark.circle.fill")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .buttonStyle(.plain)
      .help("Stop monitoring")
    }
  }

  // MARK: - Status Border

  private var statusBorderColor: Color {
    guard let state = state else { return .clear }
    switch state.status {
    case .awaitingApproval:
      return .yellow.opacity(0.5)
    case .executingTool, .thinking:
      return .orange.opacity(0.3)
    default:
      return .clear
    }
  }
}

// MARK: - Preview

#Preview {
  VStack(spacing: 16) {
    // Active session
    MonitoringCardView(
      session: CLISession(
        id: "e1b8aae2-2a33-4402-a8f5-886c4d4da370",
        projectPath: "/Users/james/git/ClaudeCodeUI",
        branchName: "main",
        isWorktree: false,
        lastActivityAt: Date(),
        messageCount: 42,
        isActive: true
      ),
      state: SessionMonitorState(
        status: .executingTool(name: "Bash"),
        currentTool: "Bash",
        lastActivityAt: Date(),
        model: "claude-opus-4-20250514",
        recentActivities: [
          ActivityEntry(timestamp: Date(), type: .toolUse(name: "Bash"), description: "swift build")
        ]
      ),
      onStopMonitoring: {},
      onConnect: {}
    )

    // Awaiting approval
    MonitoringCardView(
      session: CLISession(
        id: "f2c9bbf3-3b44-5513-b9f6-997d5e5eb481",
        projectPath: "/Users/james/git/MyProject",
        branchName: "feature/auth",
        isWorktree: true,
        lastActivityAt: Date(),
        messageCount: 15,
        isActive: true
      ),
      state: SessionMonitorState(
        status: .awaitingApproval(tool: "git"),
        lastActivityAt: Date(),
        model: "claude-sonnet-4-20250514",
        recentActivities: []
      ),
      onStopMonitoring: {},
      onConnect: {}
    )

    // Loading state
    MonitoringCardView(
      session: CLISession(
        id: "a3d0ccg4-4c55-6624-c0g7-aa8e6f6fc592",
        projectPath: "/Users/james/Desktop",
        branchName: nil,
        isWorktree: false,
        lastActivityAt: Date(),
        messageCount: 5,
        isActive: false
      ),
      state: nil,
      onStopMonitoring: {},
      onConnect: {}
    )
  }
  .padding()
  .frame(width: 320)
}
