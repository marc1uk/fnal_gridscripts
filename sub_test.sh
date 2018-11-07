# setup fife_utils first
jobsub_submit -N 1 --resource-provides=usage_model=DEDICATED,OPPORTUNIST -M -G annie file:///annie/app/users/moflaher/test_grid/probe.sh env,memory=1000,disk=38,copy /pnfs/annie/scratch/users/moflaher/filenums.txt ${TMPDIR}/filenums.txt
