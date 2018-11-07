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

################# CHANGE THESE #####################
# source files
export DIRTDIR=/pnfs/annie/persistent/users/moflaher/g4dirt_rhatcher
export GENIEDIR=/pnfs/annie/persistent/users/rhatcher/genie
export WCSIMDIR=/pnfs/annie/persistent/users/moflaher/wcsim/multipmt/tankonly/wcsim_multipmt_tankonly_17-06-17_rhatcher

# for libWCSim.so and headers
WORKING_DIR=/annie/app/users/moflaher/test_grid_tryout/truthtest
export WCSIM_LOCAL=${WORKING_DIR}/wcsim
export LD_LIBRARY_PATH=${WCSIM_LOCAL}:$LD_LIBRARY_PATH
export ROOT_INCLUDE_PATH=${WCSIM_LOCAL}/include:$ROOT_INCLUDE_PATH

# output
export LOCALOUTDIR=${WORKING_DIR}/root_work/outdir   # for placing files when we're done
export OUTDIR=${WCSIMDIR}_truthana # to copy output files to in cleanup step of grid script

export PROCESS=12
let THENUM=1010

