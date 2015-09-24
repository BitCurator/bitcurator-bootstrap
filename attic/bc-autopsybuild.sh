#!/bin/bash

# Sample autopsy build script for Ubuntu 14.04LTS / Ubuntu 15.04
# Reference only - do not use in conjunction with main build script
# Silent install: http://askubuntu.com/questions/190582/installing-java-automatically-with-silent-option

workingdir=`pwd`

sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install  oracle-java8-installer software-properties-common wget xauth git git-svn build-essential libssl-dev libbz2-dev libz-dev ant automake autoconf libtool vim python-dev gstreamer1.0

export JAVA_HOME="/usr/lib/jvm/java-8-oracle/"
export JDK_HOME="/usr/lib/jvm/java-8-oracle/"
export JRE_HOME="/usr/lib/jvm/java-8-oracle/jre/"
export TSK_HOME=$workingdir/tsk
# Download files / Git Reps
wget -c -O libewf.tar.gz https://github.com/libyal/libewf/releases/download/20150126/libewf-experimental-20150126.tar.gz
if [ ! -d sleuthkit ]
then   
   git clone https://github.com/sleuthkit/sleuthkit.git
fi
cd sleuthkit
make clean
git pull
cd ..

if [ ! -d autopsy ]
then
   git clone https://github.com/sleuthkit/autopsy.git
fi
cd autopsy
make clean
git pull
cd ..

# Compile libewf
rm -rf libewf/
mkdir libewf
cd libewf
tar --strip-components=1 -xvzf ../libewf.tar.gz
./bootstrap
./configure --enable-python --enable-verbose-output --enable-debug-output --prefix=$workingdir/tsk
make
make install

# Compile Sleuthkit
cd $workingdir/sleuthkit
./bootstrap
./configure --prefix=$workingdir/tsk --with-libewf=$workingdir/tsk
make
make install

# Build autopsy
mkdir -p $workingdir/tsk/bindings/java/dist
mkdir -p $workingdir/tsk/bindings/java/lib
cp $workingdir/tsk/share/java/Tsk_DataModel.jar $workingdir/tsk/bindings/java/dist/
cd $workingdir/tsk/bindings/java/lib
wget -c https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.7.15-M1/sqlite-jdbc-3.7.15-M1.jar
cd $workingdir/autopsy
ant build