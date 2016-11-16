bitcurator-bootstrap: Build, upgrade, and configuration scripts for the BitCurator Environment
---------------------------------------------------------------------------------------------------

# Building the BitCurator environment

The bc-boostrap.sh shell script assists in building releases of the BitCurator environment. The script automates the majority of the process of preparing a clean Ubuntu 16.04.1LTS install for testing and respin as a BitCurator release.

This README includes basic information on how to use the script. We recommend that it is only used by developers or community members actively contributing to or maintaining the project. You may wish to visit https://github.com/bitcurator/bitcurator-distro-main/ for additional information on getting started.

Looking for the latest release? You can find it at:

https://wiki.bitcurator.net/

# Installation

The bc-bootstap.sh script expects to find itself in a Ubuntu 16.04.1LTS environment. It has not been tested on any other versions of Ubuntu. The environment must have the **git** package installed to checkout this repository. When running in a VM, any extensions (for example, the VirtualBox extensions) should be installed prior to running this script.

Once you have a clean Ubuntu 16.04.1LTS environment running as a VM (or on a host), install **dkms**. You must perform this step in order for the VirtualBox extensions to be automatically built for all future kernels that may be automatically downloaded and installed by Ubuntu:

```shell
sudo apt-get install dkms
```

Now, install the VirtualBox extensions using the "Insert Guest Additions CD Image..." entry in the VirtualBox "Devices" menu.

To check out the code, make sure you have git installed. Enter the following in a terminal:

```shell
sudo apt-get install git
git clone https://github.com/bitcurator/bitcurator-bootstrap
```

To run, enter the following inside the bitcurator-bootstrap directory:

```shell
sudo ./bc-bootstrap.sh -s -i -y
```

This will tell the script to skin the environment, install all packages, and continue without prompting the user (even if failures are encountered).

The script should eventually terminate. You must run the command:

```shell
sudo reboot
```
and hit enter to reboot. Once the environment has rebooted, you should be logged in to a desktop that displays several BitCurator environment icons, the BitCurator logo as the background, and the write-blocking logo in the top right menu bar. If one or more of these things does not happen, something has gone wrong. You can review the **bitcurator-install.log** file in **/home/bcadmin** to determine where the failure may have occurred.

# License(s)

The BitCurator logo, BitCurator project documentation, and other non-software products of the BitCurator team are subject to the the Creative Commons Attribution 4.0 Generic license (CC By 4.0).

Unless otherwise indicated, software items in this repository are distributed under the terms of the GNU General Public License, Version 3. See the text file "COPYING" for further details about the terms of this license.

In addition to software produced by the BitCurator team, BitCurator packages and modifies open source software produced by other developers. Licenses and attributions are retained here where applicable.

