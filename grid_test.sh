#!/bin/bash 

export CODE_BASE=/grid/fermiapp/products
#export CODE_BASE=/cvmfs/fermilab.opensciencegrid.org/products
source ${CODE_BASE}/common/etc/setup
export PRODUCTS=${PRODUCTS}:${CODE_BASE}/larsoft

setup geant4 v4_10_1_p02a -q e9:debug:qt
setup cmake     #sets up 2_8_8
setup -f Linux64bit+2.6-2.12 -q debug:e10:nu root v6_06_08

source ${CODE_BASE}/larsoft/root/v6_06_08/Linux64bit+2.6-2.12-e10-nu-debug/bin/thisroot.sh

setup -f Linux64bit+2.6-2.12 -q debug:e10:r6 genie v2_12_0a
setup genie_xsec v2_12_0 -q DefaultPlusMECWithNC
setup genie_phyopt v2_12_0 -q dkcharmtau
setup -f Linux64bit+2.6-2.12 -q debug:e9 clhep v2_2_0_8
setup -f Linux64bit+2.6-2.12 -q debug:e10 xerces_c v3_1_3

export XERCESROOT=${CODE_BASE}/larsoft/xerces_c/v3_1_3/Linux64bit+2.6-2.12-e10-debug
export G4SYSTEM=Linux-g++
export ROOT_PATH=${CODE_BASE}/larsoft/root/v6_06_08/Linux64bit+2.6-2.12-e10-nu-debug/cmake
export GEANT4_PATH=${GEANT4_FQ_DIR}/lib64/Geant4-10.1.2
export GEANT4_MAKEFULL_PATH=${GEANT4_DIR}/${GEANT4_VERSION}/source/geant4.10.01.p02
export NO_GENIE=1

setup fife_utils

# copy the source files
#ifdh cp -D /pnfs/annie/scratch/users/moflaher/wcsim.tar.gz .

# extract and compile the application
#tar zxvf wcsim.tar.gz

# build the application
#mkdir build
#cd build
#cmake ../wcsim
#make

# copy the input files
#ifdh cp -D /pnfs/annie/scratch/users/moflaher/filenums.txt .	# list of input files
#let THECOUNTER=${PROCESS}+1
#THENUM=`less filenums.txt | sed -n ${THECOUNTER},${THECOUNTER}p`
#ifdh cp -D /pnfs/annie/persistent/users/rhatcher/g4dirt/annie_tank_flux.${THENUM}.root .

# make any required modifications using the new input file paths (PWD)
#echo "/mygen/primariesdirectory ${PWD}/annie_tank_flux.*.root" >>  primaries_directory.mac

# run executable
#./WCSim WCSim.mac
echo "Testing if user moflaher can submit jobs to fifebatch production v1_2_3

# rename the output files
#DATESTRING=$(date)

# set the output destination
#out_dir=/pnfs/annie/scratch/users/moflaher/gridout

# copy the output files
#for file in wcsim_*; do
	# generate filename based on this job's input file (or ${PROCESS})
#	out_file=${file}_${DATESTRING}.${THENUM}.root
	# rename the output files
#	mv ${file} ${out_file}
	# copy to the output destination
#	ifdh cp -D ${out_file} ${out_dir}
#done

# clean things up
#cd ..
#rm -rf wcsim
#rm -rf build

