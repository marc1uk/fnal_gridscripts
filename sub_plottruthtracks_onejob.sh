# setup fife_utils first
jobsub_submit -N 10 --memory=4096MB --expected-lifetime=short --resource-provides=usage_model=DEDICATED,OPPORTUNIST -M -G annie file:///annie/app/users/moflaher/test_grid/grid_plottruthtracks.sh
