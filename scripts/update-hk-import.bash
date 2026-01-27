#!/usr/bin/env bash

set -o errexit  # Exit on error
set -o nounset  # Exit on unset variable
set -o pipefail # Exit on pipe failure

if [[ "${TRACE:-}" == true ]]; then
	set -o xtrace # Trace the execution of the script (debug)
fi

declare -r script_name="${0##*/}"

function log_info() {
	echo -e "[${script_name}] ${1:-}"
}

function log_error() {
	echo -e "[${script_name}] ERROR: ${1:-}" >&2
}

function handle_error() {
	local -ri exit_code="$?"
	log_error "Exited with code ${exit_code}"
	exit "${exit_code}"
}
trap handle_error ERR

# Example import headers to be updated:
# amends "package://github.com/jdx/hk/releases/download/v1.34.0/hk@1.34.0#/Config.pkl"
# import "package://github.com/jdx/hk/releases/download/v1.34.0/hk@1.34.0#/Builtins.pkl"

function main() {
	local -r repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
	local -r config_path="${repo_root}/hk.pkl"
	if [[ ! -f "${config_path}" ]]; then
		log_error "Config file not found: ${config_path}"
		exit 1
	fi

	local -r hk_version="$(hk version | head -n 1)"

	log_info "Updating hk imports in ${config_path} to version ${hk_version}"

	local -r temp_path="$(mktemp)"
	{
		echo "amends \"package://github.com/jdx/hk/releases/download/v${hk_version}/hk@${hk_version}#/Config.pkl\""
		echo "import \"package://github.com/jdx/hk/releases/download/v${hk_version}/hk@${hk_version}#/Builtins.pkl\""
		tail -n +3 "${config_path}"
	} >"${temp_path}"

	mv "${temp_path}" "${config_path}"
}

main "$@"
