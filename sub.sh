# setup fife_utils first
jobsub_submit -N 1 --memory=4096MB --expected-lifetime=long --resource-provides=usage_model=DEDICATED,OPPORTUNIST -M -G annie file:///annie/app/users/moflaher/test_grid/grid.sh
