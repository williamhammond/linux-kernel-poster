#! /usr/bin/make

# Adjustable parameters

# How much to overlap files (eg. 0.5 = give them 50% of their size).
FILE_SCRUNCH=1.0
# How much to overlap functions.
FUNCTION_SCRUNCH=1.0
# Radius of inner area (where Tux goes).
INNER_RADIUS=200
# Spacing between segments (degrees).
DIR_SPACING=2
# Functions smaller than this number of lines get culled, to avoid clutter.
YOU_MUST_BE_ABOVE_THIS_LINE_TO_BE_IN_LINUX=5
# Spacing between rings (pixels)
RING_SPACING=100

RING1:=init lib mm kernel ipc
RING2:=net fs
RING3:=arch/alpha arch/arm arch/i386 arch/ia64 arch/m68k arch/mips arch/mips64 arch/parisc arch/ppc arch/s390 arch/sh arch/sparc arch/sparc64
RING4:=drivers

ifndef KERNEL_DIR
dummy:
	@echo You must set KERNEL_DIR.  Read README.
	@exit 1
endif

CFLAGS:=-Wall -O2

default: image.ps

stage2-clean:
	rm -f image/Makefile
	find image -name '*.ps' -o -name '*.angle' -o -name '*.weight' | xargs -r rm

clean:
	rm -f image.ps analyze_function analyze_function.c data2ps draw_arrangement *~

distclean: clean
	rm -rf image

data2ps: data2ps.c
	$(CC) $(CFLAGS) -O -o $@ $^ -lm

analyze_function: analyze_function.c
	$(CC) $(CFLAGS) -O -o $@ $^ -lfl

conglomerate_functions: conglomerate_functions.c
	$(CC) $(CFLAGS) -O -o $@ $^ -lpng -lm

draw_arrangement: draw_arrangement.c
	$(CC) $(CFLAGS) -o $@ $^ -lm

merge_png: merge_png.c
	$(CC) $(CFLAGS) -o $@ $^ -lpng -lm

png_area: png_area.c
	$(CC) $(CFLAGS) -o $@ $^ -lpng -lm

draw_sector: draw_sector.c
	$(CC) $(CFLAGS) -o $@ $^ -lpng -lm

%.c: %.lex
	lex $^ && mv lex.yy.c $@

# We generate the image/ dir, and the Makefile in it.
image.ps: analyze_function data2ps draw_arrangement image image/ring1 image/ring2 image/ring3 image/ring4 image/nonstatics image/Makefile
	cd image && $(MAKE) image.ps
	@rm -f image.ps; ln -s image/image.ps .

# Create Makefile.
image/Makefile: gen_makefile.sh
	@echo STAGE 2: Creating PostScript...
	FILE_SCRUNCH="$(FILE_SCRUNCH)" RING1="$(RING1)" RING2="$(RING2)" RING3="$(RING3)" RING4="$(RING4)" FUNCTION_SCRUNCH="$(FUNCTION_SCRUNCH)" INNER_RADIUS=$(INNER_RADIUS) DIR_SPACING=$(DIR_SPACING) RING_SPACING=$(RING_SPACING) ./gen_makefile.sh > $@

define COPY_FUNCS
set -e; cd image; \
for d in `cd $(KERNEL_DIR) && find $$DIRS -type d`; do \
	[ -d $$d ] || mkdir $$d; \
	for f in $(KERNEL_DIR)/$$d/*.c; do \
		if [ "$$f" = "$(KERNEL_DIR)/$$d/*.c" ]; then echo SKIPPING $$f; continue; fi; \
		BASE=`basename $$f`; \
		if [ "`echo $$d/$$BASE.*`" = "$$d/$$BASE.*" ] 2>/dev/null; then \
			echo "Finding functions in $$d/$$BASE"; \
			cp $$f $$d/; ../analyze_file.pl $$d/$$BASE; \
			for fun in $$d/$$BASE.*; do \
				[ `wc -l < $$fun` -gt $(YOU_MUST_BE_ABOVE_THIS_LINE_TO_BE_IN_LINUX) ] 2>/dev/null || rm -f $$fun; \
			done; \
			rm $$d/`basename $$f`; \
		fi; \
	done; \
done
endef

# Copy functions over a certain size from kernel sources.
image:
	@mkdir image && mkdir image/arch

image/ring1:
	@echo STAGE 1: Function extraction and classification.
	@echo Copying ring1 functions from kernel directory...
	@DIRS="$(RING1)"; $(COPY_FUNCS)
	@echo Classifying ring1 functions...
	@cd image; find $(RING1) -name '*.c.*' ! -name '*.c.*+' ! -name '*.ps' -exec ../classify_function.sh {} $(KERNEL_DIR) \;
	@touch $@

image/ring2:
	@echo Copying ring2 functions from kernel directory...
	@DIRS="$(RING2)"; $(COPY_FUNCS)
	@echo Classifying ring2 functions...
	@cd image; find $(RING2) -name '*.c.*' ! -name '*.c.*+' ! -name '*.ps' -exec ../classify_function.sh {} $(KERNEL_DIR) \;
	@touch $@

image/ring3:
	@echo Copying ring3 functions from kernel directory...
	@DIRS="$(RING3)"; $(COPY_FUNCS)
	@echo Classifying ring3 functions...
	@cd image; find $(RING3) -name '*.c.*' ! -name '*.c.*+' ! -name '*.ps' -exec ../classify_function.sh {} $(KERNEL_DIR) \;
	@touch $@

# There's a broken function in amijoy... (missing ").  Fix it.
image/ring4:
	@echo Copying ring4 functions from kernel directory...
	@DIRS="$(RING4)"; $(COPY_FUNCS)
	@sed 's/amijoy \[Denise\]/"amijoy [Denise]/g' < image/drivers/char/joystick/amijoy.c.amijoy_init > image/drivers/char/joystick/amijoy.c.amijoy_init. && mv image/drivers/char/joystick/amijoy.c.amijoy_init. image/drivers/char/joystick/amijoy.c.amijoy_init
	@echo Classifying ring4 functions...
	@cd image; find $(RING4) -name '*.c.*' ! -name '*.c.*+' ! -name '*.ps' -exec ../classify_function.sh {} $(KERNEL_DIR) \;
	@touch $@

image/nonstatics:
	@echo Classifying remaining nonstatics...
	@cd image; find $(RING1) $(RING2) $(RING3) $(RING4) -name '*.+NONSTATIC+' | xargs ../classify_nonstatics.sh $(KERNEL_DIR)
	@touch $@

