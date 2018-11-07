#!/bin/bash 
echo "setting up software base"
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
#export NO_GENIE=1

setup fife_utils

# copy the source files
SOURCEFILEDIR=/pnfs/annie/scratch/users/moflaher
SOURCEFILEZIP=wcsim.tar.gz
echo "searching for source files in ${SOURCEFILEDIR}/${SOURCEFILEZIP}"
echo "ls -l ${SOURCEFILEDIR}"
ls -l ${SOURCEFILEDIR}
if [ -f ${SOURCEFILEDIR}/${SOURCEFILEZIP} ]; then
    echo "copying source files"
    ifdh cp -D ${SOURCEFILEDIR}/${SOURCEFILEZIP} .
else
    echo "source file zip not found!!!"
    exit 127
fi

# extract and compile the application
echo "unzipping source files"
tar zxvf ${SOURCEFILEZIP}

echo "compiling application"
mkdir build
cd wcsim
make rootcint
make 
cp src/WCSimRootDict_rdict.pcm ./
cd ../build
cmake ../wcsim
make
rm libWCSimRootDict.rootmap
if [ ! -x ./WCSim ]; then
    if [ -a ./WCSim ]; then
        chmod +x ./WCSim
        hash -r
    fi
fi
if [ ! -x ./WCSim ]; then
    echo "something failed in compilation?! WCSim not found!"
    exit 128
fi

# copy the list of input files
INPUTFILELISTDIR=/pnfs/annie/scratch/users/moflaher
INPUTFILELISTNAME=filenums.txt
echo "copying list of input files"
echo "ls ${INPUTFILELISTDIR}"
ls ${INPUTFILELISTDIR}
ifdh cp -D ${INPUTFILELISTDIR}/${INPUTFILELISTNAME} .	# list of input files
if [ ! -f ${INPUTFILELISTNAME} ]; then
    echo "input file list not found!!!"
    exit 129
fi

# calculate the input file to use
let THECOUNTER=${PROCESS}+1
THENUM=`less filenums.txt | sed -n ${THECOUNTER},${THECOUNTER}p`
echo "this job has process ${PROCESS}, and will use file num ${THENUM}"

# copy the input files
#DIRTDIR=/pnfs/annie/persistent/users/rhatcher/g4dirt
DIRTDIR=/pnfs/annie/persistent/users/moflaher/g4dirt
DIRTFILE=annie_tank_flux.${THENUM}.root
GENIEDIR=/pnfs/annie/persistent/users/rhatcher/genie
GENIEFILE=gntp.${THENUM}.ghep.root

echo "copying the input files ${DIRTDIR}/${DIRTFILE} and ${GENIEDIR}/${GENIEFILE}"
ifdh cp -D ${DIRTDIR}/${DIRTFILE} .
ifdh cp -D ${GENIEDIR}/${GENIEFILE} .
if [ ! -f ${DIRTFILE} ]; then echo "dirt file not found!!!"; exit 120; fi
if [ ! -f ${GENIEFILE} ]; then echo "genie file not found!!!"; fi	#dont break, dont need

#echo "writing primaries_directory.mac"
echo "/mygen/neutrinosdirectory ${PWD}/gntp.*.ghep.root" >  primaries_directory.mac
echo "/mygen/primariesdirectory ${PWD}/annie_tank_flux.*.root" >>  primaries_directory.mac
echo "/run/beamOn 10000" >> WCSim.mac	# will end the run as rqd if there are fewer events in the input file

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

out_dir=/pnfs/annie/scratch/users/moflaher/gridout
echo "copying the output files to ${out_dir}"

# copy back the output files
DATESTRING=$(date)	# contains a bunch of spaces, dont use in filenames
for file in wcsim_*; do
	tmp=${file%.*}	# strip .root extension
	out_file=${tmp}.${THENUM}.root
	echo "moving ${file} to ${out_file}"
	mv ${file} ${out_file}
	echo "copying ${out_file}"
	ifdh cp -D ${out_file} ${out_dir}
	if [ ! -f ${out_dir}/${out_file} ]; then echo "something went wrong with the copy?!"; fi
done

# clean things up
cd ..
rm -rf wcsim
rm -rf build
rm -rf ${SOURCEFILEZIP}
