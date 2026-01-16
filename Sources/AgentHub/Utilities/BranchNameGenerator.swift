//
//  BranchNameGenerator.swift
//  AgentHub
//
//  Created by Assistant on 1/16/26.
//

import Foundation

/// Generates unique, memorable branch names to avoid naming conflicts
public enum BranchNameGenerator {
  // Fun, memorable adjectives
  static let adjectives = [
    // Animals/Nature
    "dancing", "cosmic", "flying", "sleepy", "mighty", "tiny", "giant", "swift",
    // Colors/Visual
    "purple", "golden", "silver", "neon", "sparkly", "glowing",
    // Personality
    "happy", "grumpy", "clever", "sneaky", "brave", "lazy", "fancy",
    // World locations inspired
    "alpine", "tropical", "arctic", "desert", "ocean", "forest"
  ]

  // Fun, memorable nouns
  static let nouns = [
    // Animals
    "penguin", "dragon", "unicorn", "phoenix", "koala", "panda", "octopus",
    // Food
    "banana", "taco", "pizza", "mango", "pretzel", "waffle",
    // Objects
    "rocket", "castle", "crystal", "compass", "lantern", "telescope",
    // Nature
    "thunder", "aurora", "comet", "volcano", "glacier"
  ]

  /// Generates a unique branch name: {module}-{adjective}-{noun}
  /// - Parameter moduleName: The name of the module/repository
  /// - Returns: A branch name like "agenthub-cosmic-penguin"
  public static func generate(moduleName: String) -> String {
    let adjective = adjectives.randomElement() ?? "random"
    let noun = nouns.randomElement() ?? "branch"
    let sanitizedModule = moduleName.lowercased()
      .replacingOccurrences(of: " ", with: "-")
    return "\(sanitizedModule)-\(adjective)-\(noun)"
  }
}
