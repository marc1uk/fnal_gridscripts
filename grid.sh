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
cd build

# needed for robert's files, not for vincent's files as they are numbered sequentially and continually 
# (at least for tank files. For world files they are not? Either need to make a suitable file of nums... or just let the jobs fail?)
# copy the list of input files
INPUTFILELISTDIR=/pnfs/annie/persistent/users/moflaher
#INPUTFILELISTNAME=filenums_rhatcher.txt
#INPUTFILELISTNAME=jobnumstodo.txt
INPUTFILELISTNAME=lastjob.txt
echo "searching for input file list in ${INPUTFILELISTDIR}/${INPUTFILELISTNAME}"
echo "ifdh ls ${INPUTFILELISTDIR}"
ifdh ls ${INPUTFILELISTDIR}
ifdh ls ${INPUTFILELISTDIR}/${INPUTFILELISTNAME} 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "copying input file list"
    ifdh cp ${INPUTFILELISTDIR}/${INPUTFILELISTNAME} ${PWD}/filenums.txt   # list of input files
else
    echo "${INPUTFILELISTNAME} not found in ${INPUTFILELISTDIR}! Trying alternatives..."
    for INLISTLOC in /pnfs/annie/scratch/users/moflaher \
                     /annie/app/users/moflaher/wcsim
    do
      echo "try copy from ${INLISTLOC}"
      ifdh cp ${INLISTLOC}/${INPUTFILELISTNAME} ${PWD}/filenums.txt
      if [ ! -f ${INPUTFILELISTNAME} ]; then continue; fi
    done
    if [ ! -f ${INPUTFILELISTNAME} ]; then
      echo "input file list not found in any accessible locations!!!"
      exit 13
    fi
fi

# calculate the input file to use
let THECOUNTER=${PROCESS}+${PROCESSOFFSET}+1
#THENUM=`less filenums.txt | sed -n ${THECOUNTER},${THECOUNTER}p` # <<< XXX for robert's file, or use with filenums.txt file.
#let THENUM=${PROCESS}+${PROCESSOFFSET}  # <<< XXX for just assuming consecutive file numbers from 0, or a suitable PROCESSOFFSET.
#echo "this job has process ${PROCESS}, and will use file num ${THENUM}"

JOBNUM=`less filenums.txt | sed -n ${THECOUNTER},${THECOUNTER}p` # pull from list of failed job numbers
echo "this job has process ${PROCESS}, and will use job num ${JOBNUM}"
if [ -z "${JOBNUM}" ]; then echo "read beyond end of input files list"; exit 13; fi
let PROCESSNUM=${JOBNUM}
#let PROCESSNUM=${PROCESS} # not sure if necessary, but to numerically manipulate PROCESS it must be set with 'let' not 'set'.
let SPLITFACTOR=10
let THENUM=$((${PROCESSNUM}/${SPLITFACTOR}))   # because this division is integer, this rounds DOWN (29->2)
let INFILE_OFFSETFACTOR=$((${PROCESSNUM}-(${SPLITFACTOR}*${THENUM}))) # this extracts the difference
let INFILE_OFFSET=$((${INFILE_OFFSETFACTOR}*1000))
echo "this is job PROCESSNUM=${PROCESSNUM}, will process file THENUM=${THENUM}, with offset INFILE_OFFSET=${INFILE_OFFSET}"
echo "the results will be output to OUTFILE=wcsim_0.${THENUM}.${INFILE_OFFSETFACTOR}.root"
# e.g. PROCESSNUM=122 -> THENUM=12; INFILE_OFFSETFACTOR=(122-(10*12))=2; -> INFILE_OFFSET=2000 :: process 122 uses file 12, offset 2000

#OUTDIR=/pnfs/annie/persistent/users/moflaher/wcsim_wdirt_17-06-17
#OUTDIR=/pnfs/annie/persistent/users/moflaher/wcsim_tankonly_03-05-17_BNB_World_10k_29-06-17
OUTDIR=/pnfs/annie/persistent/users/moflaher/wcsim_lappd_24-09-17_BNB_Water_10k_22-05-17
#OUTDIR=/pnfs/annie/persistent/users/moflaher/wcsim_tankonly_muonsonly_03-05-17_rhatcher

# Skip job if output file already exists
OUTFILECHECK=wcsim_0.${THENUM}.${INFILE_OFFSETFACTOR}.root
echo "checking if output file already exists"
if [ -f ${OUTFILECHECK} ]; then
    echo "input file already exists, skipping this job"
    exit 0
fi
# TODO: add something to create a new temp outdir based on job num and run the job anyway? 

# copy the source files
cd .. # exit from build dir
SOURCEFILEDIR=/pnfs/annie/persistent/users/moflaher
#SOURCEFILEZIP=wcsim.tar.gz
#SOURCEFILEZIP=wcsim_tankonly_03-05-17.tar.gz
SOURCEFILEZIP=wcsim_lappd_24-09-17.tar.gz
#SOURCEFILEZIP=wcsim_03-05-17_tankonly_muonsonly.tar.gz
#SOURCEFILEZIP=wcsim_17-06-17.tar.gz
#SOURCEFILEZIP=wcsim_wdirt_17-06-17.tar.gz
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
#if [ ! -f ${SOURCEFILEZIP} ]; then
#  echo "could not copy source file zip from ${SOURCEFILEDIR}, trying alternatives"
#  for TARLOC in /pnfs/annie/scratch/users/moflaher \
#                /annie/app/users/moflaher/wcsim
#  do
#    echo "try copy from ${TARLOC}"
#    ifdh cp -D ${TARLOC}/${SOURCEFILEZIP} .
#    if [ ! -f ${SOURCEFILEZIP} ]; then continue; fi
#  done
#  if [ ! -f ${SOURCEFILEZIP} ]; then
#    echo "source file zip not found in any accessible locations!!!"
#    exit 11
#  fi
#fi

# copy the input files
cd build # back into build dir
#DIRTDIR=/pnfs/annie/persistent/users/rhatcher/g4dirt
#DIRTDIR=/pnfs/annie/persistent/users/moflaher/g4dirt_rhatcher
#DIRTDIR=/pnfs/annie/persistent/users/moflaher/g4dirt_vincentsgenie/world
DIRTDIR=/pnfs/annie/persistent/users/moflaher/g4dirt_vincentsgenie/tank
DIRTFILE=annie_tank_flux.${THENUM}.root
#GENIEDIR=/pnfs/annie/persistent/users/rhatcher/genie
#GENIEDIR=/pnfs/annie/persistent/users/vfischer/genie/BNB_World_10k_29-06-17
GENIEDIR=/pnfs/annie/persistent/users/vfischer/genie/BNB_Water_10k_22-05-17
GENIEFILE=gntp.${THENUM}.ghep.root

echo "copying the input files ${DIRTDIR}/${DIRTFILE} and ${GENIEDIR}/${GENIEFILE}"
ifdh cp -D ${DIRTDIR}/${DIRTFILE} .
ifdh cp -D ${GENIEDIR}/${GENIEFILE} .
if [ ! -f ${DIRTFILE} ]; then echo "dirt file not found!!!"; exit 14; fi
if [ ! -f ${GENIEFILE} ]; then echo "genie file not found!!!"; exit 15; fi


# extract and compile the application
cd .. ## added to move out of build
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
cp ../wcsim/PHASE2_INNER_STRUCTURE.gdml ./
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
        OUTFILE=${tmp}.${THENUM}.${INFILE_OFFSETFACTOR}.root
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
