# Must define:
# DOTF: .f file containing root of file list
# TOP: name of top-level module

SRCS=$(shell $(SCRIPTS)/listfiles --relative -f flat $(DOTF))
INCDIRS=$(shell $(SCRIPTS)/listfiles --relative -f flati $(DOTF))

YOSYS=yosys
YOSYS_SMTBMC=$(YOSYS)-smtbmc

DEPTH?=20
COVER_APPEND?=3
YOSYS_SMT_SOLVER?=z3

DEFINES?=

PREP_CMD =read_verilog -formal
PREP_CMD+=$(addprefix -I,$(INCDIRS))
PREP_CMD+=$(addprefix -D,$(DEFINES) )
PREP_CMD+= $(SRCS);
PREP_CMD+=prep -top $(TOP) -nordff; async2sync; dffunmap; write_smt2 -wires $(TOP).smt2

BMC_ARGS=-s $(YOSYS_SMT_SOLVER) --dump-vcd $(TOP).vcd -t $(DEPTH)
IND_ARGS=-i $(BMC_ARGS)
COV_ARGS = -c $(BMC_ARGS) --append $(COVER_APPEND)
.PHONY: prove prep bmc induct clean

prove: bmc induct

prep:
	$(YOSYS) -p "$(PREP_CMD)" > prep.log

bmc: prep
	$(YOSYS_SMTBMC) $(BMC_ARGS) $(TOP).smt2 | tee bmc.log

induct: prep
	$(YOSYS_SMTBMC) $(IND_ARGS) $(TOP).smt2 | tee induct.log

cover: prep
	$(YOSYS_SMTBMC) $(COV_ARGS) $(TOP).smt2 | tee cover.log

clean::
	rm -f $(TOP).vcd $(TOP).smt2 srcs.mk prep.log bmc.log induct.log cover.log
