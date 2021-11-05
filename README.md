# ansible
Getting real with system management via ansible-pull.

## Disclaimer
This setup is specific to the maintainer's devices and needs. You're welcome to use it as an example for your needs, but do not expect it to work as-is.

## Currently Supported Linux Systems
### Debian Family
#### Debian
100%, but only if using a recent enough version of Ansible. `pip` usually has a better version than `apt`.
#### Ubuntu
100%, both server and desktop.
#### Pop!_OS
100%, have not used for a while though.
#### Mint
100%, but not really used, just tested once for fun.
#### Parrot Security OS (MATE)
100% for a while, but OS did not serve maintainer's needs and 404 errors were terrible while updating. Ubuntu Rolling Rhino filled the gap.

### Arch Family
#### Manjaro
100% at some point.

### Fedora Family
#### Fedora 35
In progress.

## Currently Supported Unix Systems
### FreeBSD 12, 13
100%, although GUI is not working completely on 13 yet (dash-to-dock doesn't compile).
Software choices are slightly more limited since not `flatpak`-enabled and not feeling a `ports` setup.

## Waiting To Be Tested
### Kali Linux
### Arch Linux ARM 
Specifically for the Pinephone.
### Arch Linux x86
Would be great to have Arch get built up by this. Used for many years but left after update problems due to a long computer hiatus.

## Future Goals
Make the preferred user's name per-device, specified in the hosts file, rather than the hard-coded `ling`.

Eventually some of the scripts and install files will be put into the files folder. This will allow initializing systems outside of the maintainer's home network. 

There may also be a refactor of task-specific facts to be in their task file so that some playbooks can be more self-sufficient and be provided to the community without hacking. The original goal was to never define facts in tasks, but the benefit has yet to be seen for some tasks. Shared facts will definitely continue to exist under the facts tree.
