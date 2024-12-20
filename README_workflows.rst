Development Workflows with Tox and Kas
======================================

Local tox workflows and helper scripts to automate building and deploying
Yocto build artifacts, which includes the following features based on the
enclustra docs Yocto layers:

* clone user BSP layer to get Kas_ build configuration(s)
* clone metadata repositories and build/install workflow dependencies
  into a python virtual environment managed by Tox_
* build yocto images using supported boot modes (qspi and sdmmc)
* optionally create sdcard image from sdmmc build
* deploy qspi build artifacts to sdcard (bootable or empty)


.. _Tox: https://github.com/tox-dev/tox
.. _Kas: https://kas.readthedocs.io/en/latest/command-line.html


Workflow descriptions
---------------------

The workflow commands described here fall roughly into three categories:

**Workspace workflows**

:dev: Sync and checkout build metadata, create virtual environment with
      build/deploy dependencies.
:clean: Remove staged qspi artifacts and Yocto ``build/tmp-*`` folder.

**Yocto build workflows**

:sdmmc: Build bootable sdcard target (sets UBOOT boot mode variable).
:qspi: Clean and build corresponding named build target (sets UBOOT boot
       mode variable).
:emmc: Build bootable emmc target for transfering to emmc flash from u-boot.

**Deployment workflows**

:bmap: Use vendor-recommended ``bmaptool`` to burn raw disk image to
       an SDCard. Optionally apply udev rule to optimize I/O performance.
:deploy: Use ``udisksctl`` to handle SDCard mounts and deploy qspi artifacts
         to deployed sdcard artifact. Optionally apply polkit rule to
         provide equivalent console permissions.

Big Fat Warning
---------------

.. important:: The above deployment workflows *directly touch* disk devices
               and will *destroy any data* on the ``DISK`` target. Therefore,
               as the workflow user, *you* need to make sure the value
               you provide is the correct ``DISK`` value for your sdcard
               device, eg, ``/dev/mmcblk0`` or ``/dev/sdb``. See below in
               section `Setup micro-SDCard`_ for an example of how to find
               your device name.

Workflow permissions
--------------------

* general Linux development host permissions to install/update host OS packages
* development user added to removable media group, eg, ``disk``
* development user added to ``wheel`` group for polkit rule


General requirements
====================

* supported Linux host with yocto build dependencies and tox package installed

With at least Python 3.8 and tox installed, clone this repository, then run
the ``dev`` command to create the yocto build environment. From there, either
use the virtual environment to run kas and/or bitbake commands *or* run one
or more ``tox`` commands to build/deploy specific yocto targets.

Install dependencies on vendor-recommended Ubuntu build host::

  $ sudo apt-get update
  $ sudo apt-get install gawk wget git diffstat unzip texinfo gcc build-essential \
  chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
  iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 \
  xterm python3-subunit mesa-common-dev zstd liblz4-tool libyaml-dev libelf-dev python3-distutils
  $ sudo apt-get install python3-venv tree libgpgme-dev

On ubuntu 20 or 22, install a newer version of tox into user home::

  $ python3 -m pip install -U pip  # this will install into ~/.local/bin
  $ source ~/.profile
  $ which pip3
  /home/user/.local/bin/pip3
  $ pip3 install tox

Setup micro-SDCard
------------------

We need access to the External Drive to be utilized by the target device.
Run lsblk to help figure out what linux device has been reserved for your
External Drive. To compare state, run ``lsblk`` before inserting the USB
card reader, then run the same command again with the USB device inserted.

Example: for DISK=/dev/sdX

::

  $ lsblk
  NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
  sda      8:0    0 465.8G  0 disk
  ├─sda1   8:1    0   512M  0 part /boot/efi
  └─sda2   8:2    0 465.3G  0 part /                <- Development Machine Root Partition
  sdb      8:16   1   962M  0 disk                  <- microSD/USB Storage Device
  └─sdb1   8:17   1   961M  0 part                  <- microSD/USB Storage Partition

Thus your value is ``DISK=/dev/sdb``

Example: for DISK=/dev/mmcblkX

::

  $ lsblk
  NAME      MAJ:MIN   RM   SIZE RO TYPE MOUNTPOINT
  sda         8:0      0 465.8G  0 disk
  ├─sda1      8:1      0   512M  0 part /boot/efi
  └─sda2      8:2      0 465.3G  0 part /                <- Development Machine Root Partition
  mmcblk0     179:0    0   962M  0 disk                  <- microSD/MMC Storage Device
  └─mmcblk0p1 179:1    0   961M  0 part                  <- microSD/MMC Storage Partition

Thus your value is ``DISK=/dev/mmcblk0`` which is the default workflow value
so may be omitted.

.. note:: The qspi deployment workflow SDCard requirement is essentially
          "the first partition must be ``VFAT``". This allows both the
          enclustra bootable SDCard *or* an empty VFAT-formatted card
          to be used as the deployment DISK target. If your board has
          been set to boot from QSPI, then there is no need to change
          the boot target. Just build the ``qspi`` artifacts and use a
          blank VFAT-formatted sdcard for the deployment workflow.


Usage
=====

The commands shown below will clone the required yocto layers along with some
tools, then build and install the python deps for running build and deploy
commands. The install results will end up in a tox virtual environment
named ``.venv`` which you can activate for manual use as needed.

The tox/kas commands create two directories to contain the yocto metadata
and build outputs, ie, ``layers`` and ``build`` respectively. Note the Kas_
tool treats both these directories as *transitory*, however, development
workflows include testing yocto changes inside ``build/conf`` as well as
preserving yocto ``downloads`` and ``sstate_cache`` to speed up builds.

Tox commands
------------

From inside the repository checkout, use  ``tox list`` to view the list of
workflow environment descriptions::

  $ tox list
  ...
  default environments:
  dev     -> Create a kas build virtual environment with managed deps
  bmap    -> Burn the wic image to sdcard device (default: /dev/mmcblk0)
  emmc    -> Build the (wic) emmc boot target
  sdmmc   -> Build the default (wic) sdmmc boot target
  qspi    -> Clean and build the qspi boot target
  deploy  -> Deploy qspi build products to sdcard


.. note:: The default DISK value shown below is at least somewhat "safe"
          as it is not likely to be critical on most development hardware.
          If the value you provide, or the default device, does not exist,
          then the deploy script will skip the sdcard deployment when
          there is no device to mount.


Also note the primary tox commands given here are order-dependent, eg::

  $ tox -e qspi                   # first build the qspi flash artifacts
  $ DISK=/dev/sda tox -e deploy   # then deploy the qspi artifacts to an existing sdcard


Same goes for sdcard creation::

  $ tox -e sdmmc|emmc             # first build the ``.wic`` image
  $ DISK=/dev/sda tox -e bmap     # then burn the image to an sdcard


Remember, the ``emmc`` ``.wic`` image is *not* bootable using the sdcard,
rather, this sdcard is used to transfer the rootfs to the emmc flash from
u-boot.

Additional Tox environment commands include::

  $ tox -e changes    # generate a changelog
  $ tox -e clean      # clean build artifacts/tmp dir


.. important:: When running tox commands using an existing build tree, it is
               advisable to run ``tox -e clean`` before (re)building the qspi
               or sdmmc artifacts.

Kas commands
------------

First create a (Python) virtual environment for Kas using one of the following
methods; note the extra commands when creating it manually.

Use the Tox ``dev`` command::

  $ tox -e dev
  $ source .venv/bin/activate

Or create one manually::

  $ python -m venv .venv
  $ source .venv/bin/activate
  (.venv) $ python -m pip install kas
  (.venv) $ mkdir layers
  (.venv) $ git clone https://github.com/VCTLabs/meta-user-aa1.git -b oe-mickledore layers/meta-user-aa1


.. note:: Several (Yocto) build variables are given default values in the
          kas config files, mainly to provide a consistent baseline for
          kas commands. Thus the default machine name and image target are
          defined in ``base.yaml``.  These values can be overridden on the
          command line as shown below.


Run the kas ``checkout`` command to (re)init Yocto build environment::

   (.venv) $ kas checkout layers/meta-user-aa1/kas/sysvinit.yaml

Use the kas ``build`` command to build the default image target::

  (.venv) $ kas build layers/meta-user-aa1/kas/sysvinit.yaml

The above is essentially what the first two tox commands do, but how to use
the `` bitbake`` commands?

Use the kas ``shell`` command to run arbitrary commands within the Yocto
environment managed by kas.

Build a non-default image::

  (.venv) $ kas shell layers/meta-user-aa1/kas/sysvinit.yaml -c 'bitbake devel-image-data'

Build a specific software recipe::

  (.venv) $ kas shell layers/meta-user-aa1/kas/sysvinit.yaml -c 'bitbake libuio-ng'

Override kas defaults::

  (.venv) $ kas shell layers/meta-user-aa1/kas/sysvinit.yaml -c 'UBOOT_CONFIG=sdmmc bitbake devel-image-data'

Adjust the default kernel config::

  (.venv) $ kas shell layers/meta-user-aa1/kas/sysvinit.yaml -c 'bitbake -c kernel_configme virtual/kernel'
  (.venv) $ kas shell layers/meta-user-aa1/kas/sysvinit.yaml -c 'bitbake -c menuconfig virtual/kernel'
  (.venv) $ kas shell layers/meta-user-aa1/kas/sysvinit.yaml -c 'bitbake -c diffconfig virtual/kernel'

The third command above will generate a config fragment with the changes
and display the path to the file with extension ``.cfg``, eg, something like
``long/path/to/config/fragment.cfg`` (see the `example here`_). Also note
the `Yocto dev-manual`_ has even more useful info.


.. _example here: https://wiki.koansoftware.com/index.php/Modify_the_linux_kernel_with_configuration_fragments_in_Yocto
.. _Yocto dev-manual: https://docs.yoctoproject.org/dev-manual/index.html


Workflow support files
----------------------

In terms of development functionality, there is essentially one "support"
file required, that being the kas build config. The default vendor build
lives in the (now unused) ``enclustra-refdes`` layer, and the new custom
build configurations live in the ``meta-user-aa1`` layer.

The main functionality and development user knobs are contained directly
in the parent repo ``tox.ini`` file (any helper scripts can be found in
the ``scripts`` directory).

Default options are set as tox environment variables with defaults matching
the yocto build tree, machine, and image names::

    DEPLOY_DIR = {env:DEPLOY_DIR:build/tmp-glibc/deploy/images/{env:MACHINE}}
    DISK = {env:DISK:/dev/mmcblk0}
    IMAGE = {env:IMAGE:devel-image-minimal}
    MACHINE = {env:MACHINE:me-aa1-270-2i2-d11e-nfx3}
    UBOOT_CONFIG = {env:UBOOT_CONFIG:{envname}}


Expected build warnings
-----------------------

Currently expected build warnings are listed below; any additional warnings
are most likely specific to a given build environment.

:too-new-gcc: WARNING: Your host glibc version (2.39) is newer than that
              in uninative (2.37). Disabling uninative so that sstate is
              not corrupted.
:missing-checksum: WARNING: exported-binaries-1.0-r0 do_fetch: Missing
                   checksum... occurs when recipe uses ``BB_STRICT_CHECKSUM = "0"``
                   in exported-binaries and hellogitcmake.

.. note:: When using cmake in a bitbake recipe, you must also inherit the
          ``pkgconfig`` bbclass when using (cmake's) PkgConfig module.


Full QSPI flash example using Tox
---------------------------------

End-to-end ``qspi`` flash example assuming a clean parent repository checkout.
The following example runs the build/deploy commands to the bootable sdcard
for deploying and installing the qspi build artifacts. After installing
the yocto build dependencies and Tox_, run the following commands from
a terminal window; note the first-time build will download several large
source artifacts and build several thousand packages.

Step 1. Create the required artifacts.

::

  $ cd $HOME/src
  $ git clone https://github.com/VCTLabs/vct-enclustra-bsp-platform.git
  $ cd vct-enclustra-bsp-platform/
  $ tox -e dev                   # fetch all yocto layers
  $ tox -e sdmmc                 # build a bootable sdcard image --or--
  $ IPP="192.168.7.122:8080" tox -e sdmmc  # to set the pkg feed IP and port
  # <insert USB card reader or sdcard>
  $ DISK=/dev/sda tox -e bmap    # USE YOUR SDCARD DEVICE
  $ tox -e qspi                  # build qspi flash artifacts
  $ DISK=/dev/sda tox -e deploy  # USE YOUR SDCARD DEVICE

The last few lines of console messages should look like this::

  Unmounted /dev/sda1.
  Done.
    deploy: OK (5.84=setup[0.04]+cmd[0.00,5.79] seconds)
    congratulations :) (5.91 seconds)

Step 2. Insert the SD card you just created in the AA1 card slot.

Step 3. Attach serial console, power up the board, and stop the boot at the u-boot prompt.

Step 4. From the u-boot prompt, run the following two commands marked by comments:

::

  => load mmc 0:1 ${loadaddr} flash.scr  # load flash script
  1079 bytes read in 6 ms (174.8 KiB/s)
  => source ${loadaddr}                  # run flash script, then WAIT
  ## Executing script at 01000000
  switch to partitions #0, OK
  ...  # output snipped
  device 0 offset 0x1000000, size 0x1000000
  6029312 bytes written, 10747904 bytes skipped in 22.35s, speed 798915 B/s
  device 0 offset 0x2000000, size 0x2000000
  23330816 bytes written, 10223616 bytes skipped in 74.150s, speed 466033 B/s
  =>


Step 5. Confirm success and power OFF the board.

Step 6. Remove the SD card and configure the hardware for QSPI boot.


Full EMMC flash example using Tox (vendor version)
--------------------------------------------------

End-to-end ``emmc`` flash example assuming a clean parent repository checkout.
The following example runs the build/deploy commands to make the bootable
sdcard and (not)bootable emmc-on-sdcard for installing via u-boot commands.
After installing the yocto build dependencies and Tox_, run the following
commands from a terminal window.

1. Create the required artifacts:

::

  $ cd $HOME/src
  $ git clone https://github.com/VCTLabs/vct-enclustra-bsp-platform.git
  $ cd vct-enclustra-bsp-platform/
  $ tox -e dev                   # init env and/or fetch yocto layers
  $ tox -e sdmmc                 # build a bootable sdcard image
  # <insert USB card reader or sdcard>
  $ DISK=/dev/sda tox -e bmap    # USE YOUR SDCARD DEVICE
  $ tox -e clean                 # clean the build/tmp dir
  $ tox -e emmc                  # build a bootable emmc image
  # <insert USB card reader or sdcard *using a different sdcard*>
  $ DISK=/dev/sda tox -e bmap    # USE YOUR SDCARD DEVICE


2. Insert the first SD card you just created in the AA1 card slot

3. Attach serial console, power up the board, and stop the boot at the u-boot prompt

4. Replace the SD card with the *second* one containing the eMMC image

5. Copy the SD card content into the DDR memory using the updated size::

    => mmc rescan
    => mmc dev 0
    => mmc read 0 0 0x114800

    MMC read: dev # 0, block # 0, count 1132544 ... 1132544 blocks read: OK

5. Switch to the eMMC device::

    => altera_set_storage EMMC

6. Copy the data from the DDR memory to the eMMC flash::

    => mmc rescan
    => mmc write 0 0 0x114800

    MMC write: dev # 0, block # 0, count 1132544 ... 1132544 blocks written: OK

7. When completed, power off the board, remove the SD card, and configure
   the hardware for EMMC boot

Alternate flash example using wic image and tftp
------------------------------------------------

This method requires the following conditions:

* board can boot to the u-boot prompt from any of the available media (sdmmc, emmc, qspi)
* an available tftp server for the yocto build directory
* successful enclustra build of emmc image
* we also assume the build host and enclustra board are on the same LAN
  segment with a free static IP address for the board

1. From a fresh checkout, create the required artifacts:

::

    $ git clone https://github.com/VCTLabs/vct-enclustra-bsp-platform.git
    $ cd vct-enclustra-bsp-platform/
    $ tox -e dev                   # init env and/or fetch yocto layers
    $ tox -e emmc                  # build a bootable emmc image


2. Enter the virtual environment and start the provided tftp server;
   alternately use your own:

::

    $ source .venv/bin/activate
    (.venv) $ export DOCROOT=build/tmp-glibc/deploy/images/me-aa1-270-2i2-d11e-nfx3/
    (.venv) $ export IFACE=0.0.0.0
    (.venv) $ export PORT=69
    (.venv) $ export DEBUG=1  # optional for additional logging
    (.venv) $ tftpdaemon start

If using the provided tftp server above, observe the log path printed on
startup and use ``tail -f <filename>`` to observe log messages.

Without the DEBUG export, the status command will display the PID file path::

    (.venv) $ tftpdaemon status
    pidfile /home/user/.cache/pyserv/tftpd.pid found, daemon PID is 19099

3. Boot the enclustra board and stop it at the u-boot prompt:

::

    U-Boot 2023.01 (Jun 20 2023 - 00:59:09 +0000)socfpga_arria10

    CPU:   Altera SoCFPGA Arria 10
    BOOT:  SD/MMC External Transceiver (1.8V)
    Model: Enclustra Mercury+ AA1
    DRAM:  2 GiB
    Core:  82 devices, 22 uclasses, devicetree: separate
    MMC:   dwmmc0@ff808000: 0
    Loading Environment from FAT... Unable to read "uboot.env" from mmc0:1...
    In:    serial
    Out:   serial
    Err:   serial
    Model: Enclustra Mercury+ AA1
    Net:   eth0: ethernet@ff800000
    Hit any key to stop autoboot:  0
    =>

4. Set the tftp server address and give the board a static IP address
   (assumed to be on the same subnet)::

    => setenv serverip 192.168.7.134  # yocto build host
    => setenv ipaddr 192.168.7.99     # enclustra board
    => saveenv                        # make the values persistent

5. Load the emmc flash image into memory::

    => tftp 0 devel-image-minimal-me-aa1-270-2i2-d11e-nfx3-20241219200909.rootfs.wic

6. Wait for the image to load::

    ...
    #####################################################################
    #####################################################################
    #####################################################################
    done
    Bytes transferred = 579862528 (22900000 hex)

7. Copy the data from the DDR memory to the eMMC flash::

    => altera_set_storage EMMC  # make sure EMMC device is active
    => mmc rescan
    => mmc write 0 0 0x114800

8. When completed, power off the board, remove the SD card, and configure
   the hardware for EMMC boot (if needed)


.. note:: The emmc flash size shown above is fixed in the .wks files, but
          should continue to work using the size above even with new packages
          and sysvinit or systemd images (up to a point). The size used above
          is calculated and converted to hex as in the following python example.

Get current wic image physical size; the size shown is for the 400 MB
fixed-size rootfs::

    $ ls -l devel-image-minimal-me-aa1-emmc.wic
    -rw-r--r-- 1 user user 579862528 Oct 29 16:47 devel-image-minimal-me-aa1-emmc.wic

Open a python prompt::

    $ python
    Python 3.12.7 (main, Oct 19 2024, 22:38:25) [GCC 14.2.1 20240921] on linux
    Type "help", "copyright", "credits" or "license" for more information.
    >>> hex(579862528 // 512)
    '0x114800'
    >>>

The size to use in the above u-boot ``mmc`` commands is ``0x114800``

MMC images and partitions
=========================

The ``wic`` directory in the ``meta-user-aa1`` layer contains two kickstart
files that mirror the image recipe names. The minimal image has one (usable)
partition for the root filesystem, while the data image also contains an
empty data partition. The new ``resize-last-part`` and ``resize-rootfs``
recipes currently support sysvinit *only*, but feel free to contribute a
systemd unit.

To automatically resize the rootfs/data partitions on MMC devices, include
the following recipe in the ``sysvinit.yaml`` kas config:

* devel-image-minimal - add ``resize-rootfs`` to expand the root partition
* devel-image-data - add ``resize-last-part`` to expand the data partition

Conversely, to leave the existing partitions alone, remove the above recipes
from the kas configuration.

To specify a minimum amount of free space, add the following option to the
``local_conf_header`` section of the desired YAML config, eg:

.. code-block:: yaml

  local_conf_header:
    sysvinit: |
          IMAGE_ROOTFS_EXTRA_SPACE = "524288"
          ...

Yocto dev package feeds
=======================

Yocto/OE supports several package formats in addition to rootfs/image formats,
where the default package format depends on yocto release and/or distribution
(ie, "distro").

* Yocto package formats - ipk, deb, rpm, tar

Potential constraints on choosing a package format include:

* openembedded support in SCAP Security Guide requires ``rpm``

Native package managers are used for each format, and the on-device workflow
is more-or-less the same given the minor command differences between each one.

For example, ``apt-get`` vs. ``dnf``::

  Ubuntu command --- Fedora command
  ---------------------------------
  apt-get update --- dnf check-update  # Note dnf updates its cache automatically
                                       # before performing transactions
  apt-get upgrade --- dnf upgrade
  apt-get install --- dnf install
  apt-get remove --- dnf remove
  apt-get purge --- N/A
  apt-cache search --- dnf search

Package feed development workflow
---------------------------------

There are both recipes and configuration directives to facilitate usage of
package feeds. The simplest way uses the deploy directory of an existing
build tree and a simple web server (eg, the Python ``http.server`` module).
Howver, an existing build tree is not a "stable" source for production
workflows so the Yocto manual recommends copying the package tree to a
more stable location on a "production" web server.

.. important:: *Do not* install the ``distro-feed-configs`` package when using
   the development workflow, rather *do* use the PACKAGE_FEED_URIS_ config
   shown below. For production feeds, review the recipe and make your own
   ``distro-feed-configs.bbappend`` recipe with your chosen options.

Whenever you perform any sort of build step that can potentially generate a
package or modify existing packages, it is always a good idea to re-generate
the package index *after* the build by using the following command::

  $ bitbake package-index


Package feed quick start
------------------------

* the PACKAGE_FEED_URIS_ parameter is a list of one or more feed URIs
  starting with ``http://``

  - for python web server, use the IP address of the build server and
    a non-privileged port number, something like ``192.168.0.123:8000``

The following is required for simple dev package feeds:

* a local web server with document root set to the top-level package
  directory in the build tree
* dev package feed setup with the build host (domain) name *or* IP address
  and port number (as in the above example)
* a build image with package feed config and package management feature
  enabled

Given the current kas config, initialize one of the build options with
the build host web server address, something like::

   $ IPP="192.168.1.42:8080" tox -e emmc

Start the provided web server in the top-level directory with corresponding
options::

    $ source .venv/bin/activate
    (.venv) $ export DOCROOT=build/tmp-glibc/deploy/ipk
    (.venv) $ export IFACE=0.0.0.0
    (.venv) $ export PORT=8080
    (.venv) $ export DEBUG=1  # optional for additional logging
    (.venv) $ httpdaemon start

If using the provided http server above, observe the log path printed on
startup and use ``tail -f <filename>`` to observe log messages.

Without the DEBUG export, the status command will display the PID file path::

    $ httpdaemon status
    pidfile /home/user/.cache/pyserv/httpd.pid found, daemon PID is 7461


Dev package feed setup
----------------------

The ``deploy`` directory in a Yocto/OE build tree typically contains both
package feeds and the build images, and is found under the ``build/tmp*``
directory. A typical kas-created layout looks something like this::

  $ ls build/ layers/
  build/:
  bitbake-cookerdaemon.log  cache  conf  downloads  sstate-cache  tmp-glibc

  layers/:
  bitbake                 meta-intel-fpga    meta-user-aa1
  meta-enclustra-socfpga  meta-openembedded  openembedded-core

Where the ``tmp`` directory in a default OE build is named ``tmp-glibc``::

  $ ls build/tmp-glibc/deploy
  images  licenses  rpm

The web server document root in this situation would be the ``rpm`` directory::

  build/tmp-glibc/deploy/rpm

when using a development workflow and is the working directory (and web root)
for a web server running on the build host.

Starting a web server in the package directory without setting any extra
build parameters requires the target device to generate its own package cache,
however, this is handled automatically when using the following build setting,
something like::

  PACKAGE_FEED_URIS = "http://<build_server_IP>:8000"

The above will setup each of the build architectures under the ``rpm`` directory
as a package feed. For customizing a development setup, use the additional params
as needed:

* PACKAGE_FEED_ARCHS_
* PACKAGE_FEED_BASE_PATHS_

.. _PACKAGE_FEED_URIS: https://docs.yoctoproject.org/ref-manual/variables.html#term-PACKAGE_FEED_URIS
.. _PACKAGE_FEED_ARCHS: https://docs.yoctoproject.org/ref-manual/variables.html#term-PACKAGE_FEED_ARCHS
.. _PACKAGE_FEED_BASE_PATHS: https://docs.yoctoproject.org/ref-manual/variables.html#term-PACKAGE_FEED_BASE_PATHS

For more details, see the Yocto dev-manual section on `Runtime Package Management`_
and Digital Ocean's `package manager comparison`_.

.. _Runtime Package Management: https://docs.yoctoproject.org/dev-manual/packages.html#using-runtime-package-management
.. _package manager comparison: https://www.digitalocean.com/community/tutorials/package-management-basics-apt-yum-dnf-pkg
