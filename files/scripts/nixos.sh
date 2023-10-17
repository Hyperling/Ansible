#!/usr/bin/env bash
# Script to consistently install configuration.nix.
# To be called by Ansible via setup.sh and nixos.yml, as well as CLI by users.

## Variables ##

DIR="$(dirname -- "${BASH_SOURCE[0]}")"
PROG="$(basename -- "${BASH_SOURCE[0]}")"

nixos_working_dir=~/nixos-config-deleteme
nixos_working_exe=activate.sh

## Functions ##

function usage {
	echo -e "\nUsage: $PROG -b BRANCH" >&2
	cat <<- EOF
		Run a setup script for NixOS based on the https://github.com/Hyperling/NixOS project.

		Parameters:
		  -b BRANCH: The branch which should be installed, likely 'main' or 'dev'.
	EOF
	echo ""
	exit $1
}

function cleanup {
	sh -c "rm -rfv $nixos_working_dir" >/dev/null
}

## Parameters ##

while getopts ":b:h" opt; do
	case $opt in
		b) branch="$OPTARG" ;;
		h) usage 0 ;;
		*) echo "ERROR: Parameter $OPTARG was not recognized." && usage 1 ;;
	esac
done

if [[ -z $branch ]]; then
	echo "ERROR: Branch is required. $branch" >&2
	usage 2
fi

## Main ##

cleanup

# Install the Hyperling NixOS configurations.
git clone https://github.com/Hyperling/NixOS --branch $branch $nixos_working_dir
chmod 755 $nixos_working_dir/$nixos_working_exe
$nixos_working_dir/$nixos_working_exe

cleanup

exit 0
