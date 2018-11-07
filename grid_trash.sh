#!/bin/bash 
echo "setting up software base"
#export CODE_BASE=/grid/fermiapp/products
export CODE_BASE=/cvmfs/fermilab.opensciencegrid.org/products
source ${CODE_BASE}/common/etc/setup
export PRODUCTS=${PRODUCTS}:${CODE_BASE}/larsoft

setup geant4 v4_10_1_p02a -q e9:debug:qt

# replaced with function below 11-03-18
#setup genie v2_12_0a -q debug:e10:r6
#setup genie_xsec v2_12_0 -q DefaultPlusMECWithNC
#setup genie_phyopt v2_12_0 -q dkcharmtau
#setup -q debug:e10 xerces_c v3_1_3

setup_genie_2_12(){
  if [ -z "$GVERS"    ]; then export GVERS="v2_12_0"             ; fi
  if [ -z "$GQAUL"    ]; then export GQUAL="debug:e10:r6"         ; fi
  if [ -z "$XSECQUAL" ]; then export XSECQUAL="DefaultPlusMECWithNC" ; fi
  setup genie        ${GVERS}a -q ${GQUAL}
  setup genie_phyopt ${GVERS} -q dkcharmtau
  # do phyopt before xsec in case xsec has its own UserPhysicsOptions.xml
  setup genie_xsec   ${GVERS} -q ${XSECQUAL}
  if [ $? -ne 0 ]; then
    # echo "$b0: looking for genie_xec ${GVERS}a -q ${XSECQUAL}"
    # might have a letter beyond GENIE code's
    setup genie_xsec   ${GVERS}a -q ${XSECQUAL}
  fi
  
  setup ifdhc   # for copying geometry & flux files
  export IFDH_CP_MAXRETRIES=2  # default 8 tries is silly
  
  setup -q debug:e10 xerces_c v3_1_3  # do we need xerces? for which genie?
  
  #others from setup_setup used for genie file generation... needed?
  #setup pandora v01_01_00a -q debug:e7:nu
  #setup dk2nu v01_01_03a -q debug:e7    ## or version: setup dk2nu v01_03_00c -q debug:e9:r5  ?
  #setup cstxsd v4_0_0b -q e7
  #setup boost v1_57_0 -q debug:e7
}

setup_genie_2_12

setup -q debug:e10:nu root v6_06_08
source ${CODE_BASE}/larsoft/root/v6_06_08/Linux64bit+2.6-2.12-e10-nu-debug/bin/thisroot.sh

setup -q debug:e9 clhep v2_2_0_8
setup -f Linux64bit+2.6-2.12 cmake v2_8_8
#setup cmake     #sets up 2_8_8
setup fife_utils

export XERCESROOT=${CODE_BASE}/larsoft/xerces_c/v3_1_3/Linux64bit+2.6-2.12-e10-debug
export G4SYSTEM=Linux-g++
export ROOT_PATH=${CODE_BASE}/larsoft/root/v6_06_08/Linux64bit+2.6-2.12-e10-nu-debug/cmake
export GEANT4_PATH=${GEANT4_FQ_DIR}/lib64/Geant4-10.1.2
export GEANT4_MAKEFULL_PATH=${GEANT4_DIR}/${GEANT4_VERSION}/source/geant4.10.01.p02
export ROOT_INCLUDE_PATH=${ROOT_INCLUDE_PATH}:${GENIE}/../include/GENIE
export ROOT_LIBRARY_PATH=${ROOT_LIBRARY_PATH}:${GENIE}/../lib
#export LD_LIBRARY_PATH=/annie/app/users/moflaher/wcsim/wcsim:$LD_LIBRARY_PATH
#export ROOT_INCLUDE_PATH=/annie/app/users/moflaher/wcsim/wcsim/include:$ROOT_INCLUDE_PATH

