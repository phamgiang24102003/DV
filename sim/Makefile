build:
	vlib work
	vmap work work
	vlog +incdir+../rtl -f compile.f
run:
	vsim -debugDB -l report.log -voptargs=+acc -assertdebug -c test -do "log -r /*; run -all;"
wave:
	vsim -i -view vsim.wlf -do "add wave /dut_c/*; radix -decimal" &

