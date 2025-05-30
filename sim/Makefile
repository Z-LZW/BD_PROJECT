#Name of the SV test class to pe run
TESTNAME="cov_selfcheck"
#Tool used to run simulation; 0 - Mentor, 1 - Cadence
TOOL=0
#SEED number used for randomization(for recipe where NUM_SEEDS is not used)
SEED=1
#Number of tests to be run(for recipe where SEED is not used)
NUM_SEEDS=2
#verbosity
VERBOSITY="UVM_HIGH"

#Testbench - root of hierarchy
ifeq (${TOOL},0)
	TOP="top"
else
	TOP="./../v_src/top.sv"
endif


#Add here tests to the regression list
.PHONY: run_regression	
run_regression:	
	make run_cov_multiple TOP=${TOP} TOOL=${TOOL} TESTNAME="single_conf_small_read_test" 	 NUM_SEEDS=10;
	make run_cov_multiple TOP=${TOP} TOOL=${TOOL} TESTNAME="single_conf_small_write_test"  NUM_SEEDS=10;
	make run_cov_multiple TOP=${TOP} TOOL=${TOOL} TESTNAME="multiple_conf_small_rw_test"   NUM_SEEDS=10;
	make run_cov_multiple TOP=${TOP} TOOL=${TOOL} TESTNAME="max_ts_min_bs_test"            NUM_SEEDS=10;
	make run_cov_multiple TOP=${TOP} TOOL=${TOOL} TESTNAME="max_ts_max_bs_test"            NUM_SEEDS=10;
	make run_cov_multiple TOP=${TOP} TOOL=${TOOL} TESTNAME="min_ts_test"                   NUM_SEEDS=10;
	make run_cov_multiple TOP=${TOP} TOOL=${TOOL} TESTNAME="large_burst_test"              NUM_SEEDS=15;
	make run_cov_multiple TOP=${TOP} TOOL=${TOOL} TESTNAME="large_last_burst_test"         NUM_SEEDS=15;
	make run_cov_multiple TOP=${TOP} TOOL=${TOOL} TESTNAME="rst_test"                   	 NUM_SEEDS=5;
	make run_cov_multiple TOP=${TOP} TOOL=${TOOL} TESTNAME="random_test"                   NUM_SEEDS=20;
	make merge_cov TOOL=${TOOL};

.PHONY: run_small_regression	
run_small_regression:	
	make run_cov_multiple TOP=${TOP} TOOL=${TOOL} TESTNAME="random_test"                   NUM_SEEDS=20;
	make merge_cov TOOL=${TOOL};

.PHONY: run_rst_regression
run_rst_regression:
	make run_cov TOP=${TOP} TOOL=${TOOL} TESTNAME="rst_test" SEEDS=1512;
	make run_cov TOP=${TOP} TOOL=${TOOL} TESTNAME="rst_test" SEEDS=2856;
	make run_cov TOP=${TOP} TOOL=${TOOL} TESTNAME="rst_test" SEEDS=11619;
	make run_cov TOP=${TOP} TOOL=${TOOL} TESTNAME="rst_test" SEEDS=19958;
	make run_cov TOP=${TOP} TOOL=${TOOL} TESTNAME="rst_test" SEEDS=26835;
	make merge_cov TOOL=${TOOL};

.PHONY: clean
clean:
	rm -rf work
	rm -f transcript
	rm -f compile.log
	rm -f vsim.wlf
	rm -rf covhtmlreport
	rm -rf xcelium.d
	rm -f xrun*
	rm -rf cov_work
	rm -rf logs
	rm -f imc.log
	rm -f mdv.log
	rm -f imc.key
	rm -f ./cov_ucdb/*
	rm -f ./transcripts/*
	clear	

#vlog -define ${TESTNAME} +cover +fcover -sv -f build_files_vlog > compile.log;\ 
#vsim -voptargs=+acc -classdebug ${TOP} +UVM_TESTNAME=${TESTNAME} -sv_seed ${SEED} work.top\

.PHONY: run_gui
run_gui:
	if [ ${TOOL} == 0 ]; then \
	    vlib work;\
        vmap work work;\
		vlog -define ${TESTNAME} -sv -f  build_files_vlog > compile.log; \
		vsim -voptargs=+acc -classdebug  +UVM_TESTNAME=${TESTNAME} +UVM_VERBOSITY=${VERBOSITY} -sv_seed ${SEED} work.top\
		-do wave.do\
		#-do "run -all";\
	else \
		xrun  -define ${TESTNAME} -licqueue -64bit -clean -date -access +rwc -ALLOWREDEFINITION -uvm -sv -gui -linedebug \
		-f build_files_xrun \
		${TOP} \
		+UVM_TESTNAME=${TESTNAME} \
		-l logs/${TESTNAME}_${SEED}.log -messages \
		+SEED=${SEED} \
		-simvisargs '-input load_wave.tcl';\
	fi

.PHONY: run_batch	
run_batch:
	if [ ${TOOL} == 0 ]; then \
	vlib work;\
        vmap work work;\
		vlog -sv -f build_files_vlog > compile.log; \
		vsim -c ${TOP} +UVM_TESTNAME=${TESTNAME} +UVM_VERBOSITY=${VERBOSITY} -sv_seed ${SEED} -do "run -all";\
	else \
		xrun -64bit -clean -date -access +rwc -ALLOWREDEFINITION  -sv  \
		-f build_files_xrun \
		${TOP} \
		+TESTNAME=${TESTNAME} \
		-l logs/${TESTNAME}_${SEED}.log -messages \
		+SEED=${SEED}; \
	fi
	
.PHONY: run_cov
run_cov:
	if [ ${TOOL} == 0 ]; then \
		vlog -define ${TESTNAME} +cover +fcover -sv -f build_files_vlog > compile.log; \
		vsim -c -coverage ${TOP} +UVM_TESTNAME=${TESTNAME} -sv_seed ${SEED} +UVM_VERBOSITY=${VERBOSITY} -do "coverage save -onexit ./cov_ucdb/${TESTNAME}_${SEED}.ucdb;do exclude.do; run -all; quit -f"; \
		cp transcript ./transcripts/${TESTNAME}_${SEED}_transcript \
		#vcover report -details -html ${TESTNAME}_${SEED}.ucdb; \
		#rm ${TESTNAME}_${SEED}.ucdb; \
	else \
		xrun -define ${TESTNAME} -licqueue -64bit -clean -date -access +rwc -ALLOWREDEFINITION  -sv \
		-f build_files_xrun \
		${TOP} \
		+TESTNAME=${TESTNAME} \
		-l logs/${TESTNAME}_${SEED}.log -messages \
		+SEED=${SEED} \
		-coverage all \
		-covfile ./cov.ccf \
		-covtest ${TESTNAME}_${SEED}; \
	fi

.PHONY: run_cov_multiple
run_cov_multiple:
	for i in {1..${NUM_SEEDS}}; do \
		make run_cov TOP=${TOP} TOOL=${TOOL} TESTNAME=${TESTNAME} SEED=$$RANDOM; \
	done\

	
.PHONY: run_batch_multiple
run_batch_multiple:
	for i in {1..${NUM_SEEDS}}; do \
		make run_batch TOP=${TOP} TOOL=${TOOL} TESTNAME=${TESTNAME} SEED=$$RANDOM; \
	done\
	

# Questa - vcover merge -64 merge_covucdb *.ucdb 

.PHONY: merge_cov
merge_cov:
	if [ ${TOOL} == 0 ]; then \
		vcover merge -64 merged_cov.ucdb merged_cov.ucdb ./cov_ucdb/*.ucdb; \
		vcover report -html -details merged_cov.ucdb; \
	else \
		imc -nostdout -execcmd "merge all * -overwrite -out all"; \
	fi
	clear;
