.. role:: sh(code)
   :language: sh

XtChain
#######

Build and install crosstool-ng based toolchains.

Provided components
===================

Installed toolchains will include the following components :

* autoconf suite
* automake suite
* libtool patched for cross-compiling purposes
* pkg-config
* cross-compiling gcc/g++ suite
* a target platform glibc/libstdc++ (including a sysroot hierarchy)
* ldconfig patched for cross-compiling purposes 
  
Toolchains are meant to run onto **x86_64 GNU/Linux** development hosts only.
  
Supported platforms
===================

As of today, the following toolchain support is provided :

:a38x: Marvell Armada 38x SoC based platforms

.. table:: Toolchains components

   +----------------+-----------------------------+
   |                | Toolchains                  |
   + Components     +-----------------------------+
   |                | a38x                        |
   +================+=============================+
   | autoconf       | 2.69                        |
   +----------------+-----------------------------+
   | automake       | 1.16.1                      |
   +----------------+-----------------------------+
   | libtool        | 2.4.6                       |
   +----------------+-----------------------------+
   | pkg-config     | 0.26.2                      |
   +----------------+-----------------------------+
   | binutils       | 2.32                        |
   +----------------+-----------------------------+
   | gcc            | 8.3.0                       |
   +----------------+-----------------------------+
   | glibc6         | 2.29                        |
   +----------------+-----------------------------+
   | packager       | crosstool-ng 1.24.0         |
   +----------------+---------------+-------------+

Toolchain default settings are described into the table below [1]_.

.. table:: Default toolchains gcc / glibc settings

   +-------------------------------+------------------------------------+
   | gcc / glibc settings          | Toolchains                         |
   +-------------+-----------------+------------------------------------+
   | Name        | GCC switch      | a38x                               |
   +=============+=================+====================================+
   | ABI         | -mabi           | aapcs-linux                        |
   +-------------+-----------------+------------------------------------+
   | TLS model   | -mtls-dialect   | gnu                                |
   +-------------+-----------------+------------------------------------+
   | Arch        | -march          | armv7-a+mp+sec+simd                |
   +-------------+-----------------+------------------------------------+
   | float ABI   | -mfloat-abi     | hard                               |
   +-------------+-----------------+------------------------------------+
   | FPU         | -mfpu           | neon-vfpv3                         |
   +-------------+-----------------+------------------------------------+
   | Instruction | -mthumb / -marm | ARM  (with no interwork)           |
   | state       |                 |                                    |
   +-------------+-----------------+------------------------------------+
   | CPU         | -mcpu / -mtune  | cortex-a9                          |
   +-------------+-----------------+------------------------------------+
   | system tuple                  | armv7_a38x-xtchain-linux-gnueabihf |
   +-------------------------------+------------------------------------+


Build / install workflow
========================

Prerequisites
*************

Packages listed below are required to build and install cross toolchains onto
your development host :

* coreutils
* tar
* patch
* help2man
* gcc
* g++
* make
* autoconf
* automake
* libtool / libtool-bin
* libncurses5-dev
* git
* ssh
* pkg-config
* flex
* bison
* texinfo
* texlive
* gawk
* rsync

Getting help
************

From XtChain source tree root, enter :

.. code:: sh

   $ make help

Build
*****

Building toolchain *a38x* is performed out of source tree like so :

.. code:: sh

   $ make build-a38x BUILDDIR=/tmp/xtchain_build PREFIX=/opt/xtchain

This will basically build every components of the *a38x* toolchain :

* under the */tmp/xtchain_build* directory ;
* using */opt/xtchain/a38x* as the futur install directory path.

Install
*******

Installing toolchain *a38x* is performed according to the following
command :

.. code:: sh

   $ make install-a38x BUILDDIR=/tmp/xtchain_build PREFIX=/opt/xtchain
   
This instructs to deploy / install built components found under :

* the */tmp/xtchain_build* directory ;
* under the */opt/xtchain/a38x* directory path.

If you want to install the toolchain into a system-wide directory, you will most
likely need root priviledge to run the above command.

Install directory hierarchy
***************************

The directory hierarchy installed by the example commands above is show below.

.. parsed-literal::

   $ ls -l /opt/xtchain/a38x/
   total 28
   drwxr-xr-x  7 greg home 4096 Aug 22 18:22 .
   drwxr-xr-x  3 greg home 4096 Aug 22 20:13 ..
   dr-xr-xr-x  8 greg home 4096 Aug 22 18:52 armv7_a38x-xtchain-linux-gnueabihf
   drwxr-xr-x  2 greg home 4096 Aug 22 18:21 bin
   drwxr-xr-x  3 greg home 4096 Aug 22 18:21 include
   drwxr-xr-x  2 greg home 4096 Aug 22 18:21 lib
   drwxr-xr-x 11 greg home 4096 Aug 22 18:06 share

In the excerpt above :

* tools generating objects for target will be found under the
  *armv7_a38x-xtchain-linux-gnueabihf* directory
* development host only tools will be found into *bin", *include*, *lib* and
  *share* remaining directories.

Adding a new toolchain
======================

Complete me !

TODO
====

An unordered list of futur improvements :

* alternative DESTDIR install location
* debian packaging (depends on DESTDIR support)
* additional components ??
* enable glibc libmvec support
* flex / bison
* gawk perl python2/3 cpio fakeroot bc
* make / cmake / gcc / g++ / libc6-dev ?

.. [1] gcc / glibc settings retrieved according to the command :
       :sh:`gcc -Q --help=target`
