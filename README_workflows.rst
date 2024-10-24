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

* general Linux development host permissions to install/update system packages
* development user added to removable media group, eg, ``disk``
* development user added to ``wheel`` group for polkit rule


General requirements
====================

* supported Linux host with yocto build dependencies and tox package installed
* development user with sudo privileges to install OS packages

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

  $ tox -e sdmmc                  # first build the bootable sdcard image
  $ DISK=/dev/sda tox -e bmap     # then burn the image to an sdcard


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

   (.venv) $ kas checkout layers/meta-user-aa1/kas/systemd.yaml

Use the kas ``build`` command to build the default image target::

  (.venv) $ kas build layers/meta-user-aa1/kas/systemd.yaml

The above is essentially what the first two tox commands do, but how to use
the `` bitbake`` commands?

Use the kas ``shell`` command to run arbitrary commands within the Yocto
environment managed by kas.

Build a non-default image::

  (.venv) $ kas shell layers/meta-user-aa1/kas/systemd.yaml -c 'bitbake devel-image-data'

Build a specific software recipe::

  (.venv) $ kas shell layers/meta-user-aa1/kas/systemd.yaml -c 'bitbake libuio-ng'

Override kas defaults::

  (.venv) $ kas shell layers/meta-user-aa1/kas/systemd.yaml -c 'UBOOT_CONFIG=sdmmc bitbake devel-image-data'

Adjust the default kernel config::

  (.venv) $ kas shell layers/meta-user-aa1/kas/systemd.yaml -c 'bitbake -c kernel_configme virtual/kernel'
  (.venv) $ kas shell layers/meta-user-aa1/kas/systemd.yaml -c 'bitbake -c menuconfig virtual/kernel'
  (.venv) $ kas shell layers/meta-user-aa1/kas/systemd.yaml -c 'bitbake -c diffconfig virtual/kernel'

The third command above will generate a config fragment with your changes
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
          ``pkconfig`` bbclass when using (cmake's) PkgConfig module.


Full QSPI flash example using Tox
---------------------------------

End-to-end ``qspi`` flash example assuming a clean parent repo checkout.
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
  $ tox -e sdmmc                 # build a bootable sdcard image
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
