bitcurator-bootstrap: Build, upgrade, and configuration scripts for the BitCurator Environment
---------------------------------------------------------------------------------------------------

# Building the BitCurator Environment

The bc-boostrap.sh shell script assists in building the BitCurator environment from scratch.
It may also be used to upgrade an existing instance of a BitCurator environment, although this
is subject to ongoing testing.

# Clean Installation

The bc-bootstap.sh assumes a Ubuntu 14.04LTS environment. It has not been tested on any other
versions of Ubuntu. The environment must have the "git" package installed to checkout this
repository. When running in a VM, any extensions (for example, the VirtualBox extensions) should
be installed prior to running this script.

To checkout, enter the following in a terminal.

git clone https://github.com/bitcurator/bitcurator-bootstrap

To run, enter the following in the bitcurator-bootstrap directory:

sudo ./bc-bootstrap.sh -s -i -y

This will tell the script to skin the environment, install all packages, and continue
without prompting the user (even if failures are encountered).

The script requires one interaction from the user (near the end of the build) to
select the correct Plymouth theme to "skin" then environment for BitCurator. When
you see the line:

"There are 4 choices for the alternative default.plymouth (providing /lib/plymouth/themes/default.plymouth)."

and a list of choices, type the "1" key and hit enter. The script should now complete.

# Upgarding existing BitCurator VMs or Installs

More info on this soon...

# Additional Notes

The BitCurator environment depends on hundreds of libraries and software tools, some of
which must be compiled from source. Be patient! For reference, the build process takes
nearly 45 minutes on a circa-2015 Macbook Pro.

# WARNING!

The bootstrap script is in active development. We recommend that you do not use it to upgrade
production environments at this time.

For general project information, please visit:

<http://wiki.bitcurator.net/>

