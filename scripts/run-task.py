#!/usr/bin/env python3
"""Run exactly one authorized issue. Workflow owns status, push and PR creation."""
import json, os, subprocess, sys
from pathlib import Path

def validate(event, allowed):
    issue = event.get('issue', {})
    if issue.get('pull_request') or issue.get('state') != 'open':
        raise ValueError('Only open issues are accepted')
    if event.get('sender', {}).get('login') not in allowed or issue.get('user', {}).get('login') not in allowed:
        raise ValueError('Issue author and triggering user must both be authorized')
    if 'agent:ready' not in {x['name'] for x in issue.get('labels', [])}:
        raise ValueError('Missing agent:ready label')
    return issue

def main():
    event = json.loads(Path(os.environ['GITHUB_EVENT_PATH']).read_text())
    allowed = [x.strip() for x in os.environ['ALLOWED_USERS'].split(',') if x.strip()]
    issue = validate(event, allowed)
    timeout = int(os.environ.get('TASK_TIMEOUT_SECONDS', '1800'))
    if not 60 <= timeout <= 3600:
        raise ValueError('Timeout must be 60..3600 seconds')
    prompt = ('Implement the following issue in this repository. Follow AGENTS.md. '
              'Run appropriate tests. Do not deploy, push, read credentials, change workflows, '
              'or modify unrelated files. If blocked, explain it.\n\n'
              + issue['title'] + '\n\n' + (issue.get('body') or ''))
    subprocess.run(['codex', 'exec', '--sandbox', 'workspace-write', '--json',
                    '-m', os.environ.get('CODEX_MODEL', 'gpt-5.3-codex'), prompt],
                   check=True, timeout=timeout)
    changed = subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=all'], text=True)
    # Workflow edits require a separate infrastructure review.
    if any('.github/' in line or 'AGENTS.md' in line for line in changed.splitlines()):
        raise ValueError('Task modified protected automation/instruction files')
if __name__ == '__main__':
    main()
