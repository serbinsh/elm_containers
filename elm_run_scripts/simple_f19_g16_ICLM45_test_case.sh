#!/bin/bash

WORKDIR=/elm_run_scripts/
cd $WORKDIR
echo $PWD

# Setup simulation options
export MODEL_SOURCE=/E3SM
export MODEL_VERSION=ELM
export ELM_HASH=`(cd ${MODEL_SOURCE};git log -n 1 --pretty=%h)`
export CIME_MODEL=e3sm
export MACH=docker
export CASEROOT=/elm_output
export date_var=$(date +%s)
export CASE_NAME=${CASEROOT}/${MODEL_VERSION}_${date_var}

# setup case
rm -rf ${CASE_NAME}
cd ${MODEL_SOURCE}/cime/scripts/

./create_newcase --case ${CASE_NAME} --res f19_g16 --compset ICLM45 --mach docker --compiler gnu

cd ${CASE_NAME}
echo ${PWD}

# setup run options
./xmlchange RUN_TYPE=startup
./xmlchange CALENDAR=GREGORIAN
./xmlchange --file env_run.xml --id PIO_DEBUG_LEVEL --val 0
./xmlchange --id RUN_STARTDATE --val 1972
./xmlchange --id STOP_N --val 1
./xmlchange --id STOP_OPTION --val nyears
./xmlchange --id REST_N --val 1
./xmlchange --id REST_OPTION --val nyears
./xmlchange --id CLM_FORCE_COLDSTART --val on
./xmlchange --id RESUBMIT --val 0
./xmlchange PIO_TYPENAME=netcdf
./xmlchange --file env_run.xml --id DOUT_S_SAVE_INTERIM_RESTART_FILES --val FALSE
./xmlchange --file env_run.xml --id DOUT_S --val FALSE
./xmlchange --file env_run.xml --id DOUT_S_ROOT --val '$CASEROOT/run'
./xmlchange --file env_run.xml --id RUNDIR --val ${CASE_NAME}/run
./xmlchange --file env_build.xml --id EXEROOT --val ${CASE_NAME}/bld
./xmlchange NTASKS=1

# update input file location for other needed run files - this makes sure the files get stored in main output directory mapped to host computer
./xmlchange DIN_LOC_ROOT_CLMFORC=/data/atm/datm7
./xmlchange DIN_LOC_ROOT=/data/

# turn off debug
./xmlchange DEBUG=FALSE
./xmlchange INFO_DBUG=0

# Set run location to case dir
./xmlchange --file env_build.xml --id CIME_OUTPUT_ROOT --val ${CASE_NAME}

echo "*** Running case.setup ***"
./case.setup

echo *** Build case ***
./case.build

echo "*** Finished building new case in CASE: ${CASE_NAME} "