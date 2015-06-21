#!/bin/bash -

#
# bitcurator-bootstrap: Build, upgrade, and configuration scripts for the BitCurator Environment
# ----------------------------------------------------------------------------------------------
# <http://wiki.bitcurator.net>
#
# This script should be run using Ubuntu 14.04LTS or later. If you are building the
# environment as a VirtualBox virtual machine, please install the VirtualBox extension pack
# and reboot prior to running this script.
#
# WARNING! The bootstrap script is in development. Do not use it in production environments!
#
# Modified from sift-bootstrap for use with BitCurator, post-1.3.7
#
#
#===============================================================================
# vim: softtabstop=4 shiftwidth=4 expandtab fenc=utf-8 spell spelllang=en cc=81
#===============================================================================
#

#--- FUNCTION ----------------------------------------------------------------
# NAME: __function_defined
# DESCRIPTION: Checks if a function is defined within this scripts scope
# PARAMETERS: function name
# RETURNS: 0 or 1 as in defined or not defined
#-------------------------------------------------------------------------------
__function_defined() {
    FUNC_NAME=$1
    if [ "$(command -v $FUNC_NAME)x" != "x" ]; then
        echoinfo "Found function $FUNC_NAME"
        return 0
    fi
    
    echodebug "$FUNC_NAME not found...."
    return 1
}

#--- FUNCTION ----------------------------------------------------------------
# NAME: __strip_duplicates
# DESCRIPTION: Strip duplicate strings
#-------------------------------------------------------------------------------
__strip_duplicates() {
    echo $@ | tr -s '[:space:]' '\n' | awk '!x[$0]++'
}

#--- FUNCTION ----------------------------------------------------------------
# NAME: echoerr
# DESCRIPTION: Echo errors to stderr.
#-------------------------------------------------------------------------------
echoerror() {
    printf "${RC} * ERROR${EC}: $@\n" 1>&2;
}

#--- FUNCTION ----------------------------------------------------------------
# NAME: echoinfo
# DESCRIPTION: Echo information to stdout.
#-------------------------------------------------------------------------------
echoinfo() {
    printf "${GC} * STATUS${EC}: %s\n" "$@";
}

#--- FUNCTION ----------------------------------------------------------------
# NAME: echowarn
# DESCRIPTION: Echo warning informations to stdout.
#-------------------------------------------------------------------------------
echowarn() {
    printf "${YC} * WARN${EC}: %s\n" "$@";
}

#--- FUNCTION ----------------------------------------------------------------
# NAME: echodebug
# DESCRIPTION: Echo debug information to stdout.
#-------------------------------------------------------------------------------
echodebug() {
    if [ $_ECHO_DEBUG -eq $BS_TRUE ]; then
        printf "${BC} * DEBUG${EC}: %s\n" "$@";
    fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __apt_get_install_noinput
#   DESCRIPTION:  (DRY) apt-get install with noinput options
#-------------------------------------------------------------------------------
__apt_get_install_noinput() {
    apt-get install -y -o DPkg::Options::=--force-confold $@; return $?
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __apt_get_upgrade_noinput
#   DESCRIPTION:  (DRY) apt-get upgrade with noinput options
#-------------------------------------------------------------------------------
__apt_get_upgrade_noinput() {
    apt-get upgrade -y -o DPkg::Options::=--force-confold $@; return $?
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __pip_install_noinput
#   DESCRIPTION:  (DRY)
#-------------------------------------------------------------------------------
__pip_install_noinput() {
    pip install --upgrade $@; return $?
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __pip_install_noinput
#   DESCRIPTION:  (DRY)
#-------------------------------------------------------------------------------
__pip_pre_install_noinput() {
    pip install --pre --upgrade $@; return $?
}

__check_apt_lock() {
    lsof /var/lib/dpkg/lock > /dev/null 2>&1
    RES=`echo $?`
    return $RES
}


__enable_universe_repository() {
    if [ "x$(grep -R universe /etc/apt/sources.list /etc/apt/sources.list.d/ | grep -v '#')" != "x" ]; then
        # The universe repository is already enabled
        return 0
    fi

    echodebug "Enabling the universe repository"

    # Ubuntu versions higher than 12.04 do not live in the old repositories
    if [ $DISTRO_MAJOR_VERSION -gt 12 ] || ([ $DISTRO_MAJOR_VERSION -eq 12 ] && [ $DISTRO_MINOR_VERSION -gt 04 ]); then
        add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe" || return 1
    elif [ $DISTRO_MAJOR_VERSION -lt 11 ] && [ $DISTRO_MINOR_VERSION -lt 10 ]; then
        # Below Ubuntu 11.10, the -y flag to add-apt-repository is not supported
        add-apt-repository "deb http://old-releases.ubuntu.com/ubuntu $(lsb_release -sc) universe" || return 1
    fi

    add-apt-repository -y "deb http://old-releases.ubuntu.com/ubuntu $(lsb_release -sc) universe" || return 1

    return 0
}

__check_unparsed_options() {
    shellopts="$1"
    # grep alternative for SunOS
    if [ -f /usr/xpg4/bin/grep ]; then
        grep='/usr/xpg4/bin/grep'
    else
        grep='grep'
    fi
    unparsed_options=$( echo "$shellopts" | ${grep} -E '(^|[[:space:]])[-]+[[:alnum:]]' )
    if [ "x$unparsed_options" != "x" ]; then
        usage
        echo
        echoerror "options are only allowed before install arguments"
        echo
        exit 1
    fi
}

configure_cpan() {
    (echo y;echo o conf prerequisites_policy follow;echo o conf commit)|cpan > /dev/null
}

usage() {
    echo "usage"
    exit 1
}

install_ubuntu_14.04_deps() {
    echoinfo "Updating your APT Repositories ... "
    apt-get update >> $HOME/bitcurator-install.log 2>&1 || return 1

    echoinfo "Installing Python Software Properies ... "
    __apt_get_install_noinput software-properties-common >> $HOME/bitcurator-install.log 2>&1  || return 1

    echoinfo "Enabling Universal Repository ... "
    __enable_universe_repository >> $HOME/bitcurator-install.log 2>&1 || return 1

    #echoinfo "Enabling Elastic Repository ... "
    #wget -qO - "https://packages.elasticsearch.org/GPG-KEY-elasticsearch" | apt-key add - >> $HOME/sift-install.log 2>&1 || return 1
    #add-apt-repository "deb http://packages.elasticsearch.org/elasticsearch/1.5/debian stable main" >> $HOME/sift-install.log 2>&1 || return 1

    echoinfo "Adding Ubuntu Tweak Repository"
    add-apt-repository -y ppa:tualatrix/ppa  >> $HOME/bitcurator-install.log 2>&1 || return 1

    echoinfo "Adding Guymager Repository"
    wget -nH -rP /etc/apt/sources.list.d/ http://deb.pinguin.lu/pinguin.lu.list     
    wget -q http://deb.pinguin.lu/debsign_public.key -O- | sudo apt-key add -
    apt-get update
    #apt-get install guymager-beta

    echoinfo "Adding BitCurator Repository: $@"
    #add-apt-repository -y ppa:sift/$@  >> $HOME/sift-install.log 2>&1 || return 1

    echoinfo "Updating Repository Package List ..."
    apt-get update >> $HOME/bitcurator-install.log 2>&1 || return 1

    echoinfo "Upgrading all packages to latest version ..."
    __apt_get_upgrade_noinput >> $HOME/bitcurator-install.log 2>&1 || return 1

    return 0
}

install_ubuntu_14.04_packages() {
    packages="dkms 
g++ 
ant 
guymager-beta
libcrypto++9 
libssl-dev 
expat 
libexpat1-dev 
libfuse-dev 
libncurses5-dev 
libcurl4-openssl-dev 
libreadline-dev 
libmagic-dev 
flex 
gawk 
libpthread-stubs0-dev 
libcppunit-1.13-0 
libcppunit-dev 
libtool 
automake 
openjdk-7-jdk 
expect 
ghex 
gnome-system-tools 
gnome-panel 
gnome-search-tool 
hfsutils 
hfsutils-tcltk 
hfsplus 
hfsprogs 
dconf-tools 
libgtk2.0-dev 
xmount 
mercurial-common 
python-sphinx 
vim 
git 
equivs 
python2.7-dev 
python3 
python3-setuptools 
python3-dev 
python3-numpy 
uuid-dev 
libncursesw5-dev 
libbz2-dev 
clamav 
clamav-daemon 
clamtk 
sharutils 
smartmontools 
hdparm 
fdutils 
cifs-utils 
winbind 
subversion 
libarchive-dev 
nautilus-actions 
libxml2-dev 
libboost-dev 
libboost-test-dev 
libboost-program-options-dev 
libboost-system-dev 
libboost-filesystem-dev 
bison python3-pyqt4 
python3-sip-dev 
mysql-client 
libmyodbc 
unixodbc 
unixodbc-dev 
libmysqlclient-dev 
libexif-dev 
readpst 
recoll 
cdrdao 
dcfldd 
bchunk 
libimage-exiftool-perl 
python-tk 
python3-tk 
python-pyside 
python-compizconfig 
udisks 
libappindicator1 
unity-tweak-tool 
gnome-tweak-tool 
compizconfig-settings-manager 
gtkhash 
nautilus-scripts-manager 
fslint 
libgnomeui-0 
libgnomeui-dev 
cmake 
swig 
python-magic 
libtre-dev 
libtre5 
libudev-dev 
gddrescue 
gnome-sushi 
vlc 
autopoint 
libevent-dev 
python-pip 
python3-pip 
antiword 
openssh-server
maven
mediainfo 
libav-tools 
plymouth-theme-script 
mplayer 
tree
gstreamer0.10-plugins-ugly 
libxine1-ffmpeg 
gxine 
mencoder 
libdvdread4 
totem-mozilla 
icedax 
tagtool 
easytag 
id3tool 
lame 
nautilus-script-audio-convert 
libmad0 
mpg321 
libavcodec-extra"

# ubuntu-restricted-extras 
# Added to above list. May be removed depending on deployment.
#
#gstreamer0.10-plugins-ugly libxine1-ffmpeg gxine mencoder libdvdread4 totem-mozilla icedax tagtool easytag id3tool lame nautilus-script-audio-convert libmad0 mpg321 libavcodec-extra

    if [ "$@" = "dev" ]; then
        packages="$packages"
    elif [ "$@" = "stable" ]; then
        packages="$packages"
    fi

    for PACKAGE in $packages; do
        __apt_get_install_noinput $PACKAGE >> $HOME/bitcurator-install.log 2>&1
        ERROR=$?
        if [ $ERROR -ne 0 ]; then
            echoerror "Install Failure: $PACKAGE (Error Code: $ERROR)"
        else
            echoinfo "Installed Package: $PACKAGE"
        fi
    done

    return 0
}

install_ubuntu_14.04_pip_packages() {
    #pip_packages="rekall docopt python-evtx python-registry six construct pyv8 pefile analyzeMFT python-magic argparse unicodecsv"
    pip_packages="docopt python-evtx python-registry six configobj construct pyv8 pefile analyzeMFT python-magic argparse unicodecsv"
    pip_pre_packages="bitstring"

    if [ "$@" = "dev" ]; then
        pip_packages="$pip_packages"
    elif [ "$@" = "stable" ]; then
        pip_packages="$pip_packages"
    fi

    ERROR=0
    for PACKAGE in $pip_pre_packages; do
        CURRENT_ERROR=0
        echoinfo "Installed Python (pre) Package: $PACKAGE"
        __pip_pre_install_noinput $PACKAGE >> $HOME/bitcurator-install.log 2>&1 || (let ERROR=ERROR+1 && let CURRENT_ERROR=1)
        if [ $CURRENT_ERROR -eq 1 ]; then
            echoerror "Python Package Install Failure: $PACKAGE"
        fi
    done

    for PACKAGE in $pip_packages; do
        CURRENT_ERROR=0
        echoinfo "Installed Python Package: $PACKAGE"
        __pip_install_noinput $PACKAGE >> $HOME/bitcurator-install.log 2>&1 || (let ERROR=ERROR+1 && let CURRENT_ERROR=1)
        if [ $CURRENT_ERROR -eq 1 ]; then
            echoerror "Python Package Install Failure: $PACKAGE"
        fi
    done

    if [ $ERROR -ne 0 ]; then
        echoerror
        return 1
    fi

    return 0
}

# Global: Works on 12.04 and 14.04
install_perl_modules() {
	# Required by macl.pl script
	#perl -MCPAN -e "install Net::Wigle" >> $HOME/bitcurator-install.log 2>&1
        echoinfo "No perl modules to install at this time."
}

install_bitcurator_files() {
  # Checkout code from bitcurator and put these files into place
  echoinfo "BitCurator environment: Installing BitCurator Tools"
  echoinfo " -- Please be patient. This may take several minutes..."
	CDIR=$(pwd)
	git clone --recursive https://github.com/kamwoods/bitcurator /tmp/bitcurator >> $HOME/bitcurator-install.log 2>&1
	cd /tmp/bitcurator/bctools
        python3 setup.py build >> $HOME/bitcurator-install.log 2>&1
        python3 setup.py install >> $HOME/bitcurator-install.log 2>&1
	#bash install.sh >> $HOME/bitcurator-install.log 2>&1

  echoinfo "BitCurator environment: Installing py3fpdf"
        cd /tmp/bitcurator/externals/py3fpdf
        python3 setup.py build >> $HOME/bitcurator-install.log 2>&1
        sudo python3 setup.py install >> $HOME/bitcurator-install.log 2>&1
  
  echoinfo "BitCurator environment: Installing BitCurator mount policy app and mounter"
        cd /tmp/bitcurator/mounter
        cp *.py /usr/local/bin

  echoinfo "BitCurator environment: Installing BitCurator desktop launcher scripts"
        cd /tmp/bitcurator/scripts
        cp ./launch-scripts/* /usr/local/bin 
  
  echoinfo "BitCurator environment: Moving BitCurator configuration files to /etc/bitcurator"
        cd /tmp/bitcurator/env/etc
        cp -r bitcurator /etc

  echoinfo "BitCurator environment: Disabling fstrim in cron.weekly"
        cd /tmp/bitcurator/env/etc
        cp cron.weekly/fstrim /etc/cron.weekly/fstrim

  echoinfo "BitCurator environment: Updating sudoers"
        echoinfo "(not implemented currently)"

  echoinfo "BitCurator environment: Copying fmount support scripts to /usr/local/bin"
        cd /tmp/bitcurator/env/usr/local/bin
        cp * /usr/local/bin

  echoinfo "BitCurator environment: Copying rbfstab scripts to /usr/sbin"
        cd /tmp/bitcurator/env/usr/sbin
        cp * /usr/sbin
  
  echoinfo "BitCurator environment: Force fstab options for devices"
        cd /tmp/bitcurator/env/etc/udev/rules.d
        cp fstab.rules /etc/udev/rules.d

  echoinfo "BitCurator environment: Moving BitCurator icons and pixmaps to /usr/share"
        cd /tmp/bitcurator/env/usr/share/icons
        cp -r bitcurator /usr/share/icons
        cd /tmp/bitcurator/env/usr/share/pixmaps
        cp -r * /usr/share/pixmaps
 
  echoinfo "BitCurator environment: Moving desktop support files to /usr/share/bitcurator/resources"
        if [ ! -d /usr/share/bitcurator ]; then
		mkdir -p /usr/share/bitcurator
	fi
        if [ ! -d /usr/share/bitcurator/resources ]; then
		mkdir -p /usr/share/bitcurator/resources
	fi
        # We'll be transfering desktop-folders contents later...
        cp -r /tmp/bitcurator/env/desktop-folders /usr/share/bitcurator/resources
 
  echoinfo "BitCurator environment: Moving image files to /usr/share/bitcurator/resources"
        cp -r /tmp/bitcurator/env/images /usr/share/bitcurator/resources

  echoinfo "BitCurator environment: Cleaning up..."
	cd $CDIR
	rm -r -f /tmp/bitcurator

}

install_source_packages() {

#  wget "https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz"  >> $HOME/sift-install.log 2>&1
#  tar -zxf kibana-3.1.0.tar.gz  >> $HOME/sift-install.log 2>&1
#  cd /tmp/kibana-3.1.0/ >> $HOME/sift-install.log 2>&1
#  mkdir -p /var/www/html/kibana
#  cp -r . /var/www/html/kibana >> $HOME/sift-install.log 2>&1
#  cd $CDIR
#}

  # Install Apache Thrift - packaged version too old in 14.04LTS
  echoinfo "BitCurator environment: Building and installing Apache Thrift"
  echoinfo " -- Please be patient. This may take several minutes..."
	CDIR=$(pwd)
        cd /tmp
        wget -q mirror.cogentco.com/pub/apache/thrift/0.9.2/thrift-0.9.2.tar.gz
	tar -zxf thrift-0.9.2.tar.gz >> $HOME/bitcurator-install.log 2>&1
        cd thrift-0.9.2
        ./configure >> $HOME/bitcurator-install.log 2>&1
        make -s >> $HOME/bitcurator-install.log 2>&1
        make install >> $HOME/bitcurator-install.log 2>&1
        ldconfig >> $HOME/bitcurator-install.log 2>&1
	# Now clean up
        cd /tmp
        rm thrift-0.9.2.tar.gz
        rm -rf thrift-0.9.2

  # Install libewf from current sources
  echoinfo "BitCurator environment: Building and installing libewf"
	CDIR=$(pwd)
	git clone --recursive https://github.com/libyal/libewf /tmp/libewf >> $HOME/bitcurator-install.log 2>&1
	cd /tmp/libewf
        ./synclibs.sh >> $HOME/bitcurator-install.log 2>&1
        ./autogen.sh >> $HOME/bitcurator-install.log 2>&1
        ./configure --enable-v1-api >> $HOME/bitcurator-install.log 2>&1
        make -s >> $HOME/bitcurator-install.log 2>&1
        make install >> $HOME/bitcurator-install.log 2>&1
        ldconfig >> $HOME/bitcurator-install.log 2>&1
        # Now clean up
        cd /tmp
        rm -rf libewf	

  # Install AFFLIBv3 (may remove this in future - deprecated)
  echoinfo "BitCurator environment: Building and installing AFFLIBv3"
	CDIR=$(pwd)
	git clone --recursive https://github.com/simsong/AFFLIBv3 /tmp/AFFLIBv3 >> $HOME/bitcurator-install.log 2>&1
	cd /tmp/AFFLIBv3
        ./bootstrap.sh >> $HOME/bitcurator-install.log 2>&1
        ./configure >> $HOME/bitcurator-install.log 2>&1
        make -s >> $HOME/bitcurator-install.log 2>&1
        make install >> $HOME/bitcurator-install.log 2>&1
        ldconfig >> $HOME/bitcurator-install.log 2>&1
	# Now clean up
        cd /tmp
        rm -rf AFFLIBv3

  # Install POCO
  echoinfo "BitCurator environment: Building and installing POCO C++ libraries"
  echoinfo " -- Please be patient. This may take several minutes..."
	CDIR=$(pwd)
        cd /tmp
        wget -q pocoproject.org/releases/poco-1.6.0/poco-1.6.0.tar.gz
	tar -zxf poco-1.6.0.tar.gz >> $HOME/bitcurator-install.log 2>&1
        cd poco-1.6.0
        ./configure >> $HOME/bitcurator-install.log 2>&1
        make -s >> $HOME/bitcurator-install.log 2>&1
        make install >> $HOME/bitcurator-install.log 2>&1
        ldconfig >> $HOME/bitcurator-install.log 2>&1
	# Now clean up
        cd /tmp
        rm poco-1.6.0.tar.gz
        rm -rf poco-1.6.0

  # Install The Sleuth Kit (TSK) from current sources
  echoinfo "BitCurator environment: Building and installing The Sleuth Kit"
	CDIR=$(pwd)
	git clone --recursive https://github.com/sleuthkit/sleuthkit /tmp/sleuthkit >> $HOME/bitcurator-install.log 2>&1
	cd /tmp/sleuthkit
        ./configure >> $HOME/bitcurator-install.log 2>&1
        make -s >> $HOME/bitcurator-install.log 2>&1
        make install >> $HOME/bitcurator-install.log 2>&1
        ldconfig >> $HOME/bitcurator-install.log 2>&1
	#bash install.sh >> $HOME/bitcurator-install.log 2>&1
  echoinfo "BitCurator environment: Building and installing The Sleuth Kit framework"
        echoinfo "DON'T FORGET TO FIX THIS"
        # Now clean up
        cd /tmp
        rm -rf sleuthkit

  # Install PyTSK
  echoinfo "BitCurator environment: Building and installing PyTSK (Python bindings for TSK)"
  echoinfo " -- Please be patient. This may take several minutes..."
	CDIR=$(pwd)
        cd /tmp
        wget -q https://github.com/py4n6/pytsk/releases/download/20150406/pytsk-20150406.tgz
	tar -zxf pytsk-20150406.tgz >> $HOME/bitcurator-install.log 2>&1
        cd pytsk
        python3 setup.py build >> $HOME/bitcurator-install.log 2>&1
        python3 setup.py install >> $HOME/bitcurator-install.log 2>&1
        # Now clean up
        cd /tmp
        rm -rf pytsk	
  
  # Install libsodium (not packaged version in 14.04LTS, needed for ZeroMQ)
  echoinfo "BitCurator environment: Building and installing libsodium"
  echoinfo " -- Please be patient. This may take several minutes..."
	CDIR=$(pwd)
        cd /tmp
        wget -q https://download.libsodium.org/libsodium/releases/libsodium-1.0.3.tar.gz
	tar -zxf libsodium-1.0.3.tar.gz >> $HOME/bitcurator-install.log 2>&1
        cd libsodium-1.0.3
        ./configure >> $HOME/bitcurator-install.log 2>&1
        make >> $HOME/bitcurator-install.log 2>&1
        make install >> $HOME/bitcurator-install.log 2>&1
        ldconfig >> $HOME/bitcurator-install.log 2>&1
        # Now clean up
        cd /tmp
        rm libsodium-1.0.3.tar.gz
        rm -rf libsodium-1.0.3	

  # Install ZeroMQ (packaged version in 14.04LTS out of date)
  echoinfo "BitCurator environment: Building and installing ZeroMQ"
  echoinfo " -- Please be patient. This may take several minutes..."
	CDIR=$(pwd)
        cd /tmp
        wget -q download.zeromq.org/zeromq-4.1.1.tar.gz
	tar -zxf zeromq-4.1.1.tar.gz >> $HOME/bitcurator-install.log 2>&1
        cd zeromq-4.1.1
        ./configure >> $HOME/bitcurator-install.log 2>&1
        make >> $HOME/bitcurator-install.log 2>&1
        make install >> $HOME/bitcurator-install.log 2>&1
        ldconfig >> $HOME/bitcurator-install.log 2>&1
	# Now clean up
        cd /tmp
        rm zeromq-4.1.1.tar.gz
        rm -rf zeromq-4.1.1
  
  # Install hashdb (optional dependency for bulk_extractor)
  echoinfo "BitCurator environment: Building and installing hashdb"
	CDIR=$(pwd)
	git clone --recursive https://github.com/simsong/hashdb /tmp/hashdb >> $HOME/bitcurator-install.log 2>&1
	cd /tmp/hashdb
        chmod 755 bootstrap.sh
        ./bootstrap.sh >> $HOME/bitcurator-install.log 1>&1
        ./configure --with-boost-libdir=/usr/lib/x86_64-linux-gnu >> $HOME/bitcurator-install.log 2>&1
        make -s >> $HOME/bitcurator-install.log 2>&1
        make install >> $HOME/bitcurator-install.log 2>&1
        ldconfig >> $HOME/bitcurator-install.log 2>&1
	# Now clean up
        cd /tmp
        rm -rf hashdb

  # Install bulk_extractor
  echoinfo "BitCurator environment: Building and installing bulk_extractor"
  echoinfo " -- Please be patient. This may take several minutes..."
	CDIR=$(pwd)
	git clone --recursive https://github.com/simsong/bulk_extractor /tmp/bulk_extractor >> $HOME/bitcurator-install.log 2>&1
	cd /tmp/bulk_extractor
        chmod 755 bootstrap.sh
        ./bootstrap.sh >> $HOME/bitcurator-install.log 1>&1
        ./configure --with-boost-libdir=/usr/lib/x86_64-linux-gnu >> $HOME/bitcurator-install.log 2>&1
        make -s >> $HOME/bitcurator-install.log 2>&1
        make install >> $HOME/bitcurator-install.log 2>&1
        ldconfig >> $HOME/bitcurator-install.log 2>&1
        # Now clean up
        # KEEP FOR TIME BEING	

  # Install HFSUtils (not packaged for 14.04LTS)
  echoinfo "BitCurator environment: Building and installing hfsutils"
	CDIR=$(pwd)
        cd /tmp
        wget -q ftp://ftp.mars.org/pub/hfs/hfsutils-3.2.6.tar.gz
	tar -zxf hfsutils-3.2.6.tar.gz >> $HOME/bitcurator-install.log 2>&1
        cd hfsutils-3.2.6
        ./configure >> $HOME/bitcurator-install.log 2>&1
        make >> $HOME/bitcurator-install.log 2>&1
        make install >> $HOME/bitcurator-install.log 2>&1
        ldconfig >> $HOME/bitcurator-install.log 2>&1
	# Now clean up
        cd /tmp
        rm hfsutils-3.2.6.tar.gz
        rm -rf hfsutils-3.2.6

  # Install disktype (not packaged for 14.04LTS, use KW fork)
  echoinfo "BitCurator environment: Building and installing disktype"
	CDIR=$(pwd)
        cd /tmp
        git clone https://github.com/kamwoods/disktype >> $HOME/bitcurator-install.log 2>&1
        cd disktype
        ./configure >> $HOME/bitcurator-install.log 2>&1
        make >> $HOME/bitcurator-install.log 2>&1
        make install >> $HOME/bitcurator-install.log 2>&1
        ldconfig >> $HOME/bitcurator-install.log 2>&1
	# Now clean up
        cd /tmp
        rm -rf disktype

  # Install dumpfloppy (not packaged for 14.04LTS, use author source)
  echoinfo "BitCurator environment: Building and installing dumpfloppy"
	CDIR=$(pwd)
        cd /tmp
        git clone http://offog.org/git/dumpfloppy.git >> $HOME/bitcurator-install.log 2>&1
        cd dumpfloppy
        ./configure >> $HOME/bitcurator-install.log 2>&1
        make >> $HOME/bitcurator-install.log 2>&1
        make install >> $HOME/bitcurator-install.log 2>&1
        ldconfig >> $HOME/bitcurator-install.log 2>&1
	# Now clean up
        cd /tmp
        rm -rf dumpfloppy

  # Install bagit (not packaged for 14.04LTS, use author source)
  echoinfo "BitCurator environment: Building and installing bagit"
	CDIR=$(pwd)
        cd /tmp
        git clone https://github.com/LibraryOfCongress/bagit-java >> $HOME/bitcurator-install.log 2>&1
        cd bagit-java
        mvn package >> $HOME/bitcurator-install.log 2>&1
        cd target
        unzip bagit-4.10.0-SNAPSHOT-bin.zip 2>&1
        cd bagit-4.10.0-SNAPSHOT
        # NEED INSTALL INSTRUCTIONS HERE
	# Now clean up
        cd /tmp
        # ???

  # CHECK - DFXML, others from build doc
  # Remove when completed

  # Install sdhash (not packaged for 14.04LTS, use author source)
  echoinfo "BitCurator environment: Building and installing sdhash"
	CDIR=$(pwd)
        cd /tmp
        wget -q https://github.com/sdhash/sdhash/archive/v3.4.tar.gz
	tar -zxf v3.4.tar.gz >> $HOME/bitcurator-install.log 2>&1
        cd sdhash-3.4
        ./configure >> $HOME/bitcurator-install.log 2>&1
        make >> $HOME/bitcurator-install.log 2>&1
        make install >> $HOME/bitcurator-install.log 2>&1
        ldconfig >> $HOME/bitcurator-install.log 2>&1
	# Now clean up
        cd /tmp
        rm -rf sdhash-3.4

}

configure_ubuntu() {
  #echoinfo "BitCurator VM: Creating Cases Folder"
  #	if [ ! -d /cases ]; then
  #		mkdir -p /cases
  #		chown $SUDO_USER:$SUDO_USER /cases
  #		chmod 775 /cases
  #		chmod g+s /cases
  #	fi

  #echoinfo "BitCurator VM: Creating Mount Folders"
  #	for dir in usb vss shadow windows_mount e01 aff ewf bde iscsi
  #	do
  #		if [ ! -d /mnt/$dir ]; then
  #			mkdir -p /mnt/$dir
  #		fi
  #	done
  #
  #	for NUM in 1 2 3 4 5
  #	do
  #		if [ ! -d /mnt/windows_mount$NUM ]; then
  #			mkdir -p /mnt/windows_mount$NUM
  #		fi
  #		if [ ! -d /mnt/ewf_mount$NUM ]; then
  #			mkdir -p /mnt/ewf_mount$NUM
  #		fi
  #	done
  # 
  #	for NUM in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
  #	do
  #		if [ ! -d /mnt/shadow/vss$NUM ]; then
  #			mkdir -p /mnt/shadow/vss$NUM
  #		fi
  #		if [ ! -d /mnt/shadow_mount/vss$NUM ]; then
  #			mkdir -p /mnt/shadow_mount/vss$NUM
  #		fi
  #	done

  echoinfo "BitCurator VM: Setting up symlinks to useful scripts"
  if [ ! -L /usr/bin/vol.py ] && [ ! -e /usr/bin/vol.py ]; then
    ln -s /usr/bin/vol.py /usr/bin/vol
	fi
	if [ ! -L /usr/bin/log2timeline ] && [ ! -e /usr/bin/log2timeline ]; then
		ln -s /usr/bin/log2timeline_legacy /usr/bin/log2timeline
	fi
	if [ ! -L /usr/bin/kedit ] && [ ! -e /usr/bin/kedit ]; then
		ln -s /usr/bin/gedit /usr/bin/kedit
	fi
	if [ ! -L /usr/bin/mount_ewf.py ] && [ ! -e /usr/bin/mount_ewf.py ]; then
		ln -s /usr/bin/ewfmount /usr/bin/mount_ewf.py
	fi

#  # Fix for https://github.com/sans-dfir/sift/issues/10
#  if [ ! -L /usr/bin/icat-sleuthkit ] && [ ! -e /usr/bin/icat-sleuthkit ]; then
#    ln -s /usr/bin/icat /usr/bin/icat-sleuthkit 
#  fi
#
#  # Fix for https://github.com/sans-dfir/sift/issues/23
#  if [ ! -L /usr/local/bin/l2t_process ] && [ ! -e /usr/local/bin/l2t_process ]; then
#    ln -s /usr/bin/l2t_process_old.pl /usr/local/bin/l2t_process
#  fi
#
#  if [ ! -L /usr/local/etc/foremost.conf ]; then
#    ln -s /etc/foremost.conf /usr/local/etc/foremost.conf
#  fi
#
#  # Fix for https://github.com/sans-dfir/sift/issues/41
#  if [ ! -L /usr/local/bin/mactime-sleuthkit ] && [ ! -e /usr/local/bin/mactime-sleuthkit ]; then
#    ln -s /usr/bin/mactime /usr/local/bin/mactime-sleuthkit
#  fi
#
#  sed -i "s/APT::Periodic::Update-Package-Lists \"1\"/APT::Periodic::Update-Package-Lists \"0\"/g" /etc/apt/apt.conf.d/10periodic
}

# Global: Ubuntu BitCurator VM Configuration Function
# Works with 12.04 and 14.04 Versions
configure_ubuntu_bitcurator_vm() {
  echoinfo "BitCurator VM: Setting Hostname: bitcurator"
	OLD_HOSTNAME=$(hostname)
	sed -i "s/$OLD_HOSTNAME/bitcurator/g" /etc/hosts
	echo "bitcurator" > /etc/hostname
	hostname bitcurator

  echoinfo "BitCurator VM: Fixing Samba User"
	# Make sure we replace the BITCURATOR_USER template with our actual
	# user so there is write permissions to samba.
	sed -i "s/BITCURTOR_USER/$SUDO_USER/g" /etc/samba/smb.conf

  echoinfo "BitCurator VM: Restarting Samba"
	# Restart samba services 
	service smbd restart >> $HOME/bitcurator-install.log 2>&1
	service nmbd restart >> $HOME/bitcurator-install.log 2>&1

  echoinfo "BitCurator VM: Setting Timezone to UTC" >> $HOME/bitcurator-install.log 2>&1
  echo "Etc/UTC" > /etc/timezone >> $HOME/bitcurator-install.log 2>&1
    
  #echoinfo "SIFT VM: Fixing Regripper Files"
#	# Make sure to remove all ^M from regripper plugins
#	# Not sure why they are there in the first place ...
#	dos2unix -ascii /usr/share/regripper/* >> $HOME/sift-install.log 2>&1

#  if [ -f /usr/share/regripper/plugins/usrclass-all ]; then
#    mv /usr/share/regripper/plugins/usrclass-all /usr/share/regripper/plugins/usrclass
#  fi
#
#  if [ -f /usr/share/regripper/plugins/ntuser-all ]; then
#    mv /usr/share/regripper/plugins/ntuser-all /usr/share/regripper/plugins/ntuser
#  fi
#
#  chmod 775 /usr/share/regripper/rip.pl
#  chmod -R 755 /usr/share/regripper/plugins
   
  echoinfo "BitCurator VM: Fixing i2c_piix4 boot error:"
        # Edit /etc/modprobe.d/blacklist.conf
        # Add line: blacklist i2c_piix4
 
  echoinfo "BitCurator VM: Setting noclobber for $SUDO_USER"
	if ! grep -i "set -o noclobber" $HOME/.bashrc > /dev/null 2>&1
	then
		echo "set -o noclobber" >> $HOME/.bashrc
	fi
	if ! grep -i "set -o noclobber" /root/.bashrc > /dev/null 2>&1
	then
		echo "set -o noclobber" >> /root/.bashrc
	fi

  echoinfo "BitCurator VM: Configuring Aliases for $SUDO_USER and root"
	if ! grep -i "alias mountwin" $HOME/.bash_aliases > /dev/null 2>&1
	then
		echo "alias mountwin='mount -o ro,loop,show_sys_files,streams_interface=windows'" >> $HOME/.bash_aliases
	fi
	
	# For BitCurator VM, root is used frequently, set the alias there too.
	if ! grep -i "alias mountwin" /root/.bash_aliases > /dev/null 2>&1
	then
		echo "alias mountwin='mount -o ro,loop,show_sys_files,streams_interface=windows'" >> /root/.bash_aliases
	fi

  echoinfo "BitCurator VM: Setting up useful links on $SUDO_USER Desktop"
	#if [ ! -L /home/$SUDO_USER/Desktop/cases ]; then
	#	sudo -u $SUDO_USER ln -s /cases /home/$SUDO_USER/Desktop/cases
	#fi
  
	#if [ ! -L /home/$SUDO_USER/Desktop/mount_points ]; then
	#	sudo -u $SUDO_USER ln -s /mnt /home/$SUDO_USER/Desktop/mount_points
	#fi

  echoinfo "BitCurator VM: Cleaning up broken symlinks on $SUDO_USER Desktop"
	# Clean up broken symlinks
	find -L /home/$SUDO_USER/Desktop -type l -delete

  echoinfo "BitCurator VM: Adding all BitCurator resources to $SUDO_USER Desktop"

        files="$(find -L "/usr/share/bitcurator/resources/desktop-folders" -type f)"
        directories="$(find -L "/usr/share/bitcurator/resources/desktop-folders" -type d)"

        # Process desktop directories - FINISH ME!
        echo "$directories" | while read LINK_OR_DIR; do
            echo "$LINK_OR_DIR"

            # Create desktop dirs if they don't already exist
            if [ -d "$LINK_OR_DIR" ]; then 
              if [ -L "$LINK_OR_DIR" ]; then
                # It is a symlink!
                # Symbolic link specific commands go here.
                #rm "$LINK_OR_DIR"
                echo "$LINK_OR_DIR"
              else
                # It's a directory!
                # Directory command goes here.
                #rmdir "$LINK_OR_DIR"
                echo "$LINK_OR_DIR"
              fi
            fi
        done

        # Process desktop files - FINISH ME!
        echo "Count: $(echo -n "$files" | wc -l)"
        echo "$files" | while read file; do
            echo "$file"
        done

        #	for file in /usr/share/bitcurator/resources/*.pdf
        #	do
        #		base=`basename $file`
        #		if [ ! -L /home/$SUDO_USER/Desktop/$base ]; then
        #			sudo -u $SUDO_USER ln -s $file /home/$SUDO_USER/Desktop/$base
        #		fi
        #	done
  
  echoinfo "BitCurator VM: Enabling desktop icons for $SUDO_USER Desktop"
        sudo -u $SUDO_USER gsettings set org.gnome.desktop.background show-desktop-icons true


  echoinfo "BitCurator VM: Setting some useful icons for $SUDO_USER Desktop"
        sudo -u $SUDO_USER gsettings set org.gnome.nautilus.desktop home-icon-visible true
        #gsettings set org.gnome.nautilus.desktop computer-icon-visible true
        sudo -u $SUDO_USER gsettings set org.gnome.nautilus.desktop trash-icon-visible true
        #gsettings set org.gnome.nautilus.desktop network-icon-visible true

  echoinfo "BitCurator VM: Setting Desktop background image"
        #cd /usr/share/bitcurator/resources/images
        sudo -u $SUDO_USER gsettings set org.gnome.desktop.background primary-color '#3464A2'
        sudo -u $SUDO_USER gsettings set org.gnome.desktop.background secondary-color '#3464A2'
        sudo -u $SUDO_USER gsettings set org.gnome.desktop.background color-shading-type 'solid'

        sudo -u $SUDO_USER gsettings set org.gnome.desktop.background draw-background false && sudo -u $SUDO_USER gsettings set org.gnome.desktop.background picture-uri file:///usr/share/bitcurator/resources/images/bc400px-1280full.png && sudo -u $SUDO_USER gsettings set org.gnome.desktop.background draw-background true

  if [ ! -L /sbin/iscsiadm ]; then
    ln -s /usr/bin/iscsiadm /sbin/iscsiadm
  fi
  
  if [ ! -L /usr/local/bin/rip.pl ]; then
    ln -s /usr/share/regripper/rip.pl /usr/local/bin/rip.pl
  fi

  # Add extra device loop backs.
  if ! grep "do mknod /dev/loop" /etc/rc.local > /dev/null 2>&1
  then
    echo 'for i in `seq 8 100`; do mknod /dev/loop$i b 7 $i; done' >> /etc/rc.local
  fi
}

# 14.04 BitCurator VM Configuration Function
configure_ubuntu_14.04_bitcurator_vm() {

  echoinfo "More config needed here..."

#  sudo -u $SUDO_USER gsettings set com.canonical.Unity.Launcher favorites "['application://nautilus.desktop', 'application://gnome-terminal.desktop', 'application://firefox.desktop', 'application://gnome-screenshot.desktop', 'application://gcalctool.desktop', 'application://bless.desktop', 'application://autopsy.desktop', 'application://wireshark.desktop']" >> $HOME/bitcurator-install.log 2>&1

#  # Works in 12.04 and 14.04
#  sudo -u $SUDO_USER gsettings set org.gnome.desktop.background picture-uri file:///usr/share/sift/images/forensics_blue.jpg >> $HOME/bitcurator-install.log 2>&1

#  # Works in 14.04 
#	if [ ! -d /home/$SUDO_USER/.config/autostart ]; then
#		sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/.config/autostart
#	fi

#  # Works in 14.04 too.
#	if [ ! -L /home/$SUDO_USER/.config/autostart ]; then
#		sudo -u $SUDO_USER cp /usr/share/sift/other/gnome-terminal.desktop /home/$SUDO_USER/.config/autostart
#	fi
    
#  # Works in 14.04 too
#	#if [ ! -e /usr/share/unity-greeter/logo.png.ubuntu ]; then
#	#	sudo cp /usr/share/unity-greeter/logo.png /usr/share/unity-greeter/logo.png.ubuntu
#	#	sudo cp /usr/share/sift/images/login_logo.png /usr/share/unity-greeter/logo.png
#	#fi

  # Setup user favorites (only for 12.04)
  #sudo -u $SUDO_USER dconf write /desktop/unity/launcher/favorites "['nautilus.desktop', 'gnome-terminal.desktop', 'firefox.desktop', 'gnome-screenshot.desktop', 'gcalctool.desktop', 'bless.desktop', 'autopsy.desktop', 'wireshark.desktop']" >> $HOME/sift-install.log 2>&1

  # Setup the login background image
  #cp /usr/share/sift/images/forensics_blue.jpg /usr/share/backgrounds/warty-final-ubuntu.png
  
  chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER
}

complete_message() {
    echo
    echo "Installation Complete!"
    echo 
    echo "Related docs are works in progress, feel free to contribute!"
    echo 
    echo "Documentation: http://wiki.bitcurator.net"
    echo
}

complete_message_skin() {
    echo "The hostname was changed, you should relogin or reboot for it to take full effect."
    echo
    echo "sudo reboot"
    echo
}

UPGRADE_ONLY=0
CONFIGURE_ONLY=0
SKIN=0
INSTALL=1
YESTOALL=0

OS=$(lsb_release -si)
ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
VER=$(lsb_release -sr)

if [ $OS != "Ubuntu" ]; then
    echo "BitCurator is only installable on Ubuntu operating systems at this time."
    exit 1
fi

if [ $ARCH != "64" ]; then
    echo "BitCurator is only installable on a 64 bit architecture at this time."
    exit 2
fi

if [ $VER != "12.04" ] && [ $VER != "14.04" ]; then
    echo "BitCurator is only installable on Ubuntu 14.04 at this time."
    exit 3
fi

if [ `whoami` != "root" ]; then
    echoerror "The BitCurator Bootstrap script must run as root."
    echoinfo "Preferred Usage: sudo bootstrap.sh (options)"
    echo ""
    exit 3
fi

if [ "$SUDO_USER" = "" ]; then
    echo "The SUDO_USER variable doesn't seem to be set"
    exit 4
fi

#if [ ! "$(__check_apt_lock)" ]; then
#    echo "APT Package Manager appears to be locked. Close all package managers."
#    exit 15
#fi

while getopts ":hvcsiyu" opt
do
case "${opt}" in
    h ) usage; exit 0 ;;  
    v ) echo "$0 -- Version $__ScriptVersion"; exit 0 ;;
    s ) SKIN=1 ;;
    i ) INSTALL=1 ;;
    c ) CONFIGURE_ONLY=1; INSTALL=0; SKIN=0; ;;
    u ) UPGRADE_ONLY=1; ;;
    y ) YESTOALL=1 ;;
    \?) echo
        echoerror "Option does not exist: $OPTARG"
        usage
        exit 1
        ;;
esac
done

shift $(($OPTIND-1))

if [ "$#" -eq 0 ]; then
    ITYPE="stable"
else
    __check_unparsed_options "$*"
    ITYPE=$1
    shift
fi

if [ "$UPGRADE_ONLY" -eq 1 ]; then
  echoinfo "BitCurator update/upgrade requested."
  echoinfo "All other options will be ignored!"
  echoinfo "This could take a few minutes ..."
  echo ""
  
  export DEBIAN_FRONTEND=noninteractive

  install_ubuntu_${VER}_deps $ITYPE || echoerror "Updating Depedencies Failed"
  install_ubuntu_${VER}_packages $ITYPE || echoerror "Updating Packages Failed"
  install_ubuntu_${VER}_pip_packages $ITYPE || echoerror "Updating Python Packages Failed"
  install_perl_modules || echoerror "Updating Perl Packages Failed"
#  install_kibana || echoerror "Installing/Updating Kibana Failed"
  install_bitcurator_files || echoerror "Installing/Updating BitCurator Files Failed"
  install_source_packages || echoerror "Installing/Updating BitCurator Source Packages Failed"

  echo ""
  echoinfo "BitCurator Upgrade Complete"
  exit 0
fi

# Check installation type
if [ "$(echo $ITYPE | egrep '(dev|stable)')x" = "x" ]; then
    echoerror "Installation type \"$ITYPE\" is not known..."
    exit 1
fi

echoinfo "*******************************************************"
echoinfo "Welcome to the BitCurator Bootstrap Script"
echoinfo "This script will now proceed to configure your system."
echoinfo "*******************************************************"
echoinfo ""

if [ "$YESTOALL" -eq 1 ]; then
    echoinfo "You supplied the -y option, this script will not exit for any reason"
fi

echoinfo "OS: $OS"
echoinfo "Arch: $ARCH"
echoinfo "Version: $VER"

if [ "$SKIN" -eq 1 ] && [ "$YESTOALL" -eq 0 ]; then
    echo
    echo "You have chosen to apply the BitCurator skin to your ubuntu system."
    echo 
    echo "You did not choose to say YES to all, so we are going to exit."
    echo
    echo "Your current user is: $SUDO_USER"
    echo
    echo "Re-run this command with the -y option"
    echo
    exit 10
fi

if [ "$INSTALL" -eq 1 ] && [ "$CONFIGURE_ONLY" -eq 0 ]; then
    export DEBIAN_FRONTEND=noninteractive
    install_ubuntu_${VER}_deps $ITYPE
    install_ubuntu_${VER}_packages $ITYPE
    install_ubuntu_${VER}_pip_packages $ITYPE
    configure_cpan
    install_perl_modules
    #install_kibana
    install_bitcurator_files
    install_source_packages
fi

#configure_elasticsearch

# Configure for BitCurator
configure_ubuntu

# Configure BitCurator VM (if selected)
if [ "$SKIN" -eq 1 ]; then
    configure_ubuntu_bitcurator_vm
    configure_ubuntu_${VER}_bitcurator_vm
fi

complete_message

if [ "$SKIN" -eq 1 ]; then
    complete_message_skin
fi