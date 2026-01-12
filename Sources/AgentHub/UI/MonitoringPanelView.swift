//
//  MonitoringPanelView.swift
//  AgentHub
//
//  Created by Assistant on 1/11/26.
//

import SwiftUI

// MARK: - MonitoringPanelView

/// Right panel view showing all monitored sessions
public struct MonitoringPanelView: View {
  @Bindable var viewModel: CLISessionsViewModel

  public init(viewModel: CLISessionsViewModel) {
    self.viewModel = viewModel
  }

  public var body: some View {
    VStack(spacing: 0) {
      // Header
      header

      Divider()

      // Content
      if viewModel.monitoredSessionIds.isEmpty {
        emptyState
      } else {
        monitoredSessionsList
      }
    }
    .frame(minWidth: 300)
  }

  // MARK: - Header

  private var header: some View {
    HStack {
      Image(systemName: "eye.fill")
        .foregroundColor(.brandPrimary)
      Text("Monitoring")
        .font(.headline)

      Spacer()

      // Count badge
      if !viewModel.monitoredSessionIds.isEmpty {
        Text("\(viewModel.monitoredSessionIds.count)")
          .font(.caption)
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .background(Color.brandPrimary.opacity(0.1))
          .foregroundColor(.brandPrimary)
          .cornerRadius(10)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(spacing: 12) {
      Image(systemName: "eye.slash")
        .font(.largeTitle)
        .foregroundColor(.secondary.opacity(0.5))

      Text("No Sessions Monitored")
        .font(.headline)
        .foregroundColor(.secondary)

      Text("Click the monitor button on a session to start tracking its activity in real-time.")
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }

  // MARK: - Monitored Sessions List

  private var monitoredSessionsList: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(viewModel.monitoredSessions, id: \.session.id) { item in
          MonitoringCardView(
            session: item.session,
            state: item.state,
            onStopMonitoring: {
              viewModel.stopMonitoring(session: item.session)
            },
            onConnect: {
              if let error = viewModel.connectToSession(item.session) {
                print("Failed to connect: \(error.localizedDescription)")
              }
            }
          )
        }
      }
      .padding(12)
    }
  }
}

// MARK: - Preview

#Preview {
  let service = CLISessionMonitorService()
  let viewModel = CLISessionsViewModel(monitorService: service)

  return MonitoringPanelView(viewModel: viewModel)
    .frame(width: 350, height: 500)
}
