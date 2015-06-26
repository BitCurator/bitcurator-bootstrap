bitcurator-bootstrap: Build, upgrade, and configuration scripts for the BitCurator Environment
---------------------------------------------------------------------------------------------------

# Building the BitCurator Environment

The bc-boostrap.sh shell script assists in building the BitCurator environment from scratch.
It may also be used to upgrade an existing instance of a BitCurator environment, although this
is subject to ongoing testing.

# How to run

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

# Time to build

The BitCurator environment depends on hundreds of libraries and software tools, some of
which must be compiled from source. Be patient! For reference, the build process takes
nearly 45 minutes on a circa-2015 Macbook Pro.

# WARNING!

The bootstrap script is in development. Do not use it in production environments!


For general project information, please visit:

<http://wiki.bitcurator.net/>

