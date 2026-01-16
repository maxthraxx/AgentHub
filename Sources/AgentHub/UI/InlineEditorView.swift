//
//  InlineEditorView.swift
//  AgentHub
//
//  Created by Assistant on 1/16/26.
//

import SwiftUI
import AppKit

/// A compact floating text editor for asking questions about specific diff lines.
/// Appears below clicked lines in the diff view.
struct InlineEditorView: View {

  // MARK: - Properties

  let lineNumber: Int
  let side: String
  let fileName: String
  let onSubmit: (String) -> Void
  let onDismiss: () -> Void

  @State private var text: String = ""
  @FocusState private var isFocused: Bool

  private let placeholder = "Ask about this line..."

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      // Header with line context
      headerView

      Divider()

      // Input area
      VStack(alignment: .leading, spacing: 6) {
        textEditorView
        controlsRow
      }
      .padding(10)
    }
    .frame(width: 320)
    .background(Color(NSColor.controlBackgroundColor))
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    .overlay(
      RoundedRectangle(cornerRadius: 10)
        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
    )
    .onAppear {
      isFocused = true
    }
  }

  // MARK: - Header

  private var headerView: some View {
    HStack(spacing: 6) {
      // Line context
      HStack(spacing: 4) {
        Image(systemName: "text.line.first.and.arrowtriangle.forward")
          .font(.system(size: 11))
          .foregroundColor(.brandPrimary)

        Text("Line \(lineNumber)")
          .font(.system(.caption, design: .monospaced, weight: .medium))

        Text("(\(sideLabel))")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      // Close button
      Button(action: onDismiss) {
        Image(systemName: "xmark.circle.fill")
          .font(.system(size: 14))
          .foregroundColor(.secondary)
      }
      .buttonStyle(.plain)
      .help("Close (Esc)")
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
  }

  private var sideLabel: String {
    switch side {
    case "left": return "old"
    case "right": return "new"
    default: return side
    }
  }

  // MARK: - Text Editor

  private var textEditorView: some View {
    ZStack(alignment: .topLeading) {
      TextEditor(text: $text)
        .scrollContentBackground(.hidden)
        .focused($isFocused)
        .font(.system(.body, design: .default))
        .frame(minHeight: 40, maxHeight: 80)
        .fixedSize(horizontal: false, vertical: true)
        .padding(6)
        .onKeyPress { key in
          handleKeyPress(key)
        }

      if text.isEmpty {
        Text(placeholder)
          .font(.body)
          .foregroundColor(.secondary)
          .padding(.horizontal, 10)
          .padding(.vertical, 14)
          .allowsHitTesting(false)
      }
    }
    .background(
      RoundedRectangle(cornerRadius: 6)
        .fill(Color(NSColor.textBackgroundColor))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 6)
        .stroke(isFocused ? Color.brandPrimary.opacity(0.5) : Color(NSColor.separatorColor), lineWidth: 1)
    )
  }

  // MARK: - Controls Row

  private var controlsRow: some View {
    HStack {
      // Hint text
      Text("Enter to send")
        .font(.caption2)
        .foregroundColor(.secondary)

      Spacer()

      // Send button
      Button(action: submitMessage) {
        HStack(spacing: 3) {
          Text("Send")
            .font(.system(.caption, weight: .medium))
          Image(systemName: "arrow.up.circle.fill")
            .font(.system(size: 12))
        }
        .foregroundColor(isTextEmpty ? .secondary : .brandPrimary)
      }
      .buttonStyle(.plain)
      .disabled(isTextEmpty)
    }
  }

  // MARK: - Helpers

  private var isTextEmpty: Bool {
    text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private func submitMessage() {
    guard !isTextEmpty else { return }
    let messageText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    onSubmit(messageText)
  }

  private func handleKeyPress(_ key: KeyPress) -> KeyPress.Result {
    switch key.key {
    case .return:
      // Shift+Enter for new line
      if key.modifiers.contains(.shift) {
        return .ignored
      }
      // Enter to send
      submitMessage()
      return .handled

    case .escape:
      onDismiss()
      return .handled

    default:
      return .ignored
    }
  }
}

// MARK: - Preview

#Preview {
  InlineEditorView(
    lineNumber: 42,
    side: "right",
    fileName: "Example.swift",
    onSubmit: { message in
      print("Submitted: \(message)")
    },
    onDismiss: {
      print("Dismissed")
    }
  )
  .padding(40)
  .background(Color.gray.opacity(0.2))
}
