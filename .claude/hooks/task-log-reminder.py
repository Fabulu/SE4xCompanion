#!/usr/bin/env python3
"""Task log reminder hook. Gentle nudge on every user prompt."""
import json
import sys

REMINDER = "If you are in an active run, consider whether you have updated TASK_LOG.md with your recent action(s)."

try:
    output = {
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": REMINDER,
        }
    }
    print(json.dumps(output))
except Exception:
    pass
sys.exit(0)
