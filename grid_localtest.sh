#!/bin/bash 
#PROCESSOFFSET=600	# use this to offset PROCESS number, if you need to, for some reason...
unset PROCESSOFFSET

echo "setting up software base"
export CODE_BASE=/grid/fermiapp/products
#export CODE_BASE=/cvmfs/fermilab.opensciencegrid.org/products
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
#export LD_LIBRARY_PATH=/annie/app/users/moflaher/wcsim/wcsim:$LD_LIBRARY_PATH
#export ROOT_INCLUDE_PATH=/annie/app/users/moflaher/wcsim/wcsim/include:$ROOT_INCLUDE_PATH


# copy the source files
SOURCEFILEDIR=/pnfs/annie/scratch/users/moflaher
#SOURCEFILEZIP=wcsim.tar.gz
#SOURCEFILEZIP=wcsim_03-05-17.tar.gz
SOURCEFILEZIP=wcsim_17-06-17.tar.gz
echo "searching for source files in ${SOURCEFILEDIR}/${SOURCEFILEZIP}"
echo "ifdh ls ${SOURCEFILEDIR}"
ifdh ls ${SOURCEFILEDIR}
ifdh ls ${SOURCEFILEDIR}/${SOURCEFILEZIP} 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "copying source files"
  cp ${SOURCEFILEDIR}/${SOURCEFILEZIP} .
else 
  echo "source file zip not found in ${SOURCEFILEDIR}!"
fi
if [ ! -f ${SOURCEFILEZIP} ]; then
  echo "could not copy source file zip from ${SOURCEFILEDIR}, trying alternatives"
  for TARLOC in /pnfs/annie/persistent/users/moflaher \
                /annie/app/users/moflaher/wcsim
  do
    echo "try copy from ${TARLOC}"
    cp ${TARLOC}/${SOURCEFILEZIP} .
    if [ ! -f ${SOURCEFILEZIP} ]; then continue; fi
  done
  if [ ! -f ${SOURCEFILEZIP} ]; then
    echo "source file zip not found in any accessible locations!!!"
    exit 11
  fi
fi

# extract and compile the application
echo "unzipping source files"
tar zxvf ${SOURCEFILEZIP}

echo "compiling application"
mkdir build
cd wcsim
make clean
make rootcint
make 
cp src/WCSimRootDict_rdict.pcm ./
cd ../build
cmake ../wcsim
make
rm libWCSimRootDict.rootmap
cp ../wcsim/WCSimRootDict_rdict.pcm ./
if [ ! -x ./WCSim ]; then
    if [ -a ./WCSim ]; then
        chmod +x ./WCSim
        hash -r
    fi
fi
if [ ! -x ./WCSim ]; then
    echo "something failed in compilation?! WCSim not found!"
    exit 12
fi

# copy the list of input files
INPUTFILELISTDIR=/pnfs/annie/scratch/users/moflaher
INPUTFILELISTNAME=filenums.txt
echo "searching for input file list in ${INPUTFILELISTDIR}/${INPUTFILELISTNAME}"
echo "ifdh ls ${INPUTFILELISTDIR}"
ifdh ls ${INPUTFILELISTDIR}
ifdh ls ${INPUTFILELISTDIR}/${INPUTFILELISTNAME} 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "copying input file list"
    cp ${INPUTFILELISTDIR}/${INPUTFILELISTNAME} .   # list of input files
else
    echo "${INPUTFILELISTNAME} not found in ${INPUTFILELISTDIR}! Trying alternatives..."
    for INLISTLOC in /pnfs/annie/persistent/users/moflaher \
                     /annie/app/users/moflaher/wcsim
    do
      echo "try copy from ${INLISTLOC}"
      cp ${INLISTLOC}/${INPUTFILELISTNAME} .
      if [ ! -f ${INPUTFILELISTNAME} ]; then continue; fi
    done
    if [ ! -f ${INPUTFILELISTNAME} ]; then
      echo "input file list not found in any accessible locations!!!"
      exit 13
    fi
fi

# calculate the input file to use
let THECOUNTER=${PROCESS}+${PROCESSOFFSET}+1
THENUM=`less filenums.txt | sed -n ${THECOUNTER},${THECOUNTER}p`
echo "this job has process ${PROCESS}, and will use file num ${THENUM}"

# copy the input files
#DIRTDIR=/pnfs/annie/persistent/users/rhatcher/g4dirt
DIRTDIR=/pnfs/annie/persistent/users/moflaher/g4dirt
DIRTFILE=annie_tank_flux.${THENUM}.root
GENIEDIR=/pnfs/annie/persistent/users/rhatcher/genie
GENIEFILE=gntp.${THENUM}.ghep.root

echo "copying the input files ${DIRTDIR}/${DIRTFILE} and ${GENIEDIR}/${GENIEFILE}"
cp ${DIRTDIR}/${DIRTFILE} .
cp ${GENIEDIR}/${GENIEFILE} .
if [ ! -f ${DIRTFILE} ]; then echo "dirt file not found!!!"; exit 14; fi
if [ ! -f ${GENIEFILE} ]; then echo "genie file not found!!!"; exit 15; fi

echo "writing primaries_directory.mac"
echo "/mygen/neutrinosdirectory ${PWD}/gntp.*.ghep.root" >  macros/primaries_directory.mac
echo "/mygen/primariesdirectory ${PWD}/annie_tank_flux.*.root" >>  macros/primaries_directory.mac
echo "/run/beamOn 10000" >> WCSim.mac   # will end the run as rqd if there are fewer events in the input file

# run executable here, rename the output file
NOWS=`date "+%s"`
DATES=`date "+%Y-%m-%d %H:%M:%S"`
echo "checkpoint start @ ${DATES} s=${NOWS}"
echo " "

./WCSim WCSim.mac

echo " "
NOWF=`date "+%s"`
DATEF=`date "+%Y-%m-%d %H:%M:%S"`
let DS=${NOWF}-${NOWS}
echo "checkpoint finish @ ${DATEF} s=${NOWF}  ds=${DS}"
echo " "

OUTDIR=/pnfs/annie/persistent/users/moflaher/wcsim_tankonly_17-11-17
echo "copying the output files to ${OUTDIR}"

# copy back the output files
DATESTRING=$(date)      # contains a bunch of spaces, dont use in filenames
for file in wcsim_*; do
        tmp=${file%.*}  # strip .root extension
        OUTFILE=${tmp}.${THENUM}.root
        echo "moving ${file} to ${OUTFILE}"
        mv ${file} ${OUTFILE}
        echo "copying ${OUTFILE} to ${OUTDIR}"
        cp ${OUTFILE} ${OUTDIR}
        if [ $? -ne 0 ]; then echo "something went wrong with the copy?!"; fi
done

# clean things up
cd ..
#rm -rf wcsim
#rm -rf build
#rm -rf ${SOURCEFILEZIP}
