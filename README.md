bitcurator-bootstrap: Build, upgrade, and configuration scripts for the BitCurator Environment
---------------------------------------------------------------------------------------------------

# Building the BitCurator Environment

The bc-boostrap.sh shell script assists in building releases of the BitCurator environment.
It may be used in two ways, described in the sections below: (1) As a full bootstrap on top of
a clean Ubuntu 14.04.3LTS or 16.04LTS install, and (2) to upgrade existing BitCurator 
environments (planned for future releases).

# Clean Installation

The bc-bootstap.sh script expects to find itself in a Ubuntu 14.04LTS or Ubuntu 16.04LTS environment. 
It has not 
been tested on any other versions of Ubuntu. The environment must have the "git" package installed 
to checkout this repository. When running in a VM, any extensions (for example, the 
VirtualBox extensions) should be installed prior to running this script.

Once you have a "clean" Ubuntu 14.04LTS or Ubuntu 16.04LTS environment running as a VM, install 
dkms. You must perform this step in order for the VirtualBox extensions to be automatically 
built for all future kernels that may be automatically downloaded and installed by Ubuntu:

  * sudo apt-get install dkms

Now, install the VirtualBox extensions using the "Insert Guest Additions CD Image..." entry
in the VirtualBox "Devices" menu.

To check out the code, make sure you have git installed. Enter the following in a terminal:

  * sudo apt-get install git
  * git clone https://github.com/bitcurator/bitcurator-bootstrap

To run, enter the following inside the bitcurator-bootstrap directory:

  * sudo ./bc-bootstrap.sh -s -i -y

This will tell the script to skin the environment, install all packages, and continue
without prompting the user (even if failures are encountered).

The script requires one interaction from the user (near the end of the build) to
select the correct Plymouth theme to "skin" then environment for BitCurator. When
you see the line:

  "There are 4 choices for the alternative default.plymouth (providing /lib/plymouth/themes/default.plymouth)."

and a list of choices, type the "1" key and hit enter. The script should now complete.
Type "sudo reboot" and hit enter to reboot.

# Upgrading existing BitCurator VMs or Installs

Future versions of this script may support upgrade paths for previous Virtual Machine releases.
At present, please use this script only to create fresh environment instances.
