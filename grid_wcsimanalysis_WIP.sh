#!/bin/bash 
#PROCESSOFFSET=10	# use this to offset PROCESS number, if you need to, for some reason...
unset PROCESSOFFSET

echo "setting up software base"
export CODE_BASE=/grid/fermiapp/products
#export CODE_BASE=/cvmfs/fermilab.opensciencegrid.org/products
source ${CODE_BASE}/common/etc/setup
export PRODUCTS=${PRODUCTS}:${CODE_BASE}/larsoft

setup -q debug:e10:nu root v6_06_08
source ${CODE_BASE}/larsoft/root/v6_06_08/Linux64bit+2.6-2.12-e10-nu-debug/bin/thisroot.sh

setup -q debug:e9 clhep v2_2_0_8
setup cmake     #sets up 2_8_8
setup fife_utils

export ROOT_PATH=${CODE_BASE}/larsoft/root/v6_06_08/Linux64bit+2.6-2.12-e10-nu-debug/cmake
#export LD_LIBRARY_PATH=/annie/app/users/moflaher/wcsim/wcsim:$LD_LIBRARY_PATH
#export ROOT_INCLUDE_PATH=/annie/app/users/moflaher/wcsim/wcsim/include:$ROOT_INCLUDE_PATH


# copy the source files
SOURCEFILEDIR=/pnfs/annie/scratch/users/moflaher
SOURCEFILEZIP=wcsimanalysis.zip
echo "searching for source files in ${SOURCEFILEDIR}/${SOURCEFILEZIP}"
echo "ifdh ls ${SOURCEFILEDIR}"
ifdh ls ${SOURCEFILEDIR}
ifdh ls ${SOURCEFILEDIR}/${SOURCEFILEZIP} 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "copying source files"
  ifdh cp -D ${SOURCEFILEDIR}/${SOURCEFILEZIP} .
else 
  echo "source file zip ${SOURCEFILEZIP} not found in ${SOURCEFILEDIR}!"
  exit 11
fi

# extract and compile the application
echo "unzipping source files"
tar zxvf ${SOURCEFILEZIP}


## ======================================================================this to be replaced by SAM
# copy the list of input files
INPUTFILELISTDIR=/pnfs/annie/scratch/users/moflaher
INPUTFILELISTNAME=wcsimanalysisfilenums.txt
echo "searching for input file list in ${INPUTFILELISTDIR}/${INPUTFILELISTNAME}"
echo "ifdh ls ${INPUTFILELISTDIR}"
ifdh ls ${INPUTFILELISTDIR}
ifdh ls ${INPUTFILELISTDIR}/${INPUTFILELISTNAME} 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "copying input file list"
    ifdh cp -D ${INPUTFILELISTDIR}/${INPUTFILELISTNAME} .   # list of input files
else
    echo "${INPUTFILELISTNAME} not found in ${INPUTFILELISTDIR}! Trying alternatives..."
    for INLISTLOC in /pnfs/annie/persistent/users/moflaher \
                     /annie/app/users/moflaher/wcsim
    do
      echo "try copy from ${INLISTLOC}"
      ifdh cp -D ${INLISTLOC}/${INPUTFILELISTNAME} .
      if [ ! -f ${INPUTFILELISTNAME} ]; then continue; fi
    done
    if [ ! -f ${INPUTFILELISTNAME} ]; then
      echo "input file list not found in any accessible locations!!!"
      exit 13
    fi
fi

# calculate the input file to use
let THECOUNTER=${PROCESS}+${PROCESSOFFSET}+1
THENUM=`less ${INPUTFILELISTNAME} | sed -n ${THECOUNTER},${THECOUNTER}p`
echo "this job has process ${PROCESS}, and will use file num ${THENUM}"

# copy the input files
WCSIMDIR=/pnfs/annie/persistent/users/moflaher/wcsim
WCSIMFILE=wcsim_lappd_0.${THENUM}.root

echo "copying the input files ${DIRTDIR}/${DIRTFILE} and ${GENIEDIR}/${GENIEFILE}"
ifdh cp -D ${DIRTDIR}/${DIRTFILE} .
ifdh cp -D ${GENIEDIR}/${GENIEFILE} .
if [ ! -f ${DIRTFILE} ]; then echo "dirt file not found!!!"; exit 14; fi
if [ ! -f ${GENIEFILE} ]; then echo "genie file not found!!!"; exit 15; fi

## ======================================================================this to be replaced by SAM 

# run executable here, rename the output file
NOWS=`date "+%s"`
DATES=`date "+%Y-%m-%d %H:%M:%S"`
echo "checkpoint start @ ${DATES} s=${NOWS}"
echo " "

root -q -b '${PWD}/callcode.cxx'

echo " "
NOWF=`date "+%s"`
DATEF=`date "+%Y-%m-%d %H:%M:%S"`
let DS=${NOWF}-${NOWS}
echo "checkpoint finish @ ${DATEF} s=${NOWF}  ds=${DS}"
echo " "

OUTDIR=/pnfs/annie/persistent/users/moflaher/wcsimana
echo "copying the output files to ${OUTDIR}"

# copy back the output files
DATESTRING=$(date)      # contains a bunch of spaces, dont use in filenames
for file in *; do
        echo "copying ${file} to ${OUTDIR}"
        ifdh cp -D ${file} ${OUTDIR}
        if [ $? -ne 0 ]; then echo "something went wrong with the copy?!"; fi
done

# clean things up
rm -rf ./*
