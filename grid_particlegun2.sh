#!/bin/bash 
# BEFORE RUNNING:
# 1. Set source file for wcsim
# 2. Set or disable input file list (see below)
# 3. Set dirt, genie and output directories
# FILE NUMBERING: (VINCENT vs ROB'S GENIE FILES, or using/skipping the list of file numbers):
# disable or set the process offset to the first file number
# change the THENUM to just PROCESS+PROCESSOFFSET and disable the sed section
#PROCESSOFFSET=4000	# XXX use this to offset PROCESS number, OR SET TO ZERO OTHERWISE - IT MUST BE SET
PROCESSOFFSET=0

SOURCEFILEDIR=/pnfs/annie/persistent/users/moflaher/wcsim/wcsim_sourcefiles
OUTDIR=/pnfs/annie/persistent/users/moflaher/wcsim/multipmt/tankonly/wcsim_ANNIEp2v4_tankonly_13-08-18_muonswarm/
SOURCEFILEZIP=wcsim_13-08-18_ANNIEp2v4_tankonly.tar.gz
MACROFILE=WCSim_muonswarm.mac

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
  #setup dk2nu v01_03_00c -q debug:e9:r5  ## disable??
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

mkdir build

let THENUM=${PROCESS}+${PROCESSOFFSET}

# Skip job if output file already exists
OUTFILECHECK=wcsim_0.${THENUM}.root
echo "checking if output file already exists"
ifdh ls ${OUTDIR}/${OUTFILECHECK} 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "input file already exists, skipping this job"
    exit 0
fi
# TODO: add something to create a new temp outdir based on job num and run the job anyway? 

# copy the source files
echo "searching for source files in ${SOURCEFILEDIR}/${SOURCEFILEZIP}"
echo "ifdh ls ${SOURCEFILEDIR}"
ifdh ls ${SOURCEFILEDIR}
ifdh ls ${SOURCEFILEDIR}/${SOURCEFILEZIP} 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "copying source files"
  ifdh cp -D ${SOURCEFILEDIR}/${SOURCEFILEZIP} .
else 
  echo "source file zip not found in ${SOURCEFILEDIR}!"
fi

# extract and compile the application
echo "unzipping source files"
tar zxvf ${SOURCEFILEZIP}
echo "sourcing neutron related hadronic environmental variables"
source wcsim/envHadronic.sh

echo "compiling application"
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
    echo "something failed in compilation?! WCSim not found! Files in current directory:"
    ifdh ls ${PWD}
    exit 12
fi

echo "writing primaries_directory.mac"
echo "/mygen/neutrinosdirectory ${PWD}/gntp.*.ghep.root" >  macros/primaries_directory.mac
echo "/mygen/primariesdirectory ${PWD}/annie_tank_flux.*.root" >>  macros/primaries_directory.mac
echo "/mygen/primariesoffset ${INFILE_OFFSET}" >> macros/primaries_directory.mac
# backwards compatibilty with old branches, which don't use the macros folder
echo "/mygen/neutrinosdirectory ${PWD}/gntp.*.ghep.root" >  primaries_directory.mac
echo "/mygen/primariesdirectory ${PWD}/annie_tank_flux.*.root" >>  primaries_directory.mac
echo "/mygen/primariesoffset ${INFILE_OFFSET}" >> primaries_directory.mac

# copy over WCSim.mac with suitable particle gun source enabled
rm WCSim.mac
echo "copying macro file ${SOURCEFILEDIR}/${MACROFILE}"
ifdh ls ${SOURCEFILEDIR}/${MACROFILE} 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "macro file found, copying"
  ifdh cp ${SOURCEFILEDIR}/${MACROFILE} WCSim.mac
else 
  echo "macro file not found!"
fi
echo "/run/beamOn 1000" >> WCSim.mac   # will end the run as rqd if there are fewer events in the input file

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

# TODO: if the output file exists, this will fail, and we'll lose the results.
# it might be worth checking if the output file exists, and if it does, creating a new directory
# based on the job name and saving the file there... 
echo "copying the output files to ${OUTDIR}"
# copy back the output files
DATESTRING=$(date)      # contains a bunch of spaces, dont use in filenames
for file in wcsim_*; do
        tmp=${file%.*}  # strip .root extension
        OUTFILE=${tmp}.${THENUM}.root
        echo "renaming ${file} to ${OUTFILE}"
        mv ${file} ${OUTFILE}
        echo "copying ${OUTFILE} to ${OUTDIR}"
        ifdh cp -D ${OUTFILE} ${OUTDIR}
        if [ $? -ne 0 ]; then echo "something went wrong with the copy?!"; fi
done

# clean things up
cd ..
rm -rf wcsim
rm -rf build
rm -rf ${SOURCEFILEZIP}
