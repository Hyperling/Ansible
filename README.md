# ansible
Getting real with system management via ansible-pull.

Per-system configuration is handled via local files to the provisioned machine,
rather than using a hosts file. This keeps future hosts private and allows
changing what's on the machine without code changes and releases. The files are
accessed via the show-config and edit-config aliases.

## Disclaimer
This setup is specific to the maintainer's devices and needs. You're welcome to
use it as an example for your needs, but do not expect it to work as-is.

## Currently Supported Linux Systems
### Debian Family
#### Debian
100%, but only if using a recent enough version of Ansible. `pip` usually has a
better version than `apt`.
#### Ubuntu
100%, both server and desktop.
#### Pop!_OS
100%, have not used for a while though.
#### Mint
100%, but not really used, just tested once for fun.
#### Parrot Security OS (MATE)
100% for a while, but OS did not serve maintainer's needs and 404 errors were
terrible while updating. Ubuntu Rolling Rhino filled the gap.

### Arch Family
#### Manjaro
100% at some point.

### Fedora Family
#### Fedora 35
Workstation: 100%
Server: 100%

## Suse Family
### openSUSE Tumbleweed v2022-02-17
Generic: 100%
Workstation: 100%

### openSUSE Leap 15.4
Generic: 100%
Workstation: Currently failing at `[Workstation | Linux | Flatpak Distro | Package Manager | Install From Repo]` with message `Problem: nothing provides libedataserver-1.2.so.24 needed by the to be installed evolution-data-server-32bit-3.34.4-3.3.1.x86_64`.

### NixOS
99%, still need to get Telegraf going and refactor local.yml but everything else
is working well. It is automatically implementing github.com/Hyperling/NixOS.

## Currently Supported Unix Systems
### FreeBSD 12, 13
100%, although GUI is not working completely on 13 yet (dash-to-dock doesn't compile).
Software choices are slightly more limited since not `flatpak`-enabled and not feeling a `ports` setup.

## Waiting To Be Tested
### Kali Linux
### Arch Linux ARM
Specifically for the Pinephone.
### Arch Linux x86
Would be great to have Arch get built up by this. Used for many years but left
after update problems due to a long computer hiatus.
### Fedora Mobile
Specifically for the Pinephone.

## Future Goals
Eventually some of the scripts and install files will be put into the files
folder. This will allow initializing systems outside of the maintainer's home
network.

There may also be a refactor of task-specific facts to be in their task file so
that some playbooks can be more self-sufficient and be provided to the community
without hacking. The original goal was to never define facts in tasks, but the
benefit has yet to be seen for some tasks. Shared facts will definitely continue
to exist under the facts tree.

## Other Notes
### Get Setup Values
Use this command to see the variables for a system:
`ansible localhost -m setup --connection=local`.