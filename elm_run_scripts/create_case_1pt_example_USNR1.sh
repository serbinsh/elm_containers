#!/bin/bash

WORKDIR=/elm_run_scripts/
cd $WORKDIR
echo $PWD

export start_year=$1
echo "Start year: "${start_year}
export num_years=$2
echo "Number of years: "${num_years}

# Setup simulation options
export MODEL_SOURCE=/E3SM
export MODEL_VERSION=ELM
export ELM_HASH=`(cd ${MODEL_SOURCE};git log -n 1 --pretty=%h)`
export CIME_MODEL=e3sm
export MACH=docker
export RES=f19_g16
export COMP=ICLM45
export CASEROOT=/elm_output
export date_var=$(date +%s)
export CASE_NAME=${CASEROOT}/${MODEL_VERSION}_${date_var}

# setup case
rm -rf ${CASE_NAME}

echo "*** start: ${date_var} "
echo "*** Building CASE: ${CASE_NAME} "
echo "Running with CTSM location: "${MODEL_SOURCE}
cd ${MODEL_SOURCE}/cime/scripts/

# create case
./create_newcase --case ${CASE_NAME} --res ${RES} --compset ${COMP} --mach ${MACH}

echo "*** Switching directory to CASE: ${CASE_NAME} "
echo "Build options: res=${RES}; compset=${COMP}; mach ${MACH}"
cd ${CASE_NAME}
echo ${PWD}
# =======================================================================================


# =======================================================================================
# Modifying : env_mach_pes.xml --- NEED TO REVIST THIS TO OPTIMIZE SETTINGS
echo "*** Modifying xmls  ***"

# setup run options
./xmlchange RUN_TYPE=startup
./xmlchange CALENDAR=GREGORIAN
./xmlchange --file env_run.xml --id PIO_DEBUG_LEVEL --val 0
./xmlchange --id RUN_STARTDATE --val ${start_year}
./xmlchange --id STOP_N --val ${num_years}
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

# domain file options
./xmlchange -a CLM_CONFIG_OPTS='-nofire'
./xmlchange ATM_DOMAIN_FILE=domain.lnd.fv0.9x1.25_NR1.nc
./xmlchange LND_DOMAIN_FILE=domain.lnd.fv0.9x1.25_NR1.nc
./xmlchange ATM_DOMAIN_PATH=/ctsm_example_data/
./xmlchange LND_DOMAIN_PATH=/ctsm_example_data/
./xmlchange MOSART_MODE=NULL

# update input file location for other needed run files - this makes sure the files get stored in main output directory mapped to host computer
./xmlchange DIN_LOC_ROOT_CLMFORC=/data/atm/datm7
./xmlchange DIN_LOC_ROOT=/data/

# turn off debug
./xmlchange DEBUG=FALSE
./xmlchange INFO_DBUG=0

# Optimize PE layout for run
./xmlchange NTASKS_ATM=1,ROOTPE_ATM=0
./xmlchange NTASKS_CPL=1,ROOTPE_CPL=0
./xmlchange NTASKS_LND=1,ROOTPE_LND=0
./xmlchange NTASKS_OCN=1,ROOTPE_OCN=0
./xmlchange NTASKS_ICE=1,ROOTPE_ICE=0
./xmlchange NTASKS_GLC=1,ROOTPE_GLC=0
./xmlchange NTASKS_ROF=1,ROOTPE_ROF=0
./xmlchange NTASKS_WAV=1,ROOTPE_WAV=0
./xmlchange NTASKS_ESP=1,ROOTPE_ESP=0

# Set run location to case dir
./xmlchange --file env_build.xml --id CIME_OUTPUT_ROOT --val ${CASE_NAME}
# =======================================================================================


# =======================================================================================
echo "*** Running case.setup ***"
./case.setup

cat >> user_nl_clm <<EOF
fsurdat = '/ctsm_example_data/surfdata_0.9x1.25_NR1.nc'
hist_empty_htapes = .true.
hist_fincl1 = 'NEP','NPP','GPP','TOTECOSYSC','TOTVEGC','TLAI','EFLX_LH_TOT_R','TBOT','FSDS'
hist_mfilt             = 8760
hist_nhtfrq            = -1
EOF

## define met params
cat >> user_nl_datm <<EOF
dtlimit  = 1.0e9, 1.0e9, 1.0e9
streams = 'datm.streams.txt.CLMGSWP3v1.Solar 1998 1998 2010',
          'datm.streams.txt.CLMGSWP3v1.Precip 1998 1998 2010',
          'datm.streams.txt.CLMGSWP3v1.TPQW 1998 1998 2010',
mapalgo = 'nn', 'nn', 'nn'
EOF

## define stream files and edit
cp /ctsm_example_data/user_datm.streams.txt.CLMGSWP3v1.* .

echo *** Build case ***
./case.build
 
 
echo "*** Finished building new case in CASE: ${CASE_NAME} "
# =============================================================================

