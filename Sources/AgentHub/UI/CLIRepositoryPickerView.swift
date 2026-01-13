//
//  CLIRepositoryPickerView.swift
//  AgentHub
//
//  Created by Assistant on 1/10/26.
//

import SwiftUI

// MARK: - CLIRepositoryPickerView

/// Button to add a new repository with directory picker
public struct CLIRepositoryPickerView: View {
  let onAddRepository: () -> Void

  public init(onAddRepository: @escaping () -> Void) {
    self.onAddRepository = onAddRepository
  }

  public var body: some View {
    Button(action: onAddRepository) {
      HStack(spacing: 12) {
        ZStack {
          Circle()
            .fill(Color.brandPrimary.opacity(0.18))
            .frame(width: 28, height: 28)
          Image(systemName: "plus")
            .font(.caption)
            .foregroundColor(.brandPrimary)
        }

        VStack(alignment: .leading, spacing: 2) {
          Text("Add Repository")
            .font(.system(.subheadline, design: .rounded))
            .fontWeight(.semibold)
            .foregroundColor(.primary)
          Text("Pick a local git project to monitor")
            .font(.system(.caption2, design: .rounded))
            .foregroundColor(.secondary)
        }

        Spacer()

        Image(systemName: "folder.badge.plus")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding(12)
      .agentHubRow(isHighlighted: true)
    }
    .buttonStyle(.plain)
    .help("Select a git repository to monitor CLI sessions")
  }
}

// MARK: - Preview

#Preview {
  VStack(spacing: 16) {
    CLIRepositoryPickerView(onAddRepository: { print("Add repository") })
  }
  .padding()
  .frame(width: 350)
}
