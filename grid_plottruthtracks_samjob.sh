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

## start of SAM file retrieval
##############################

## setup environmental variables
################################
#export TMPDIR=${PWD}
#export _CONDOR_SCRATCH_DIR=${TMPDIR}
# Note that the 'scratch disk' directory used by ifdh is defined by the environment variable TMPDIR. For interactive use, define this by hand to avoid filling up /var/tmp on the gpvm nodes. "In a batch job, ifdh will use the directory specified by environment variable _CONDOR_SCRATCH_DIR in preference to TMPDIR". Is this the directory used by ifdh fetchInput? Other???
export applicationfamily=simulation
export application=wcsim
export host=`hostname`

## These are passed with submission script
# USER, EXPERIMENT, DATASET_NAME, PROJ_NAME, wcsim_commit
export version=${wcsim_commit}

## find project
###############
PROJ_URL=`ifdh findProject ${PROJ_NAME} ${EXPERIMENT}`
echo "found PROJ_URL is" ${PROJ_URL}
echo "printing samweb project summary"
samweb project-summary ${PROJ_URL}                          # print project info & snapshot
echo "printing ifdh dumpProject"
ifdh dumpProject ${PROJ_URL}
echo "printing ifdh fileset definition for dataset ${DATASET_NAME}"
ifdh describeDefinition ${DATASET_NAME}

## start consumer process
########################
#consumer_id=`ifdh establishProcess ${PROJ_URL} ${application} ${version} ${host} ${USER} "" "" "" `
# alternatively
consumer_id=`samweb start-process --appfamily=${applicationfamily} --appname=${application} --appversion=${version} $PROJ_URL`
#app family, name, version are arbitrary. Used for???
echo "consumer process id =" ${consumer_id}

## obtain file to process
########################
fileuri=`ifdh getNextFile $PROJ_URL $consumer_id`
# alternatively
#fileuri=`samweb get-next-file $PROJ_URL $consumer_id`
# The getNextFile interface can return http status code 204, which means no more files are available for this consumer, or it can return status code 202, which means there are no files currently available but it is trying to obtain more (the body text in this case returns a descriptive text string followed by a colon followed by the suggested number of seconds before the client should query again). Finally, getNextFile can return status 200 and a response, the first line of which is the access URL for a file.
echo "getNextFile returned fileuri =" ${fileuri}
echo "_CONDOR_SCRATCH_DIR =" ${_CONDOR_SCRATCH_DIR}
echo "TMP =" ${TMP}
echo "PWD =" ${PWD}

## fetch the file to _CONDOR_SCRATCH_DIR? Is that automatically set? Can we process it there?
if [ "$fileuri"  != "" ] ; then
	fname=`ifdh fetchInput $fileuri | tail -1 `
	echo "fname =" ${fname}
	if [ "${fname}" != "" ] ; then
		ifdh updateFileStatus $PROJ_URL  $consumer_id $fname transferred
		
		## make a link to the file in the PWD, so the script can find it
		export filename = $(basename fname)
		if [ ! -r ${PWD}/${filename} ] ; then
			ln -s fname filename
			echo "made symbolic link to file in PWD"
		fi
		ls -l
		
		## extract the file number from the filename
		THENUM=$(echo ${filename} | grep -o -E [0-9\.]+)    # extract numbers
		THENUM=${THENUM%.}                           # trim trailing .
		THENUM=echo ${THENUM/./}                     # combine nums if split
	else
		## filename is empty??
		echo "ifdh getNextFile returned non-empty file uri, but fetchInput filename is empty?"
		ifdh updateFileStatus $PROJ_URL  $consumer_id $fname skipped   # is this meaningful?
		ifdh setStatus $PROJ_URL $consumer_id bad                      # set process as bad...
		ifdh endProcess $PROJ_URL $consumer_id                         # end the process
		# alternatively
		#samweb stop-process $PROJ_URL $consumer_id
		exit 1
	fi
else
	## no more files to process
	echo "no more files in project. Exiting."
	ifdh setStatus $PROJ_URL $consumer_id ok
	ifdh endProcess $PROJ_URL $consumer_id
	# alternatively
	#samweb stop-process $PROJ_URL $consumer_id
#	ifdh endProject $PROJ_URL     ## XXX XXX XXX disable, do this manually?
	# alternatively
	#samweb stop-project $PROJ_NAME
	## nothing done by this job, we can just exit
	exit 0
fi

## end of SAM file retrieval
############################

# calculate the input file names
# ==============================

## TODO: replace use of 'THENUM' with Sam parentage information

# genie files are named: gntp.YYYY.ghep.root for YYY = 1000 to 2999 for robert, 0 to 3999 for vincent,
# but not all are present for robert (only 1250 files!) while only 3 files missing for vincent
export GENIEFILE=gntp.${THENUM}.ghep.root

# dirt files are named: annie_tank_flux.YYY.root for YYY as per genie files
export DIRTFILE=annie_tank_flux.${THENUM}.root

# wcsim files are named: wcsim.YYY.root for YYY as in dirt files,
# or for vincent's tank files: wcsim.YYY.ZZZ.root for YYY = dirt numbers / 10, ZZZ=0 to 9.
export WCSIMFILE=${fname}
#export WCSIMFILE="wcsim_0.${THENUM}.root"
#export WCSIMFILE="wcsim_0.${THENUM}.${INFILE_OFFSETFACTOR}.root"
#for i in `seq 0 9`; do export WCSIMFILE="$WCSIMFILE wcsim_0.${THENUM}.${i}.root"; done 

# wcsim lappd files are similar:
export WCSIMLAPPDFILE="${WCSIMFILE/wcsim_/wcsim_lappd_}"
#export WCSIMLAPPDFILE="wcsim_lappd_0.${THENUM}.root"
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
if [ ! -f ${WCSIMFILE} ]; then ifdh cp -D ${WCSIMDIR}/${WCSIMFILE} . ; fi  ## should be provided by SAM
ifdh cp -D ${WCSIMDIR}/${WCSIMLAPPDFILE} .
ifdh cp -D ${DIRTDIR}/${DIRTFILE} .
ifdh cp -D ${GENIEDIR}/${GENIEFILE} .
if [ ! -r ${DIRTFILE} ]; then echo "dirt file not found!!!"; exit 14; fi
if [ ! -r ${GENIEFILE} ]; then echo "genie file not found!!!"; exit 15; fi
if [ ! -r ${WCSIMFILE} ]; then echo "wcsim file not found!!!"; exit 15; fi
if [ ! -r ${WCSIMLAPPDFILE} ]; then echo "wcsim lappd file not found!!!"; exit 15; fi
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
job_success=$?
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
        echo "moving ${LOCALOUTDIR}/${file} to ${OUTDIR}/${OUTFILE}"
        ifdh cp -D ${LOCALOUTDIR}/${file} ${OUTDIR}/${OUTFILE}
        if [ $? -ne 0 ]; then echo "something went wrong with the copy?!"; fi
        # alternatively ... *
        #ifdh addOutput ${LOCALOUTDIR}/${file} 
done
# * ... copy whole set of files at once
#ifdh copyBackOutput ${OUTDIR}

## sam finalization
##############################
if [ job_success ] ; then
	ifdh updateFileStatus $PROJ_URL  $consumer_id $fname consumed
	# alternatively
	#samweb release-file $PROJ_URL $consumer_id `basename $fileuri` --status=consumed
	ifdh setStatus $PROJ_URL $consumer_id ok   # process status
	# alternatively
	#samweb set-process-status [command options] $PROJ_URL $consumer_id
else
	ifdh updateFileStatus $PROJ_URL  $consumer_id $fname skipped
	## file statuses may only be 'transferred', 'consumed' or 'skipped'
	# alternatively
	#samweb release-file $PROJ_URL $consumer_id `basename $fileuri` --status=skipped
	ifdh setStatus $PROJ_URL $consumer_id bad   # process status
fi
ifdh endProcess $PROJ_URL $consumer_id
# alternatively
#samweb stop-process $PROJ_URL $consumer_id

# Processes:
# When the job has completely finished processing, including tasks such as returning the output to the user, the /setStatus interface may be used to mark it as 'complete' (for recovery purposes).
# It's a good idea to report process status as "ok" or "bad" before exiting, otherwise the system will time out and declare the process as bad, which factors into recovery datasets. By reporting success or failure, that status can be used to make a recovery dataset if needed.
# Processes that have delivered all the available files are automatically marked as finished, but if desired the /endProcess interface may be used to explicitly end a process.

# Files:
# When the job has completed processing each file it must call the /releaseFile interface with the filename and the status of the file. A status of 'ok' will mark the file as successfully processed. Any other status will mark it as unsuccessful.

# Projects:
# Once all consumer processes have completed, then the /endProject interface should be used to terminate the project. After this is done the project is no longer usable.

## cleanup
cd ..
rm -rf ${PWD}/wcsim
rm -rf ${PWD}/build
rm -rf ${PWD}/root_work
rm -rf ${PWD}/${SOURCEFILEZIP}

## get rid of cached certificates, files pulled in with fetchInput, etc.
ifdh cleanup

