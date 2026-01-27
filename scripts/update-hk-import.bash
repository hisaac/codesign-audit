#!/usr/bin/env bash

set -o errexit  # Exit on error
set -o nounset  # Exit on unset variable
set -o pipefail # Exit on pipe failure

if [[ "${TRACE:-}" == true ]]; then
	set -o xtrace # Trace the execution of the script (debug)
fi

# Example import headers to be updated:
# amends "package://github.com/jdx/hk/releases/download/v1.34.0/hk@1.34.0#/Config.pkl"
# import "package://github.com/jdx/hk/releases/download/v1.34.0/hk@1.34.0#/Builtins.pkl"

function main() {
	local -r hk_version="$(hk version)"
	echo "Updating hk imports to version ${hk_version}..."
}

function handle_error() {
	local -ri exit_code="$?"
	local -r script_name="${0##*/}"
	echo -e "\n==> ${script_name} exited with code ${exit_code}"
}
trap handle_error ERR

main "$@"
