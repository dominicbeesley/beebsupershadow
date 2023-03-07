SOURCES = $(wildcard src/*.s) $(wildcard src/*/*.s)
COMMON = $(wildcard src/common/*.s)

TESTPROGS = SSTEST SSTESTX SSTEST2 SHATEST

PROGS = SUPSHAD SSOFF $(TESTPROGS)

INFS = $(addsuffix .inf,$(PROGS))

all: bin/supershadow.rom $(addprefix bin/,$(PROGS) $(INFS))

#dnfs/supdnfs.rom 

TARG = ../serial/serialfs/storage/DEFAULT

DEPLOYS = $(addprefix $(TARG)/,$(PROGS) $(INFS))

deploy: $(DEPLOYS)

ssd: all
	dfs form -80 supershadow.ssd
	dfs title supershadow.ssd supershadow
	dfs add supershadow.ssd $(addprefix bin/,$(INFS))
	dfs add -e 0xFF8000 -l 0xFF8000 -f "R.SUPERS" supershadow.ssd bin/supershadow.rom

hostfs: ssd
	mkdir -p ~/hostfs/supershadow
	dfs read -i -d ~/hostfs/supershadow supershadow.ssd


clean:
	-rm -f bin/*

bin/SUPSHAD labels/supshad.labels: $(SOURCES)
	xa -o bin/SUPSHAD src/main.s -I src -DSTANDALONE -l labels/supshad.labels

bin/SUPSHAD.inf: py/writeinf.py py/parsesyms.py labels/supshad.labels
	python py/writeinf.py labels/supshad.labels $@


EMBED_FILES = bin/SHATEST embedfiles/LANGTST embedfiles/PLOTTST embedfiles/STRESS

bin/supershadow.rom labels/supershadow.rom.labels: $(SOURCES) $(EMBED_FILES)
	xa -o bin/temp.rom src/main.s -I src -l labels/supershadow.rom.labels
	python py/addromfile.py bin/temp.rom $(EMBED_FILES)
	mv out.rom bin/supershadow.rom

dnfs/supdnfs.rom: dnfs/patch_dnfs.py dnfs/dnfs.rom
	(cd dnfs && python patch_dnfs.py)


burn: bin/supershadow.rom
	minipro -p AT28C64B -w bin/supershadow.rom -s


$(TARG)/% : bin/%
	cp $< $@


bin/SSTEST.inf:bin/SSTEST
bin/SSTESTX.inf:bin/SSTESTX
bin/SSTEST2.inf:bin/SSTEST2
bin/SSOFF.inf:bin/SSOFF

bin/SSTEST: testsrc/test.s
	xa -o $@ $<
	echo '$$.SSTEST      ffff2000 ffff2000' > $@.inf

bin/SSTESTX: testsrc/test1x.s
	xa -o $@ $<
	echo '$$.SSTESTX     ffff2000 ffff2000' > $@.inf

bin/SSTEST2: testsrc/test2.s
	xa -o $@ $<
	echo '$$.SSTEST2     ffff2000 ffff2000' > $@.inf

bin/SHATEST: testsrc/shatest.s
	xa -o $@ $<
	echo '$$.SHATEST     00002000 00002000' > $@.inf

bin/SSOFF: testsrc/ssoff.s $(COMMON)
	xa -o $@ $<
	echo '$$.SSOFF       ffff2000 ffff2000' > $@.inf

