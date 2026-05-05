#!/usr/bin/env bash
# Returns the current git worktree name for the active tmux pane's directory.
# If in the main worktree, shows the repo name. If in a linked worktree, shows the worktree folder name.
# Shows nothing if not in a git repo.

pane_path="$1"
cd "$pane_path" 2>/dev/null || exit 0

# Check if we're in a git repo at all
git rev-parse --is-inside-work-tree &>/dev/null || exit 0

# Get the worktree root
worktree_root="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$worktree_root" ] && exit 0

# Get the worktree folder name
worktree_name="$(basename "$worktree_root")"

# Get the branch for extra context
branch="$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"

echo " ${worktree_name} (${branch})"
