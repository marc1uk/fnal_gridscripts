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

# setup products
# ==============
echo "setting up software base"
#export CODE_BASE=/grid/fermiapp/products
export CODE_BASE=/cvmfs/fermilab.opensciencegrid.org/products
source ${CODE_BASE}/common/etc/setup
export PRODUCTS=${PRODUCTS}:${CODE_BASE}/larsoft

setup geant4 v4_10_1_p02a -q e9:debug:qt

# new genie
setup genie v2_12_0a -q debug:e10:r6
setup genie_xsec v2_12_0 -q DefaultPlusMECWithNC
setup genie_phyopt v2_12_0 -q dkcharmtau
setup -q debug:e10 xerces_c v3_1_3

#old genie - can't be used
#setup genie v2_8_6d -q e9:debug
#setup genie_xsec v2_8_6 -q default
#setup genie_phyopt v2_8_6 -q dkcharmtau
#setup -f Linux64bit+2.6-2.12 -q debug:e10 xerces_c v3_1_3

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
export LD_LIBRARY_PATH=${PWD}/wcsim:$LD_LIBRARY_PATH
export ROOT_INCLUDE_PATH=${PWD}/wcsim/include:$ROOT_INCLUDE_PATH

# copy the source files
# =====================
SOURCEFILEDIR=/pnfs/annie/persistent/users/moflaher/wcsim/multipmt/tankonly
SOURCEFILEZIP=wcsim_multipmt_tankonly_17-06-17.tar.gz
echo "searching for source files in ${SOURCEFILEDIR}/${SOURCEFILEZIP}"
echo "ifdh ls ${SOURCEFILEDIR}"
ifdh ls ${SOURCEFILEDIR}
ifdh ls ${SOURCEFILEDIR}/${SOURCEFILEZIP} 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "copying source files"
  ifdh cp -D ${SOURCEFILEDIR}/${SOURCEFILEZIP} .
else 
  echo "source file zip not found in ${SOURCEFILEDIR}!"
  exit 11
fi


# copy the script files
# =====================
SCRIPTDIR="/pnfs/annie/persistent/users/moflaher/root_work"
#SCRIPTFILEZIP="truth_ana_scripts_24-04-18.tar.gz" # XXX needs to have #included files and caller too, not just plottruthmrdtracks!!
SCRIPTFILEZIP="truth_ana_scripts_03-06-18.tar.gz"
ifdh ls ${SCRIPTDIR}/${SCRIPTFILEZIP} 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "copying the input file ${SCRIPTFILEZIP}"
    ifdh cp -D ${SCRIPTDIR}/${SCRIPTFILEZIP} .
else 
    echo "script file zip not found in ${SCRIPTDIR}!"
fi
if [ ! -f "${SCRIPTFILEZIP}" ]; then echo "${SCRIPTFILEZIP} copy failed!!!"; exit 16; fi

# export input directories
# =========================
export WCSIMDIR=/pnfs/annie/persistent/users/moflaher/wcsim/multipmt/tankonly/wcsim_multipmt_tankonly_17-06-17_rhatcher
export DIRTDIR=/pnfs/annie/persistent/users/moflaher/g4dirt_rhatcher
#export DIRTDIR=/pnfs/annie/persistent/users/moflaher/g4dirt_vincentsgenie/world
#export DIRTDIR=/pnfs/annie/persistent/users/moflaher/g4dirt_vincentsgenie/tank
export GENIEDIR=/pnfs/annie/persistent/users/rhatcher/genie
#export GENIEDIR=/pnfs/annie/persistent/users/vfischer/genie_files/BNB_World_10k_29-06-17
#export GENIEDIR=/pnfs/annie/persistent/users/vfischer/genie_files/BNB_Water_10k_22-05-17

OUTDIR=${WCSIMDIR}_truthana

# calculate the input file numbers
#=========================================
# v1: extract filename from a list of files
# -----------------------------------------
# for robert's files or vincent's tank files, as they are not numbered sequentially and continually 
# we need to make a list of the file numbers present
# (For vincent's world files there are only a few missing - we could just let the jobs fail)
# copy the list of input files
#INPUTFILELISTDIR=/pnfs/annie/persistent/users/moflaher
#INPUTFILELISTNAME=filenums_rhatcher.txt
#echo "searching for input file list in ${INPUTFILELISTDIR}/${INPUTFILELISTNAME}"
#echo "ifdh ls ${INPUTFILELISTDIR}"
#ifdh ls ${INPUTFILELISTDIR}
#ifdh ls ${INPUTFILELISTDIR}/${INPUTFILELISTNAME} 1>/dev/null 2>&1
#if [ $? -eq 0 ]; then
#    echo "copying input file list"
#    ifdh cp ${INPUTFILELISTDIR}/${INPUTFILELISTNAME} ${PWD}/filenums.txt   # list of input files
#fi
#    if [ ! -f ${INPUTFILELISTNAME} ]; then
#      echo "input file list not found in any accessible locations!!!"
#      exit 13
#    fi
#fi

## calculate the input file to use
#let THECOUNTER=${PROCESS}+${PROCESSOFFSET}+1
##THENUM=`less filenums.txt | sed -n ${THECOUNTER},${THECOUNTER}p` # <<< for robert's file, or use with filenums.txt file.
#let THENUM=${PROCESS}+${PROCESSOFFSET}  # <<< for just assuming consecutive file numbers from 0, or a suitable PROCESSOFFSET.
#echo "this job has process ${PROCESS}, and will use file num ${THENUM}"
#OUTFILEEXAMPLE=trueQEvertexinfo.${THENUM}.root
#echo "the results will be output to OUTFILEEXAMPLE=${OUTFILEEXAMPLE}"

# v2: use process number, but with 10 output files per input file
# ---------------------------------------------------------------
# for vincent's tank files, the file numbers are continuous but the WCSim files are split due to high porcessing time. Use 10 jobs per WCSim file, with a different start offset for each job.
#let PROCESSNUM=${PROCESS}+${PROCESSOFFSET} # not sure if necessary, but to numerically manipulate PROCESS it must be set with 'let' not 'set'.
#let SPLITFACTOR=10
#let THENUM=$((${PROCESSNUM}/${SPLITFACTOR}))   # because this division is integer, this rounds DOWN (29->2)
#let INFILE_OFFSETFACTOR=$((${PROCESSNUM}-(${SPLITFACTOR}*${THENUM}))) # this extracts the difference
#let INFILE_OFFSET=$((${INFILE_OFFSETFACTOR}*1000))
#export INFILE_OFFSET=${INFILE_OFFSET}
#echo "this is job PROCESSNUM=${PROCESSNUM}, will process file THENUM=${THENUM}, with offset INFILE_OFFSET=${INFILE_OFFSET}"
## e.g. PROCESSNUM=122 -> THENUM=12; INFILE_OFFSETFACTOR=(122-(10*12))=2; -> INFILE_OFFSET=2000 :: process 122 uses file 12, offset 2000
#OUTFILEEXAMPLE=trueQEvertexinfo.${THENUM}.${INFILE_OFFSETFACTOR}.root
#echo "the results will be output to OUTFILEEXAMPLE=${OUTFILEEXAMPLE}"

# v3: sam
# -----------------------------------------

# calculate the input file names
# ==============================
# genie files are named: gntp.YYYY.ghep.root for YYY = 1000 to 2999 for robert, 0 to 3999 for vincent,
# but not all are present for robert (only 1250 files!) while only 3 files missing for vincent
export GENIEFILE=gntp.${THENUM}.ghep.root

# dirt files are named: annie_tank_flux.YYY.root for YYY as per genie files
export DIRTFILE=annie_tank_flux.${THENUM}.root

# wcsim files are named: wcsim.YYY.root for YYY as in dirt files,
# or for vincent's tank files: wcsim.YYY.ZZZ.root for YYY = dirt numbers / 10, ZZZ=0 to 9.
export WCSIMFILE="wcsim_0.${THENUM}.root"
#export WCSIMFILE="wcsim_0.${THENUM}.${INFILE_OFFSETFACTOR}.root"
#for i in `seq 0 9`; do export WCSIMFILE="$WCSIMFILE wcsim_0.${THENUM}.${i}.root"; done 

# wcsim lappd files are similar:
export WCSIMLAPPDFILE="wcsim_lappd_0.${THENUM}.root"
#export WCSIMLAPPDFILE="wcsim_lappd_0.${THENUM}.${INFILE_OFFSETFACTOR}.root"

# =====================

# Check if the output files already exist, skip if they do:
ifdh ls ${OUTDIR}/${OUTFILEEXAMPLE} 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "output file already exists! Skipping this job!"
    exit 22;
fi

# copy the input files
# =====================
mkdir root_work
cd root_work

echo "copying the input files ${DIRTDIR}/${DIRTFILE}, ${GENIEDIR}/${GENIEFILE}, ${WCSIMDIR}/${WCSIMFILE} and ${WCSIMDIR}/${WCSIMLAPPDFILE}"
ifdh cp -D ${WCSIMDIR}/${WCSIMFILE} .
ifdh cp -D ${WCSIMDIR}/${WCSIMLAPPDFILE} .
ifdh cp -D ${DIRTDIR}/${DIRTFILE} .
ifdh cp -D ${GENIEDIR}/${GENIEFILE} .
if [ ! -f ${DIRTFILE} ]; then echo "dirt file not found!!!"; exit 14; fi
if [ ! -f ${GENIEFILE} ]; then echo "genie file not found!!!"; exit 15; fi
if [ ! -f ${WCSIMFILE} ]; then echo "wcsim file not found!!!"; exit 15; fi
if [ ! -f ${WCSIMLAPPDFILE} ]; then echo "wcsim lappd file not found!!!"; exit 15; fi
#for i in `seq 0 9`; do SIMFILELIST="${SIMFILELIST} wcsim_0.${THENUM}.${i}.root"; done
#for i in `seq 0 9`; do SIMLAPPDFILELIST="${SIMLAPPDFILELIST} wcsim_lappd_0.${THENUM}.${i}.root"; done
#BADFILE=0
#for SIMFILE in ${SIMFILELIST}; do if [ ! -f "${SIMFILE}" ]; then echo "can't see file ${SIMFILE}"; BADFILE=1; else echo "${SIMFILE} ok"; fi; done
#for SIMLAPPDFILE in ${SIMLAPPDFILELIST}; do if [ ! -f "${SIMLAPPDFILE}" ]; then echo "can't see file ${SIMLAPPDFILE}"; BADFILE=1; else echo "${SIMLAPPDFILE} ok"; fi; done
#if [ ${BADFILE} -eq 1 ]; then echo "wcsim files not found!!!"; exit 16; fi

# extract and compile wcsim
# =========================
echo "unzipping source files"
cd ..
tar zxvf ${SOURCEFILEZIP}

echo "compiling application"
mkdir build
cd wcsim
make clean
make rootcint
make 
cp src/WCSimRootDict_rdict.pcm ./
#cd ../build
#cmake ../wcsim
#make
#rm libWCSimRootDict.rootmap
#cp ../wcsim/WCSimRootDict_rdict.pcm ./
#if [ ! -x ./WCSim ]; then
#    if [ -a ./WCSim ]; then
#        chmod +x ./WCSim
#        hash -r
#    fi
#fi
#if [ ! -x ./WCSim ]; then
#    echo "something failed in compilation?! WCSim not found! Files in current directory:"
#    ifdh ls ${PWD}
#    exit 12
#fi

# extract the truth analysis scripts
# ==================================
echo "unzipping script files"
cd ../root_work
tar zxvf ../${SCRIPTFILEZIP}

mkdir outdir
export LOCALOUTDIR="${PWD}/outdir"

# debug prints before we start
# ============================
NOWS=`date "+%s"`
DATES=`date "+%Y-%m-%d %H:%M:%S"`
echo "checkpoint start @ ${DATES} s=${NOWS}"
echo " "
echo "PWD=${PWD}"
echo "ls -l *"
ls -l *

# do the actual work
# ==================
root -b -q -l $PWD/truthcaller.C
#\(\"${WCSIMDIR}\",\"${DIRTDIR}\",\"${GENIEDIR}\",\"${LOCALOUTDIR}\",\) << these args need to be passed to truthtracks in truthcaller.C

# debug prints after we finish
# ============================
echo " "
NOWF=`date "+%s"`
DATEF=`date "+%Y-%m-%d %H:%M:%S"`
let DS=${NOWF}-${NOWS}
echo "checkpoint finish @ ${DATEF} s=${NOWF}  ds=${DS}"
echo " "
echo "ls -l *"
ls -l *

# copy out the results
# ====================
echo "copying the output files to ${OUTDIR}"
# copy back the output files
DATESTRING=$(date)      # contains a bunch of spaces, dont use in filenames
for file in `ls ${LOCALOUTDIR}`; do
        tmp=${file%.*}  # strip the extension
        #OUTFILE=${tmp}.${THENUM}.${INFILE_OFFSETFACTOR}.root
        OUTFILE=${tmp}.${THENUM}.root
        echo "moving ${LOCALOUTDIR}/${file} to ${LOCALOUTDIR}/${OUTFILE}"
        mv ${LOCALOUTDIR}/${file} ${LOCALOUTDIR}/${OUTFILE}
        echo "copying ${LOCALOUTDIR}/${OUTFILE} to ${OUTDIR}"
        ifdh cp -D ${LOCALOUTDIR}/${OUTFILE} ${OUTDIR}
        if [ $? -ne 0 ]; then echo "something went wrong with the copy?!"; fi
done

# clean up
# ========
cd ..
rm -rf $PWD/wcsim
rm -rf $PWD/build
rm -rf $PWD/root_work
rm -rf $PWD/${SOURCEFILEZIP}
