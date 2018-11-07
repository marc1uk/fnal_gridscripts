# setup fife_utils first
jobsub_submit -N 1 --resource-provides=usage_model=DEDICATED,OPPORTUNIST -M -G annie --jobsub-server=https://fifebatch-dev.fnal.gov:8443 file:///annie/app/users/moflaher/test_grid/grid.sh
