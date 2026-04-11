#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: download-github-artifact.sh --artifact-name NAME --output-path PATH [--repo owner/repo] [--source-path PATH]

Downloads the newest successful GitHub Actions artifact matching NAME for the
HEAD commit of the source repository. If the artifact cannot be found or the
environment is missing required tooling, the script exits successfully without
creating an output file.
EOF
}

artifact_name=""
output_path=""
repo="Luxuride/p2p-stream"
source_path="p2p-stream"

while [ $# -gt 0 ]; do
  case "$1" in
    --artifact-name)
      artifact_name="${2:-}"
      shift 2
      ;;
    --output-path)
      output_path="${2:-}"
      shift 2
      ;;
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    --source-path)
      source_path="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ -z "${artifact_name}" ] || [ -z "${output_path}" ]; then
  echo "--artifact-name and --output-path are required" >&2
  usage >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is not available on this runner; skipping ${artifact_name} download."
  exit 0
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "GITHUB_TOKEN is not set; skipping ${artifact_name} download."
  exit 0
fi

rm -f "${output_path}"

commit_sha="$(git -C "${source_path}" rev-parse HEAD)"
runs_url="https://api.github.com/repos/${repo}/actions/runs?head_sha=${commit_sha}&status=success&per_page=30"

runs_json="$(curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" "${runs_url}" || true)"
if [ -z "${runs_json}" ]; then
  echo "No workflow runs response for ${repo} commit ${commit_sha}."
  exit 0
fi

run_id="$(printf '%s' "${runs_json}" | jq -r '.workflow_runs[] | select(.artifacts_url != null) | .id' | head -n 1)"
if [ -z "${run_id}" ] || [ "${run_id}" = "null" ]; then
  echo "No successful workflow run with artifacts found for ${repo} commit ${commit_sha}."
  exit 0
fi

artifacts_url="https://api.github.com/repos/${repo}/actions/runs/${run_id}/artifacts?per_page=100"
artifacts_json="$(curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" "${artifacts_url}" || true)"
if [ -z "${artifacts_json}" ]; then
  echo "No artifacts response for run ${run_id}."
  exit 0
fi

artifact_pairs="$(printf '%s' "${artifacts_json}" | jq -r --arg artifact_name "${artifact_name}" '
  .artifacts[]
  | select(.expired == false and .name == $artifact_name)
  | "\(.name) \(.archive_download_url)"
')"
if [ -z "${artifact_pairs}" ]; then
  echo "No downloadable ${artifact_name} artifact found for run ${run_id}."
  exit 0
fi

printf '%s\n' "${artifact_pairs}" | while IFS=' ' read -r found_name artifact_url; do
  [ -z "${found_name}" ] && continue

  curl -fsSL \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "${artifact_url}" \
    -o "${output_path}"

  if [ ! -s "${output_path}" ]; then
    echo "Downloaded artifact ${found_name} is empty; removing file."
    rm -f "${output_path}"
  fi
done

echo "Downloaded ${artifact_name} for commit ${commit_sha}."