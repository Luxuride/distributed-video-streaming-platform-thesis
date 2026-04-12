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
commit_hash_short="$(git -C "${SUBMODULE_PATH}" rev-parse --short=8 HEAD)"
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

commit_url="${repo_url}/tree/${commit_hash}"
commit_url_short="${repo_url}/tree/${commit_hash_short}"
commit_url_base="${repo_url}/tree/"
commit_hash_breakable="$(printf '%s' "${commit_hash}" | sed 's/.\{8\}/&\\\\allowbreak{}/g')"
commit_url_breakable="${commit_url_base}${commit_hash_breakable}"
action_run_id="${APPENDIX_ACTION_RUN_ID:-${GITHUB_RUN_ID:-}}"
if [ -n "${action_run_id}" ]; then
  workflow_runs_url_base="${repo_url}/actions/runs/"
  workflow_runs_url="${workflow_runs_url_base}${action_run_id}"
else
  workflow_runs_url_base="${repo_url}/actions/workflows/"
  workflow_runs_url="${workflow_runs_url_base}rust.yml"
fi

if [ ! -f "${TEMPLATE_FILE}" ]; then
  echo "Template file not found: ${TEMPLATE_FILE}" >&2
  exit 1
fi

template_content="$(cat "${TEMPLATE_FILE}")"
output_content="${template_content//__COMMIT_URL__/${commit_url}}"
output_content="${output_content//__COMMIT_URL_SHORT__/${commit_url_short}}"
output_content="${output_content//__COMMIT_URL_BASE__/${commit_url_base}}"
output_content="${output_content//__COMMIT_HASH_SHORT__/${commit_hash_short}}"
output_content="${output_content//__COMMIT_HASH_BREAKABLE__/${commit_hash_breakable}}"
output_content="${output_content//__COMMIT_URL_BREAKABLE__/${commit_url_breakable}}"
output_content="${output_content//__WORKFLOW_RUNS_URL_BASE__/${workflow_runs_url_base}}"
output_content="${output_content//__WORKFLOW_RUNS_URL__/${workflow_runs_url}}"

printf '%s\n' "${output_content}" > "${OUTPUT_FILE}"
