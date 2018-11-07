## start (make) the project
############################
def=wcsim_multipmt_tankonly_17-06-17_rhatcher_wcsimfiles     # dataset name
wcsim_commit="2097ece743dcdb91c18431a6e90774d7b1ed8584"

#PROJ_NAME=moflaher_wcsim_multipmt_tankonly_17-06-17_rhatcher_wcsimfiles_20180611_010544
PROJ_NAME=${USER}_${def}_`date +%Y%m%d_%H%M%S`               # project name
PROJ_URL=`ifdh startProject $PROJ_NAME ${EXPERIMENT} ${def} ${USER} ${GROUP}`
#PROJ_URL=`samweb start-project --defname=$def $PROJ_NAME`   # or use --snapshot_id= instead of defname
echo "PROJ_URL is" ${PROJ_URL}                               # to run an existing snapshot
sleep 2
PROJ_URL=`ifdh findProject  $PROJ_NAME ${EXPERIMENT}`        # check we can find the project
echo "found PROJ_URL is" ${PROJ_URL}
echo "printing project summary"
samweb project-summary ${PROJ_URL}                             # print snapshot created/used

export NUMJOBS=`samweb count-files "defname: ${def}"`
echo "submitting ${NUMJOBS} to process files"
export NUMJOBS=5

## set up environmental variables to pass to the grid script
############################################################

jobsub_submit -N ${NUMJOBS} --memory=4096MB --expected-lifetime=short --resource-provides=usage_model=DEDICATED,OPPORTUNIST -M -G ${GROUP} -e PROJ_NAME=${PROJ_NAME} -e DATASET_NAME=${def} -e USER=${USER} -e GROUP=${GROUP} -e EXPERIMENT=${EXPERIMENT} -e wcsim_commit=${wcsim_commit} file:///annie/app/users/moflaher/test_grid/grid_plottruthtracks_samjob.sh

#jobsub_submit option:
#      -f INPUT_FILE       at runtime, INPUT_FILE will be copied to directory
#                          $CONDOR_DIR_INPUT on the execution node.  Example :-f
#                          /grid/data/minerva/my/input/file.xxx  will be copied
#                          to $CONDOR_DIR_INPUT/file.xxx  Specify as many -f
#                          INPUT_FILE_1 -f INPUT_FILE_2  args as you need.  To
#                          copy file at submission time  instead of run time, use
#                          -f dropbox://INPUT_FILE to  copy the file.
# use
#        \jobsub_submit --group=annie --jobsub-server=jobsub01.fnal.gov --help
# to see full help
