VCT enclustra BSP startup
=========================

The upstream Yocto build metadata mimics the (original) Altera/Intel
``socfpg`` layers, but since it is a Brand New first release, it uses
the ``mickledore`` branches and a KAS_ build configuration.

.. _KAS: https://kas.readthedocs.io/en/latest/command-line.html

Quick start steps:

* cd somewhere
* clone this repo
* cd repo/
* create venv with kas and activate
* edit the KAS configuration file ``build.yml``

1. comment the machine key at the top (if not correrct)
2. uncomment desired machine key, eg: ``refdes-me-aa1-270-2i2-d11e-nfx3-st1``
3. do the same with the ``UBOOT_CONFIG`` env key, ie, choose the boot media
4. save and exit

* run sync/build commands via tox or kas directly
* sync the layer repositories
* check the contents of ``local.conf`` and ``bblayers.conf`` and adjust
  as needed

Notes on Enclustra BSP for Cyclone/Arria FPGA HW
================================================

meta-enclustra-socfpga has one branch: v2023.1

* https://github.com/enclustra/meta-enclustra-socfpga

Contains two meta-layers:

* meta-enclustra-module - BSP layer for enclustra
* meta-enclustra-refdes - reference design using enclustra BSP

Readme is not boiler-plate, but contians changelog and integration bits,
some of which is shown below:

* Yocto branch: mickledore
* U-Boot: 2023.01
* Linux kernel: 6.1.0

based on meta-intel-fpga: https://git.yoctoproject.org/meta-intel-fpga

Supported Devices
-----------------

Family          | Module , Revision | Base Boards
--------------- | ----------------- | --------------
Intel Cyclone V | Mercury  SA1 , R3 | Mercury+ PE1 / Mercury+ PE3 / Mercury+ ST1
Intel Cyclone V | Mercury+ SA2 , R1 | Mercury+ PE1 / Mercury+ PE3 / Mercury+ ST1
Intel Arria 10  | Mercury+ AA1 , R2 | Mercury+ PE1 / Mercury+ PE3 / Mercury+ ST1

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

