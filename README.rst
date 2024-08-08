VCT enclustra BSP startup
=========================

The upstream Yocto build metadata mimics the (original) Altera/Intel
``socfpg`` layers, but since it is a Brand New first release, it uses
the ``mickledore`` branches and a KAS_ build configuration.

.. _KAS: https://kas.readthedocs.io/en/latest/command-line.html

Quick start steps:

* cd somewhere
* clone this repo with -b <branch>
* cd repo/
* create .venv with ``tox -e dev``
* edit the KAS configuration file ``meta-project/build.yml``

1. comment the machine key at the top (if not correct)
2. uncomment the desired machine key, eg: ``refdes-me-aa1-270-2i2-d11e-nfx3-st1``
3. do the same with the ``UBOOT_CONFIG`` env key, ie, choose the boot media
4. save and exit

* check the contents of ``build/local.conf`` and ``build/bblayers.conf``
  and adjust as needed.

* run ``tox -e dev -- build`` to build refdes image for selected machine

Run KAS directly without Tox
============================

1. create a Python virtual environment, activate it, install kas::

  $ python -m venv .venv
  $ source .venv/bin/activate
  (.venv) $ python -m pip install kas

2. clone the "meta-project" layer (where the kas build.yml lives) and cd
   into it::

  (.venv) $ git clone https://github.com/enclustra/meta-enclustra-socfpga.git -b v2023.1 meta-project
  (.venv) $ cd meta-project/

3. edit the kas file ``meta-project/build.yml`` and check/set the desired
   values for keys ``machine`` and ``UBOOT_CONFIG``
4. fetch the required metadata layers and build default refdes image::

  (.venv) $ kas checkout meta-project/build.yml
  (.venv) $ kas build meta-project/build.yml

The second copmmand above above will populate the ``meta-project``
directory with layers and a build folder creatively named ``build``.
By default all of the downloaded sources and locally created sstate
cache files are also in the ``build`` folder but can be relocated to a
more convenient/shared location by using some `environment variables`_
as shown below; set them before running the ``build`` command::

  (.venv) $ export DL_DIR="${HOME}/shared/downloads"
  (.venv) $ export SSTATE_DIR="${HOME}/shared/poky/sstate-cache"


The (yocto) build config files can be found in the usual place in the
``build`` folder, ie::

  (.venv) $ ls build/conf/
  bblayers.conf  local.conf  templateconf.cfg


.. _environment variables: https://kas.readthedocs.io/en/latest/command-line.html#variables-glossary

Notes on Enclustra BSP for Cyclone/Arria FPGA HW
================================================

meta-enclustra-socfpga has one branch: v2023.1

* https://github.com/enclustra/meta-enclustra-socfpga

Contains two meta-layers:

* meta-enclustra-module - BSP layer for enclustra
* meta-enclustra-refdes - reference design using enclustra BSP

The top-level readme is not boiler-plate, but contains changelog and
integration bits, some of which is shown below:

* Yocto branch: mickledore
* U-Boot: 2023.01
* Linux kernel: 6.1.0

based on meta-intel-fpga: https://git.yoctoproject.org/meta-intel-fpga

Supported Devices
-----------------

.. table:: Enclustra Device Support
   :widths: auto

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

