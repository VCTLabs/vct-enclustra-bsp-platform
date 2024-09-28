VCT enclustra BSP startup
=========================

The upstream Yocto build metadata mimics the (original) Altera/Intel
``socfpga`` layers, but since it is a Brand New first release, it uses
the ``mickledore`` branches and a KAS_ build configuration.

.. _KAS: https://kas.readthedocs.io/en/latest/command-line.html

Quick start steps:

* cd somewhere
* clone this repo with -b <branch>
* cd repo/
* create .venv with ``tox -e dev``
* view/edit the KAS configuration file ``layers/meta-user-aa1/build.yml``

Defaults are now the custom machine and user layer image, along with ``qspi``
as default build config. User build knobs include:

1. the desired machine key, eg: ``me-aa1-270-2i2-d11e-nfx3``
2. the ``UBOOT_CONFIG`` env key setting for build cfg and boot media

* check the contents of ``build/local.conf`` and ``build/bblayers.conf``
  and adjust as needed

* run ``tox -e qspi`` to build the minimal devel image

Run KAS directly without Tox
============================

1. create a Python virtual environment in this checkout, activate it, and
   install kas:

::

   $ python -m venv .venv
   $ source .venv/bin/activate
   (.venv) $ python -m pip install kas

2. clone the "user" layer (where the new kas build.yml lives):

::

   (.venv) $ mkdir layers && cd layers/
   (.venv) $ git clone https://github.com/VCTLabs/meta-user-aa1.git -b oe-mickledore
   (.venv) $ cd -

3. view/edit the kas file ``layers/meta-user-aa1/build.yml`` and check/set
   the desired value for the ``UBOOT_CONFIG`` key

4. fetch the required metadata layers and build default qspi devel image:

::

   (.venv) $ kas checkout layers/meta-user-aa1/build.yml
   (.venv) $ kas build layers/meta-user-aa1/build.yml


The first command in step 4 above will populate the ``layers`` directory
with the cloned layers and create a build folder creatively named ``build``.

By default all of the downloaded sources and locally created sstate
cache files are also in the ``build`` folder but can be relocated to a
more convenient/shared location by using some `environment variables`_
as shown below; set them before running the ``build`` command::

  (.venv) $ export DL_DIR="${HOME}/shared/downloads"
  (.venv) $ export SSTATE_DIR="${HOME}/shared/oe/sstate-cache"

.. note:: You may need to create the above directories manually before
          starting a new build.

The (yocto) build config files can be found in the usual place in the
``build`` folder, ie::

  (.venv) $ ls build/conf/
  bblayers.conf  local.conf  templateconf.cfg

Note that changes made to the config files inside ``build/conf/`` are only
temporary as Kas treats everything in the build folder as transitory. Any
changes you wish to keep should be migrated to a Kas config file.

.. _environment variables: https://kas.readthedocs.io/en/latest/command-line.html#variables-glossary

.. important:: *Do not* delete the build folder to start a fresh build,
              rather *do* remove ``build/tmp-glibc`` for that very purpose.

The initial build must fetch and build a large number of components, including
several *very* large git repositories, so the first build can take several hours.

When finished, check the results::

    (.venv) $ ls -1 build/tmp-glibc/deploy/images/<machine>/
    bitstream.core.rbf
    bitstream.itb
    bitstream.periph.rbf
    boot-emmc.scr
    boot-qspi.scr
    boot-sdmmc.scr
    boot.scr
    devicetree
    devicetree.dtb
    fit_spl_fpga.itb
    handoff
    image-minimal-refdes-refdes-me-aa1-270-2i2-d11e-nfx3-st1-20240808203438.rootfs.cpio.gz.u-boot
    image-minimal-refdes-refdes-me-aa1-270-2i2-d11e-nfx3-st1-20240808203438.rootfs.manifest
    image-minimal-refdes-refdes-me-aa1-270-2i2-d11e-nfx3-st1-20240808203438.rootfs.tar.gz
    image-minimal-refdes-refdes-me-aa1-270-2i2-d11e-nfx3-st1-20240808203438.rootfs.wic
    image-minimal-refdes-refdes-me-aa1-270-2i2-d11e-nfx3-st1-20240808203438.rootfs.wic.bmap
    image-minimal-refdes-refdes-me-aa1-270-2i2-d11e-nfx3-st1-20240808203438.testdata.json
    image-minimal-refdes-refdes-me-aa1-270-2i2-d11e-nfx3-st1.cpio.gz.u-boot
    image-minimal-refdes-refdes-me-aa1-270-2i2-d11e-nfx3-st1.manifest
    image-minimal-refdes-refdes-me-aa1-270-2i2-d11e-nfx3-st1.tar.gz
    image-minimal-refdes-refdes-me-aa1-270-2i2-d11e-nfx3-st1.testdata.json
    image-minimal-refdes-refdes-me-aa1-270-2i2-d11e-nfx3-st1.wic
    image-minimal-refdes-refdes-me-aa1-270-2i2-d11e-nfx3-st1.wic.bmap
    image-minimal-refdes.env
    modules--6.1.38-lts+git0+21b5300ed5-r0-refdes-me-aa1-270-2i2-d11e-nfx3-st1-20240808203438.tgz
    modules-refdes-me-aa1-270-2i2-d11e-nfx3-st1.tgz
    socfpga_enclustra_mercury_emmc_overlay.dtbo
    socfpga_enclustra_mercury_qspi_overlay.dtbo
    socfpga_enclustra_mercury_sdmmc_overlay.dtbo
    u-boot-refdes-me-aa1-270-2i2-d11e-nfx3-st1.sfp
    u-boot-refdes-me-aa1-270-2i2-d11e-nfx3-st1.sfp-sdmmc
    u-boot-sdmmc-v2023.01+gitAUTOINC+0fa4e757b5-r0.sfp
    u-boot-socfpga-initial-env-refdes-me-aa1-270-2i2-d11e-nfx3-st1-sdmmc
    u-boot-socfpga-initial-env-refdes-me-aa1-270-2i2-d11e-nfx3-st1-sdmmc-v2023.01+gitAUTOINC+0fa4e757b5-r0
    u-boot-socfpga-initial-env-sdmmc
    u-boot-splx4.sfp
    u-boot-splx4.sfp-refdes-me-aa1-270-2i2-d11e-nfx3-st1
    u-boot-splx4.sfp-refdes-me-aa1-270-2i2-d11e-nfx3-st1-sdmmc
    u-boot-splx4.sfp-sdmmc
    u-boot-splx4.sfp-sdmmc-v2023.01+gitAUTOINC+0fa4e757b5-r0
    u-boot.img
    u-boot.img-sdmmc
    uImage
    uImage--6.1.38-lts+git0+21b5300ed5-r0-refdes-me-aa1-270-2i2-d11e-nfx3-st1-20240808203438.bin
    uImage-refdes-me-aa1-270-2i2-d11e-nfx3-st1.bin

Since it already has all of the important bits, the main file(s) of interest
in the listing above are the files ending in ``*.wic[.bmap]`` which are
"raw" disk images used to flash MMC devices. Use these to create a bootable
SDCard or USB stick.

Many of the above are symlinks, but mainly there should be some obvious
file types:

* yocto build image files
* FPGA bitstream files
* kernel image, modules, and device tree files
* u-boot image, boot script, and env files
* the ``handoff`` directory

The latter directory includes the Quartus project integration "glue" required\
to build the full sysem images. See the README.socfpga_ file in the U-boot
source tree for the handoff "bridge" manual process description.

.. _README.socfpga: https://github.com/u-boot/u-boot/blob/master/doc/README.socfpga


Notes on Enclustra BSP for Cyclone/Arria FPGA HW
================================================

meta-enclustra-socfpga has one branch: v2023.1

* https://github.com/enclustra/meta-enclustra-socfpga

Contains two meta-layers:

* meta-enclustra-module - BSP layer for enclustra
* meta-enclustra-refdes - reference designs using enclustra BSP

The top-level readme is not boiler-plate, but contains changelog and
integration bits, some of which are shown below:

* Yocto branch: mickledore
* U-Boot: 2023.01
* Linux kernel: 6.1.0

based on meta-intel-fpga: https://git.yoctoproject.org/meta-intel-fpga

Supported Devices
-----------------

  ===============  =================  ===========
  Family           Module , Revision  Base Boards
  ===============  =================  ===========
  Intel Cyclone V  Mercury  SA1 , R3  Mercury+ PE1 / Mercury+ PE3 / Mercury+ ST1
  Intel Cyclone V  Mercury+ SA2 , R1  Mercury+ PE1 / Mercury+ PE3 / Mercury+ ST1
  Intel Arria 10   Mercury+ AA1 , R2  Mercury+ PE1 / Mercury+ PE3 / Mercury+ ST1
  ===============  =================  ===========


Reference Designs for Intel Quartus II
--------------------------------------

The meta-enclustra-refdes_ Yocto layer in this reference design uses
prebuilt binaries for the following reference designs:

.. _meta-enclustra-refdes: https://github.com/enclustra/meta-enclustra-socfpga/blob/v2023.1/meta-enclustra-refdes

* Mercury+ AA1 PE1 Reference Design https://github.com/enclustra/Mercury_AA1_PE1_Reference_Design
* Mercury+ AA1 PE3 Reference Design https://github.com/enclustra/Mercury_AA1_PE3_Reference_Design
* Mercury+ AA1 ST1 Reference Design https://github.com/enclustra/Mercury_AA1_ST1_Reference_Design

* Mercury SA1 PE1 Reference Design https://github.com/enclustra/Mercury_SA1_PE1_Reference_Design
* Mercury SA1 PE3 Reference Design https://github.com/enclustra/Mercury_SA1_PE3_Reference_Design
* Mercury SA1 ST1 Reference Design https://github.com/enclustra/Mercury_SA1_ST1_Reference_Design

* Mercury+ SA2 PE1 Reference Design https://github.com/enclustra/Mercury_SA2_PE1_Reference_Design
* Mercury+ SA2 PE3 Reference Design https://github.com/enclustra/Mercury_SA2_PE3_Reference_Design
* Mercury+ SA2 ST1 Reference Design https://github.com/enclustra/Mercury_SA2_ST1_Reference_Design


Host Requirements
-----------------

Host Operating System:

This reference design build was tested on following operating systems:

* Ubuntu 22.04

Required Packages:

The following packages are required for building this reference design on Ubuntu:

  gawk wget git diffstat unzip texinfo gcc build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 xterm python3-subunit mesa-common-dev zstd liblz4-tool libyaml-dev libelf-dev python3-distutils

