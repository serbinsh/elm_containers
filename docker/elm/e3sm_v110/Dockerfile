# ----------------------------------------------------------------------
# Debian ELM docker container
# ----------------------------------------------------------------------

FROM serbinsh/elm_containers:baseos-stable-gcc550
MAINTAINER S.P. Serbin email: sserbin@bnl.gov

## For now this needs to be done so that ELM python build scripts can find os.user. BUT how do we then run with a different user?
# when using the --user flag it doesnt set the ENV var USER=$USER.  Maybe create a script that runs first that sets depending
# on what --user XXXXX was set to at command/run?
ENV USER=elmuser
RUN echo "export USER=elmuser" > /etc/environment

ARG ELM_BRANCH='v1.1.0-beta'
RUN echo $ELM_BRANCH

    ## temporary fix here, needs to be in baseOS.  setting gmake
RUN ln -s /usr/bin/make /usr/bin/gmake

    ## create data mount point in container - could change this to /mnt or something more generic in machines files
RUN cd / \
    && mkdir -p data \
    && mkdir -p elm_output \
    && mkdir -p scripts 
RUN chown elmuser /data
RUN chown elmuser /elm_output
RUN chown elmuser /scripts

    ## Checkout ELM model
RUN echo "*** Checkout ELM model"
RUN cd / \
    && git -c http.sslVerify=false clone -b ${ELM_BRANCH} --single-branch --depth 1 https://github.com/E3SM-Project/E3SM.git \
    && cd /E3SM \
    && git config http.sslVerify false \
    && git tag \
    && sed -i 's|git@github.com:NGEET/fates-release.git|https://github.com/NGEET/fates-release.git|g' .gitmodules \
    && sed -i 's|git@github.com:MPP-LSM/MPP.git|https://github.com/MPP-LSM/MPP.git|g' .gitmodules \
    && sed -i 's|git@github.com:BeTR-biogeochemistry-modeling/sbetr.git|https://github.com/BeTR-biogeochemistry-modeling/sbetr.git|g' .gitmodules \
    && sed -i 's|git@github.com:MPAS-Dev/MPAS-Model.git|https://github.com/MPAS-Dev/MPAS-Model.git|g' .gitmodules \
    && git submodule update --init --recursive \
    && cd /E3SM/cime/config/e3sm/machines \
    && rm config_compilers.xml \
    && rm config_machines.xml \
    && wget https://raw.githubusercontent.com/serbinsh/elm_containers/master/cime_config_files/e3sm/machines/docker/config_compilers.xml \
    && wget https://raw.githubusercontent.com/serbinsh/elm_containers/master/cime_config_files/e3sm/machines/docker/config_machines.xml \
    && cd / \
    && mkdir -p elm_run_scripts \
    && cd elm_run_scripts \
    && wget https://raw.githubusercontent.com/serbinsh/elm_containers/master/elm_run_scripts/create_case_1pt_example_USNR1.sh \
    && wget https://raw.githubusercontent.com/serbinsh/elm_containers/master/elm_run_scripts/simple_f19_g16_ICLM45_test_case.sh \
    && wget https://raw.githubusercontent.com/serbinsh/elm_containers/master/elm_run_scripts/basic_f19_g16_ICLM45_test_case.sh \
    && chmod 775 create_case_1pt_example_USNR1.sh \
    && chmod 775 simple_f19_g16_ICLM45_test_case.sh \
    && basic_f19_g16_ICLM45_test_case.sh

    ## Create US-NR1 example data directory. ---- Update scripts for E3SM!
RUN cd / \
    && mkdir -p elm_example_data \
    && chown elmuser /elm_example_data \
    && cd elm_example_data \
    && wget https://github.com/serbinsh/ctsm_containers/raw/master/ctsm_example_data/USNR1/USNR1_CTSM_Example_Data.tar.gz \
    && tar -zxvf USNR1_CTSM_Example_Data.tar.gz \
    && rm USNR1_CTSM_Example_Data.tar.gz

    ## setup elmuser to use with docker
RUN export USER=elmuser

    ## Build example case as a test
RUN cd /E3SM/cime/scripts \
    && echo $(head -1 /etc/hosts | cut -f1) docker >> /etc/hosts \
    && ./create_newcase --case /elm_output/f19_g16.ICLM45 --res f19_g16 --compset ICLM45 --mach docker --compiler gnu \
    && cd /elm_output/f19_g16.ICLM45 \
    && ./xmlchange DATM_CLMNCEP_YR_END=1972 \
    && ./xmlchange PIO_TYPENAME=netcdf \
    && ./xmlchange RUNDIR=${PWD}/run \
    && ./xmlchange EXEROOT=${PWD}/bld \
    && ./xmlchange NTASKS=1 \
    && ./xmlchange DIN_LOC_ROOT=$PWD \
    && cd /elm_output/f19_g16.ICLM45 \
    && ./case.setup \
    && ./case.build

    ## Remove test build
RUN cd /elm_output \
    && rm -r f19_g16.ICLM45/

### EOF