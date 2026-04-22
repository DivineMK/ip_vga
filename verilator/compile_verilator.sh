#!/bin/bash
# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Paul Scheffler <paulsc@iis.ee.ethz.ch>

set -e

export PROJ_NAME=${PROJ_NAME:-"ip_vga"}

[ ! -z "$VERILATOR" ] || VERILATOR=verilator

./run_verilator.sh --flist
sed -i '/pad_functional\.sv/d' ${PROJ_NAME}.f

# cd ../test
# python3 gen_bmp.py --width 640 --height 480 increment.bmp
cd ../verilator
./run_verilator.sh --build
./obj_dir/Vtb_${PROJ_NAME}
