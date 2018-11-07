#!/bin/sh

VERSION=20160613

FUNC=${1}
SECS=${2}
THDS=${3}

if  [ "${FUNC}" == "help" -o  "${FUNC}" == "-h" ] ; then
    printf "\n"
    printf "###############\n"
    printf "#  PROBE HELP #\n"
    printf "###############\n"
    printf "\n"

    printf " The probe script shows the running environment, \n"
    printf " and performs optional functions:     \n\n"
    printf "    memory GBytes ( consume memory )\n"
    printf "    disk   GBytes ( consume \${TMPDIR} disk ) \n"
    printf "    fuzz   seconds ( sleep secs * 4{PROCESS} )\n"
    printf "    sleep  seconds \n"
    printf "    burn   seconds \n"
    printf "    copy   infile outfile ( using ifdh cp )\n"
    printf "    error  integer, exit with this error\n"
    printf "    env            print the environment\n"
    printf "    killme         kill parent process\n"
    printf "\n"
    printf " Multiple functions are supported in a single call\n"
    printf "\n"
    printf " Examples :\n"
    printf "     probe \n"
    printf "     probe sleep 3\n"
    printf "     probe copy /pnfs/minos/beam_data/2004-12/B041203_162739.mbeam.root ${TMPDIR}/test.dat\n"
    printf "     probe memory=1000,disk=38,sleep=600\n"

    printf "\n"

    exit 0
fi

    

printf "##################################################\n"
printf "#  CHECKING TO SEE WHERE WE ARE AND WHAT WE HAVE #\n"
printf "##################################################\n"

printf "\n"
printf "PROBE    VERSION ${VERSION} run at `date`\n"
printf "FUNC     ${FUNC}\n"
printf "SECS     ${SECS}\n"
printf "THDS     ${THDS}\n"
if [ -n "${SECS}" ] ; then
    FUNCS="${FUNC}=${SECS}=${THDS}\n"
else
    FUNCS=`echo ${FUNC} | tr , \\\n`\\\n
fi
printf "FUNCS\n${FUNCS}\n"

printf "\n"
printf "JOBSUBJOBSECTION  ${JOBSBJOBSECTION}\n"
printf "CLUSTER  ${CLUSTER}\n"
printf "PROCESS  ${PROCESS}\n"

printf "\n"
printf "HOSTNAME " ; hostname
printf "PWD      " ; pwd
printf "WHOAMI   " ; whoami
printf "ID       " ; id
printf "REDHAT   " ; cat /etc/redhat-release
printf "LSB_RELEASE\n" ; lsb_release | tr : \\\n
printf "UNAME    " ; uname  -a
printf "ULIMIT\n"  ; ulimit -a
printf "CORELIMIT "  ; ulimit -c -H

echo
echo PATH  
echo ${PATH} | tr : \\\n

echo
echo SHELL ${SHELL}

echo
echo "HOME " ${HOME}
echo "tilde" ~
df  -h ${HOME}

echo
quota -s
if [ -n "${X509_USER_PROXY}" ] ; then
    printf "PROXY    ${X509_USER_PROXY}\n"
    voms-proxy-info | grep identity
fi

echo
printf "UMASK "
umask

printf "\n"
printf "##########\n"
printf "# CONDOR #\n"
printf "##########\n"
printf "\n"

env | grep CONDOR_JOB_IWD
env | grep CONDOR_SCRATCH_DIR
if [ -n "${_CONDOR_JOB_AD}" ]  ; then 
    EXLIFE=`grep ^JOB_EXPECTED_MAX_LIFETIME ${_CONDOR_JOB_AD} | cut -f 2 -d = | tr -d ' '`
    printf "JOB_EXPECTED_MAX_LIFETIME ${EXLIFE}\n"
fi

printf "\n"
printf "######\n"
printf "# ps #\n"
printf "######\n"
printf "\n"

ps -H -o pid,ppid,tty,time,cmd --forest

printf "\n"
printf "PPID ${PPID}\n"

printf "\n"
printf "#########\n"
printf "# CVMFS #\n"
printf "#########\n"
printf "\n"

printf "RPM\n"
rpm -qa cvmfs
printf "\n"

if  [ -d "/cvmfs" ] ; then
    printf "HAVE /cvmfs \n"
    if [ -r "/cvmfs/grid.cern.ch/util" ] ; then
        echo HAVE /cvmfs/grid.cern.ch
    else
        echo LACK /cvmfs/grid.cern.ch
    fi

    for DIR in oasis fermilab cdf d0 darkside des gm2 lariat lsst minos mu2e nova seaquest uboone ; do
    if [ -d "/cvmfs/${DIR}.opensciencegrid.org" ] ; then
        echo HAVE /cvmfs/${DIR}.opensciencegrid.org
    else
        echo LACK /cvmfs/${DIR}.opensciencegrid.org
    fi
    done

else
    printf "LACK /cvmfs \n"
fi

printf "\n"
printf "##################\n"
printf "# SETTING UP UPS #\n"
printf "##################\n"
printf "\n"

unset SETUP_UPS
unset UPS_DIR

if   [ -r "/grid/fermiapp/products/common/etc/setups.sh" ] ; then . /grid/fermiapp/products/common/etc/setups.sh
elif [ -r "/fnal/ups/etc/setups.sh"  ] ; then . /fnal/ups/etc/setups.sh
elif [ -r "/usr/local/etc/setups.sh" ] ; then . /usr/local/etc/setups.sh
elif [ -r "/cvmfs/fermilab.opensciencegrid.org/products/common/etc/setups.sh" ] ; then . /cvmfs/fermilab.opensciencegrid.org/products/common/etc/setups.sh
fi

type setup

printf "\n"
printf "##################\n"
printf "# /grid/fermiapp #\n"
printf "##################\n"
printf "\n"

[ -r "/grid/fermiapp" ] && printf " OK - have /grid/fermiapp \n"

printf "\n"
printf "###################\n"
printf "# KERBEROS TICKET #\n"
printf "###################\n"
printf "\n"

[ -x "/usr/krb5/bin/klist" ] && /usr/krb5/bin/klist -f 2>&1
printf "\n"

printf "\n"
printf "################################\n"
printf "#   CHECK THE GRID ENVIRONMENT #\n"
printf "################################\n"
printf "\n"

if [ -n "${OSG_GRID}" -a -r "${OSG_GRID}/setup.sh" ] ; then

    . ${OSG_GRID}/setup.sh

    printf "OSG_GRID   ^${OSG_GRID}^\n"
    printf "OSG_DATA   ^${OSG_DATA}^\n"
    printf "OSG_APP    ^${OSG_APP}^\n"
    printf "OSG_WN_TMP ^${OSG_WN_TMP}^\n"
    printf "TMPDIR     ^${TMPDIR}^\n"
    df -h ${TMPDIR}
    printf "\n"

else

    printf " OK - \${OSG_GRID}/setup.sh is not available \n"

fi

#        ENV

FU=env

if  FUNCARG=`printf "${FUNCS}" | grep ^${FU}` ; then
    printf "\n"
    printf "#############################\n"
    printf "#  ENVIRONMENT #\n"
    printf "#############################\n"
    printf "\n"

    env

fi

#        MEMORY

MALLOC() {
    MBALL=${1}
    FREE=$(free -m | grep Mem: | awk '{print int($4+$7)}')
    if [ ${MBALL} -lt ${FREE} ] ; then 

       NINE=123456789
       (( NEND = NINE + ( MBALL * 100000 ) ))
       MEMB=`seq -w ${NINE} ${NEND}`

    else
        printf "Cowardly not mallocing ${MBALL} with ${FREE} free\n\n"
    fi
}

FU=memory

if  FUNCARG=`printf "${FUNCS}" | grep ^${FU}` ; then
    SECS=`echo ${FUNCARG} | cut -f 2 -d =` 
    if  [ ${SECS} -gt 0 ] ; then
    printf "#############################\n"
    printf "#  MALLOCING ${SECS} MBytes #\n"
    printf "#############################\n"
    printf "\n"

    date
    ps l -p $$
    MALLOC ${SECS}
    date
    ps l -p $$
    
fi ; fi

#        DISK

FU=disk

if  FUNCARG=`printf "${FUNCS}" | grep ^${FU}` ; then
    SECS=`echo ${FUNCARG} | cut -f 2 -d =` 
    if [ "${SECS:0:1}" == "+" ] ; then
        SECS=${SECS:1}
	KEEP="keep"
    elif [ "${SECS:0:1}" == "-" ] ; then
        SECS=${SECS:1}
	KEEP="short"
    fi
    if  [ ${SECS} -gt 0 ] ; then
    printf "\n"
    printf "##############################\n"
    printf "#  USING ${SECS} GBytes DISK #\n"
    printf "##############################\n"

    printf "\n"
    date

    if [ -n "${TMPDIR}" ] ; then 

    rm -f ${TMPDIR}/HOG*

    rm -f /dev/shm/probe-*-$$

    dd if=/dev/urandom of=/dev/shm/probe-10M-$$ bs=1000000c count=10 2>/dev/null
    for N in `seq 100` ; do cat /dev/shm/probe-10M-$$ >> /dev/shm/probe-1G-$$ ; done

    for N in `seq ${SECS}` ; do
        dd if=/dev/shm/probe-1G-$$ of=/${TMPDIR}/HOG-${N} bs=10M 2>/dev/null
    done 

    rm -f /dev/shm/probe-*-$$
    
    du -sm ${TMPDIR}/HOG*
    du -sm ${TMPDIR}

    [ "${KEEP}" == "short" ] && echo CLEARING && rm -f ${TMPDIR}/HOG*

    date
 
    else
        printf "\nCowardly not writing to undefined TMPDIR\n\n"
    fi

fi ; fi

#        FUZZ

FU=fuzz

if  FUNCARG=`printf "${FUNCS}" | grep ^${FU}` ; then
    SECS=`echo ${FUNCARG} | cut -f 2 -d =` 
    if  [ ${SECS} -gt 0 ] ; then
    printf "\n"
    printf "#############################\n"
    printf "#  FUZZ ${PROCESS}*${SECS} SECONDS #\n"
    printf "#############################\n"

    (( FSEC = SECS * PROCESS ))
    { time sleep ${FSEC} ; } 2>&1

fi ; fi

#        SLEEP

FU=sleep

if  FUNCARG=`printf "${FUNCS}" | grep ^${FU}` ; then
    SECS=`echo ${FUNCARG} | cut -f 2 -d =` 
    if  [ ${SECS} -gt 0 ] ; then
    printf "\n"
    printf "#############################\n"
    printf "#  SLEEPING ${SECS} SECONDS #\n"
    printf "#############################\n"

    { time sleep ${SECS} ; } 2>&1

fi ; fi

#        BURN

BURN()
{ 
    BSECS=${1}
    ISEC=`date +%s`
     SEC=0
    { while [ ${SEC} -lt ${BSECS} ] ; do
        N=0
        while [ ${N} -lt 50000 ] ; do (( N++)) ; done       
        (( SEC = `date +%s` - ISEC ))
   done ; } 2>&1
}

FU=burn

if  FUNCARG=`printf "${FUNCS}" | grep ^${FU}` ; then
    SECS=`echo ${FUNCARG} | cut -f 2 -d =` 
    if [ ${SECS} -gt 0 ] ; then
    printf "\n"
    printf "####################################\n"
    printf "#  BURNING CPU FOR ${SECS} seconds #\n"
    printf "####################################\n"

    time BURN ${SECS}

fi ; fi


FU=tiny

if  FUNCARG=`printf "${FUNCS}" | grep ^${FU}` ; then
    SECS=`echo ${FUNCARG} | cut -f 2 -d =` 
    if [ ${SECS} -gt 0 ] ; then
    printf "\n"
    printf "####################################\n"
    printf "#  BURNING CPU FOR ${SECS} seconds #\n"
    printf "####################################\n"

    time BURN ${SECS}

fi ; fi

FU=copy

if  FUNCARG=`printf "${FUNCS}" | grep ^${FU}` ; then
    SECS=`echo ${FUNCARG} | cut -f 2 -d =` 
    THDS=`echo ${FUNCARG} | cut -f 3 -d =` 
    if [ -n "${SECS}" -a -n "${THDS}" ] ; then
    printf "\n"
    printf "############\n"
    printf "#  COPYING #\n"
    printf "############\n"
    printf "\n"

    setup ifdhc
    echo ifdh cp ${SECS} ${THDS}
         ifdh cp ${SECS} ${THDS}
    [ -r "${THDS}" ] && ls -l ${THDS} && /bin/rm -I ${THDS}
    printf "\n"

 
fi ; fi


if [ -n "${X509_USER_PROXY}" ] ; then
    printf "##########\n"
    printf "#  PROXY #\n"
    printf "##########\n"
    printf "PROXY    ${X509_USER_PROXY}\n"
    voms-proxy-info -all
fi

#printf " # # # # # environment # # # # # \n"
#env
#printf " # # # # # environment # # # # # \n"

HOGS=`ls ${TMPDIR} | grep HOG`

if [ -n "${HOGS}" ] ; then 
    if   [ "${KEEP}" == "keep" ] ; then 

        printf "\n"
        printf "##################\n"
        printf "#  RETAINED DISK #\n"
        printf "##################\n"
        printf "\n"

    else

        printf "\n"
        printf "###############\n"
        printf "#  CLEAR DISK #\n"
        printf "###############\n"
        printf "\n"

        date
        rm -f ${TMPDIR}/HOG*
        date
    fi
fi

FU=error

if  FUNCARG=`printf "${FUNCS}" | grep ^${FU}` ; then
    SECS=`echo ${FUNCARG} | cut -f 2 -d =` 
    if [ ${SECS} -gt 0 ] ; then
    printf "\n"
    printf "######################\n"
    printf "# RETURNING ERROR ${SECS} #\n"
    printf "######################\n"

    exit ${SECS}

fi ; fi


FU=killme

if  FUNCARG=`printf "${FUNCS}" | grep ^${FU}` ; then
    printf "\n"
    printf "######################\n"
    printf "# KILLING PARENT ${PPID} #\n"
    printf "######################\n"

    kill ${PPID}

fi


printf "\nRUN FINISHED " ; date
printf "\n"
exit

2016 06 13    kreymer
Added LSB_RELEASE

2016 05 02    kreymer

Added env to print the environment
Added CONDOR header, and printout of JOB_EXPECTED_MAX_LIFETIME

2016 03 20    kreymer

Added killme option
  for inducing sandbox errors on the grid

2016 03 18    kreymer

Added error to help list
Added _CONDOR_JOB_IWD
Corrected help list order

2015 12 16    kreymer

Added cvmfs RPM version

2015 12 11    kreymer

error= sets return code
disk=+value to retain files on disk
disk=-value to quickly remove files
uniform FUNCARG handling

2015 09 26    kreymer

Added fuzz sleeping secs*PROCESS
Cleaned up HOG cleanup

2015 09 19    kreymer

Removed AFS token elements
Replaced tiny with burn
Added JOBSUBJOBSECTION print
Support multiple functions f1=a1=b1,f2=a2,...
   for use with mem, disk hogging

2015 07 11    kreymer

Removed cvmfs oasis loop, added oasis to top level list

2015 07 09    kreymer

Added /cvmfs status

2014 08 01    kreymer

Added copy
Added CONDOR_CLUSTER

