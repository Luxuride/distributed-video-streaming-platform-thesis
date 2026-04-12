#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUBMODULE_PATH="${ROOT_DIR}/p2p-stream"
OUTPUT_DIR="${ROOT_DIR}/generated"
OUTPUT_FILE="${OUTPUT_DIR}/appendix-p2p-stream.tex"
TEMPLATE_FILE="${ROOT_DIR}/scripts/appendix-p2p-stream.template.tex"

mkdir -p "${OUTPUT_DIR}"

if [ ! -d "${SUBMODULE_PATH}/.git" ] && [ ! -f "${SUBMODULE_PATH}/.git" ]; then
  cat > "${OUTPUT_FILE}" <<'TEX'
\section{Implementation repository commit and pipeline}
\label{sec:appendix-implementation-commit}
Submodule \texttt{p2p-stream} is not available in this build environment.
TEX
  exit 0
fi

commit_hash="$(git -C "${SUBMODULE_PATH}" rev-parse HEAD)"
remote_url_raw="$(git -C "${SUBMODULE_PATH}" remote get-url origin)"

normalize_remote_url() {
  local raw="$1"
  if [[ "$raw" =~ ^git@github.com:(.+)$ ]]; then
    echo "https://github.com/${BASH_REMATCH[1]}"
    return
  fi
  if [[ "$raw" =~ ^ssh://git@github.com/(.+)$ ]]; then
    echo "https://github.com/${BASH_REMATCH[1]}"
    return
  fi
  if [[ "$raw" =~ ^https?://github.com/(.+)$ ]]; then
    echo "https://github.com/${BASH_REMATCH[1]}"
    return
  fi
  echo "$raw"
}

repo_url="$(normalize_remote_url "${remote_url_raw}")"
repo_url="${repo_url%.git}"

commit_url="${repo_url}/commit/${commit_hash}"
action_run_id="${APPENDIX_ACTION_RUN_ID:-${GITHUB_RUN_ID:-}}"
if [ -n "${action_run_id}" ]; then
  workflow_runs_url="${repo_url}/actions/runs/${action_run_id}"
else
  workflow_runs_url="${repo_url}/actions/workflows/rust.yml"
fi

if [ ! -f "${TEMPLATE_FILE}" ]; then
  echo "Template file not found: ${TEMPLATE_FILE}" >&2
  exit 1
fi

template_content="$(cat "${TEMPLATE_FILE}")"
output_content="${template_content//__COMMIT_URL__/${commit_url}}"
output_content="${output_content//__WORKFLOW_RUNS_URL__/${workflow_runs_url}}"

printf '%s\n' "${output_content}" > "${OUTPUT_FILE}"
