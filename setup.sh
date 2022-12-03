#!/bin/bash
# Script to initialize a system into Ansible collection.

## Global Variables ##

PROG=`basename $0`
LOCAL=`dirname $0`/local.yml
URL="https://github.com/Hyperling/ansible"

## Functions ##

# Accepts 1 parameter, it is used as the exit status.
function usage {
	cat <<- EOF
	  $PROG [-l] [-b branch_name] [-h]
	    Program to initialize synchronization with Hyperling's Ansible configuration.
	       $URL

	    Parameters:
	      -l : Run the local version associated with this setup.sh.
	      -b branch_name: Download and run a specific branch. Default is main.
	      -h : Display this help text
	EOF
	exit $1
}

## Parameter Parsing ##

while getopts ":lb:h" arg; do
	case $arg in
		l)
			local="Y"
			;;
		b)
			branch="$OPTARG"
			;;
		h)
			usage
			;;
		*)
			echo "ERROR: A parameter was not recognized. Please check your command and try again."
			usage 1
			;;
	esac
done

if [[ $branch == "" ]]; then
	branch="main"
fi

## Main ##

os="$(cat /etc/os-release)"
os="$os $(uname -a)"

echo "Making sure all necessary packages are installed..."
if [[ `which ansible > /dev/null; echo $?` != 0 ]]; then
	if [[ $os == *Debian* || $os == *Ubuntu* || $os == *"Pop!_OS"* || $os == *Mint* || $os == *Parrot* ]]; then
		sudo apt update
		sudo apt install -y ansible git <<< N
		sudo mkdir -p /etc/ansible
		sudo sh -c 'echo "localhost ansible_connection=local" > /etc/ansible/hosts'
	elif [[ $os == *FreeBSD* ]]; then
		sudo pkg install -y py38-ansible git
		sudo mkdir -p /usr/local/etc/ansible
		sudo sh -c 'echo "localhost ansible_connection=local" > /usr/local/etc/ansible/hosts'
	elif [[ $os == *Arch* || $os == *Manjaro* || $os == *Artix* ]]; then
		sudo pacman -Sy --noconfirm ansible git
		sudo mkdir -p /etc/ansible
		sudo sh -c 'echo "localhost ansible_connection=local" > /etc/ansible/hosts'
	elif [[ $os == *Darwin* ]]; then
		bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		echo "TESTING - EXIT!"
		exit 0
		brew install ansible git
	elif [[ $os == *Fedora* ]]; then
		sudo dnf install -y ansible git python3-libselinux
		sudo mkdir -p /etc/ansible
		sudo sh -c 'echo "localhost ansible_connection=local" > /etc/ansible/hosts'
	else
		echo -e "ERROR: OS not detected."
		echo -e "$os"
		exit 1
	fi
fi
echo "Installed!"

#echo "Adding Ansible Collections..."
#ansible-galaxy collection install community.general
#echo "Added!"

echo "Provisioning Ansible..."
if [[ $local == "Y" ]]; then
	sudo ansible-playbook $LOCAL
else
	sudo ansible-pull -U $URL.git --checkout $branch
fi
echo "Provisioned!"

echo "Mounting all drives..."
mount -a
echo "Mounted!"

echo "Don't forget to set any new users' passwords!"

echo "We're done!"

exit 0
