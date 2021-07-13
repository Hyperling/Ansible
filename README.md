# ansible
Getting real with system management via ansible-pull.

## Disclaimer
This setup is specific tom the maintainer's devices and needs. You're welcome to use it as an example for your needs, but do not expect it to work as-is.

## Currently Supported Linux Systems
### Debian Family
#### Debian
But only if using a recent enough version of Ansible. `pip` likely has a better version than `apt`.
#### Ubuntu
100%
#### Pop!_OS
100%
#### Mint
But not really used, just tested once for fun.
#### Parrot Security OS (MATE)
Still testing, but so far so good!

### Arch Family
#### Manjaro
100% at some point.

## Currently Supported Unix Systems
### FreeBSD
100% but untested since 12.1.
Software choices are slightly more limited since not flatpak-enabled.

## Waiting To Be Tested
### FreeBSD 13
### Kali Linux
### Arch Linux ARM 
Specifically for the Pinephone.
### Arch Linux x86
Would be great to have Arch get built up by this. Used for many years but left after update problems due to a long computer hiatus.

## Future Goals
Make the preferred user's name per-device, specified in the hosts file, rather than the hard-coded `ling`.

Eventually some of the scripts and install files will be put into the files folder. This will allow initializing systems outside of the maintainer's home network. 

There may also be a refactor of task-specific facts to be in their task file so that some playbooks can be more self-sufficient and be provided to the community without hacking. The original goal was to never define facts in tasks, but the benefit has yet to be seen for some tasks. Shared facts will definitely continue to exist under the facts tree.
