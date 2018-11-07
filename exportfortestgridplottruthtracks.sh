#!/bin/bash 
export CODE_BASE=/cvmfs/fermilab.opensciencegrid.org/products
source ${CODE_BASE}/common/etc/setup
export PRODUCTS=${PRODUCTS}:${CODE_BASE}/larsoft
setup geant4 v4_10_1_p02a -q e9:debug:qt
setup genie v2_12_0a -q debug:e10:r6
setup genie_xsec v2_12_0 -q DefaultPlusMECWithNC
setup genie_phyopt v2_12_0 -q dkcharmtau
setup -q debug:e10 xerces_c v3_1_3
setup -q debug:e10:nu root v6_06_08
source ${CODE_BASE}/larsoft/root/v6_06_08/Linux64bit+2.6-2.12-e10-nu-debug/bin/thisroot.sh
setup -q debug:e9 clhep v2_2_0_8
setup cmake     #sets up 2_8_8
setup fife_utils

export XERCESROOT=${CODE_BASE}/larsoft/xerces_c/v3_1_3/Linux64bit+2.6-2.12-e10-debug
export G4SYSTEM=Linux-g++
export ROOT_PATH=${CODE_BASE}/larsoft/root/v6_06_08/Linux64bit+2.6-2.12-e10-nu-debug/cmake
export GEANT4_PATH=${GEANT4_FQ_DIR}/lib64/Geant4-10.1.2
export GEANT4_MAKEFULL_PATH=${GEANT4_DIR}/${GEANT4_VERSION}/source/geant4.10.01.p02
export ROOT_INCLUDE_PATH=${ROOT_INCLUDE_PATH}:${GENIE}/../include/GENIE
export ROOT_LIBRARY_PATH=${ROOT_LIBRARY_PATH}:${GENIE}/../lib
export LD_LIBRARY_PATH=${PWD}/../wcsim:$LD_LIBRARY_PATH
export ROOT_INCLUDE_PATH=${PWD}/../wcsim/include:$ROOT_INCLUDE_PATH

export PROCESSOFFSET=0
export PROCESS=12
export FILENUM=${PROCESS}
export WCSIMDIR=/pnfs/annie/persistent/users/moflaher/wcsim_lappd_24-09-17_BNB_Water_10k_22-05-17
export DIRTDIR=/pnfs/annie/persistent/users/moflaher/g4dirt_vincentsgenie/tank
export GENIEDIR=/pnfs/annie/persistent/users/vfischer/genie/BNB_Water_10k_22-05-17
export LOCALOUTDIR="${PWD}/outdir" # <<<<<<<<<<<<<<<<<<<<< THIS

let PROCESSNUM=${PROCESS}+${PROCESSOFFSET}
let SPLITFACTOR=10
let THENUM=$((${PROCESSNUM}/${SPLITFACTOR}))
let INFILE_OFFSETFACTOR=$((${PROCESSNUM}-(${SPLITFACTOR}*${THENUM})))
let INFILE_OFFSET=$((${INFILE_OFFSETFACTOR}*1000))
export INFILE_OFFSET=${INFILE_OFFSET} # <<<<<<<<<<<<<<<<<<<<< AND THIS ARE THE ONLY ONES USED BY PLOTTRUTH.C

echo "this is job PROCESSNUM=${PROCESSNUM}, will process file THENUM=${THENUM}, with offset INFILE_OFFSET=${INFILE_OFFSET}"
OUTFILEEXAMPLE=trueQEvertexinfo.${THENUM}.${INFILE_OFFSETFACTOR}.root
echo "the results will be output to OUTFILEEXAMPLE=${OUTFILEEXAMPLE}"

#these are not used, as root can't open pnfs files directly on grid?
export WCSIMFILE="wcsim_0.${THENUM}.${INFILE_OFFSETFACTOR}.root"
export WCSIMLAPPDFILE="wcsim_lappd_0.${THENUM}.${INFILE_OFFSETFACTOR}.root"
export DIRTFILE=annie_tank_flux.${THENUM}.root
export GENIEFILE=gntp.${THENUM}.ghep.root

