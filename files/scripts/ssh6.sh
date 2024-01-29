#!/bin/bash
# 2024-01-28 Hyperling
# Make it a little easier to handle IPv6 addresses with SSH and SCP.

## Variables ##

DIR="$(dirname -- "${BASH_SOURCE[0]}")"
PROG="$(basename -- "${BASH_SOURCE[0]}")"
echo "Running '$DIR/$PROG'."

# Defaults
user="$LOGNAME"
port=22
output=""
receive="N"

## Functions ##

function usage {
	echo -n "$PROG -d DESTINATION [-p PORT] [-u USER] [-i INPUT] "
	echo "[-o OUTPUT] [-r] [-h]"
	cat <<- EOF
		Script around having to sometimes doing "[IPv6]" syntax.
		  -d : The IP address of the external system to connect to.
		  -u : User to connect as. Defaults to current user.
		  -p : Port which the external system is listening on.
		  -i : File or folder which needs sent. This is done recursively.
		         If this is not provided then only an SSH is done, not SCP.
		  -o : Location on the receiving end where things should land.
		         Defaults to :, meaning the foreign user's home directory.
		  -r : Receive a file to the local machine, rather than send a file out.
		  -h : Print this usage text.
	EOF
	exit $1
}

## Parameters ##

while getopts ":d:u:i:o:rh" opt; do
	case "$opt" in
		d) destination="$OPTARG" ;;
		u) user="$OPTARG" ;;
		p) port="$OPTARG" ;;
		i) input="$OPTARG" ;;
		o) output="$OPTARG" ;;
		r) receive="Y" ;;
		h) usage 0 ;;
		*) echo "ERROR: $OPTARG not recognized." >&2
			usage 1;;
	esac
done

## Validations ##

if [[ -z $input && -n $output ]]; then
	echo "ERROR: Output '$output' was provided but not input. $input" >&2
	usage 2
fi

## Main ##

if [[ -n $input ]]; then
	if [[ $receive == "N" ]]; then
		echo -n "Sending '$input' from localhost to '$user@$destination' "
		echo " at '$output' using port '$port'."
		scp -r -p$port "$user@[$destination]":"$input" "$output"
	elif [[ $receive == "Y" ]]; then
		echo -n "Receiving '$input' from '$user@$destination' "
		echo " to '$output' on localhost using port '$port'."
		scp -r -p$port "$input" "$user@[$destination]":"$output"
	else
		echo "ERROR: Receive variable is screwed up. $receive" >&2
	fi
else
	echo "No input file provided, connecting to destination."
	ssh -t $user@$destination
fi

## Finish ##

exit 0
