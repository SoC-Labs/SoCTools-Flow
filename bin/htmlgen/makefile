#-----------------------------------------------------------------------------
# HTML Generatoration Makefile 
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Contributors
#
# David Mapstone (d.a.mapstone@soton.ac.uk)
#
# Copyright � 2021-3, SoC Labs (www.soclabs.org)
#-----------------------------------------------------------------------------

# Top-level module of Hierarchy
TOP_MODULE      ?= nanosoc_chip

# Filelist to give to v2html
FILELIST        ?= $(PROJECT_DIR)/flist/project/system.flist

# Directory to store generated HTML
OUT_DIR         ?= $(PROJECT_DIR)

# Name of generated filelist by python script
OUTPUT_FILELIST := $(OUT_DIR)/filelist.flist

gen_html:
	@echo building HTML tree
	@mkdir -p $(OUT_DIR)/build
	@(cd $(OUT_DIR)/build; \
	rm *.html; rm *.gif; \
	$(SOCTOOLS_FLOW_DIR)/bin/filelist_compile.py -e -f $(FILELIST) -o $(OUTPUT_FILELIST) ; \
	$(SOCTOOLS_FLOW_DIR)/bin/htmlgen/v2html/v2html -f $(OUTPUT_FILELIST) -ht $(TOP_MODULE) ; )
