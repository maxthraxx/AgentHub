# AgentHub

A macOS SwiftUI library for real-time monitoring and management of Claude Code CLI sessions.

## Prerequisites

- **macOS 14.0+**
- **[Claude Code CLI](https://claude.ai/claude-code)** installed and authenticated
- **Xcode 15+** (for integration)

## Installation

Add AgentHub to your Swift Package Manager dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/jamesrochabrun/AgentHub", from: "1.0.0")
]
```

Then add to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["AgentHub"]
)
```

## How It Works

### Session Discovery

AgentHub reads Claude Code session data from:

```
~/.claude/projects/{encoded-path}/{sessionId}.jsonl
```

Each session is a JSONL file containing message history, tool usage, and token metrics. AgentHub monitors these files in real-time using file system watchers.

### Claude CLI Integration

AgentHub can launch Claude Code sessions via Terminal:

- **Resume session:** `claude -r {sessionId}`
- **New session:** Opens Claude in a specified directory

## Integration

```swift
import AgentHub
import SwiftUI

struct ContentView: View {
    var body: some View {
        CLISessionsListView()
    }
}
```

The `CLISessionsListView` provides the complete UI - a split view with repository browser and session monitoring panel.

## User Experience

### Left Panel: Repository Browser

- Add repositories via folder picker (persisted in UserDefaults)
- Hierarchical tree showing:
  - Repositories
  - Git worktrees
  - Sessions (with branch, message count, last activity)
- Actions per session:
  - Monitor (watch real-time updates)
  - Resume (launch Terminal with `claude -r`)
  - Open new session
  - Copy session ID

### Right Panel: Monitoring Dashboard

- Active sessions with real-time metrics:
  - Token usage (input/output/cache)
  - Current status (thinking, executing tool, awaiting approval, idle)
  - Model and duration
  - Cost estimation
- Toggle monitoring per session

### Code Changes View

- Full-screen diff viewer for all file modifications
- Shows Edit, Write, and MultiEdit tool calls
- File-by-file navigation
- Unified diff rendering via PierreDiffsSwift

### Worktree Management

- Create new git worktrees from the UI
- Select base branch, specify new branch name
- Automatic directory setup

### Notifications

- Alert sound when a tool awaits approval (configurable 5-second timeout)
- Visual status indicators

## Session States

| Status | Description |
|--------|-------------|
| Thinking | Claude is processing |
| Executing Tool | Running a tool call |
| Awaiting Approval | Tool requires user confirmation |
| Waiting for User | Awaiting input |
| Idle | Session inactive |

## Dependencies

| Package | Purpose |
|---------|---------|
| ClaudeCodeSDK | Claude CLI configuration and launch |
| PierreDiffsSwift | Diff rendering |

## Architecture

```
AgentHub/
├── Models/           # Data structures (CLISession, SessionMonitorState)
├── Services/         # Core logic (file watching, parsing, git operations)
├── ViewModels/       # UI state management
├── UI/               # SwiftUI views
└── Utils/            # Git detection helpers
```

Key services:
- `CLISessionMonitorService` - Main orchestrator (Swift actor)
- `SessionFileWatcher` - Real-time JSONL file monitoring
- `GitWorktreeService` - Worktree creation/management
- `TerminalLauncher` - Claude CLI invocation

## License

MIT
