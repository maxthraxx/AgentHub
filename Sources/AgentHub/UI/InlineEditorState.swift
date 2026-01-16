//
//  InlineEditorState.swift
//  AgentHub
//
//  Created by Assistant on 1/16/26.
//

import SwiftUI

/// Observable state for the floating inline editor
@Observable @MainActor
final class InlineEditorState {
  /// Whether the editor is currently showing
  var isShowing: Bool = false

  /// The anchor point in window coordinates where the editor should appear
  var anchorPoint: CGPoint = .zero

  /// The line number that was clicked
  var lineNumber: Int = 0

  /// Which side of the diff was clicked ("left", "right", or "unified")
  var side: String = ""

  /// The file name being edited
  var fileName: String = ""

  /// Shows the editor at the specified position
  func show(at point: CGPoint, lineNumber: Int, side: String, fileName: String) {
    self.anchorPoint = point
    self.lineNumber = lineNumber
    self.side = side
    self.fileName = fileName
    self.isShowing = true
  }

  /// Dismisses the editor
  func dismiss() {
    isShowing = false
  }
}
