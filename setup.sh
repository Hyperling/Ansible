#!/bin/bash
# Script to initialize a system into Ansible collection.

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

echo "Running ansible-pull..."
sudo ansible-pull -U https://github.com/Hyperling/ansible.git --checkout main
echo "Pulled!"

echo "Mounting all drives..."
mount -a
echo "Mounted!"

echo "Don't forget to set any new users' passwords!"

echo "We're done!"

exit 0
