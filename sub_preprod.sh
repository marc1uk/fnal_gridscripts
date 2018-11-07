# setup fife_utils first
jobsub_submit -N 2 --resource-provides=usage_model=DEDICATED,OPPORTUNIST -M -G annie --jobsub-server=https://fifebatch-preprod.fnal.gov:8443 file:///annie/app/users/moflaher/test_grid/grid.sh
