#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'This setup step must run as root.' >&2; exit 1; }
# Login belongs to the runner user, not root. Do not inherit API credentials.
as_runner() {
  runuser -l autovps -c 'env -u OPENAI_API_KEY -u CODEX_API_KEY -u CODEX_ACCESS_TOKEN -u OPENAI_IDENTITY_TOKEN_FILE -u OPENAI_WORKLOAD_IDENTITY_PROVIDER codex '"$1"
}
status=$(as_runner 'login status' 2>&1 || true)
if printf '%s' "$status" | grep -qi 'logged in using chatgpt'; then
  echo 'Codex ChatGPT subscription login is already configured for autovps.'
  exit 0
fi
echo 'Connecting Codex to your ChatGPT subscription.'
echo 'Open the browser link shown below and enter the one-time code.'
echo 'The installer will wait for you to finish. Do not share the code.'
if ! as_runner 'login --device-auth'; then
  echo 'Login did not finish. Enable device-code login in ChatGPT security settings if needed, then rerun this installer.' >&2
  exit 1
fi
status=$(as_runner 'login status' 2>&1)
if ! printf '%s' "$status" | grep -qi 'logged in using chatgpt'; then
  echo 'ChatGPT authentication could not be confirmed; setup is incomplete.' >&2
  exit 1
fi
echo 'ChatGPT subscription connected successfully.'
