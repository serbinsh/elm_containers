cd /E3SM/cime/scripts
./create_newcase --case /elm_output/f19_g16.ICLM45 --res f19_g16 --compset ICLM45 --mach docker --compiler gnu
cd /elm_output/f19_g16.ICLM45
./xmlchange DATM_CLMNCEP_YR_END=1972
./xmlchange PIO_TYPENAME=netcdf
./xmlchange RUNDIR=${PWD}/run 
./xmlchange EXEROOT=${PWD}/bld
./xmlchange NTASKS=1 
./xmlchange DIN_LOC_ROOT_CLMFORC=/data/atm/datm7
./xmlchange DIN_LOC_ROOT=/data/
cd /elm_output/f19_g16.ICLM45
./case.setup
./case.build
