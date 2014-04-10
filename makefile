# Makefile for making LCLS lattice output files from the deck file. 
#
# This makefile helps make the main lattice output files (*.ps, *.print, 
# *.tape etc) from the input mad (version 8) deck (LCLS_MAIN.mad8). 
# Additionally, it helps make the "lines" files (eg lcls_lines.dat) 
# used to update the control system of the names of LCLS devices, and 
# it makes the "subway" maps (pdfs of the elements in the lines).
#
# NOTE: by default, if no files have changed, and all files are up to date,
# then executing make will not do anything - since there is nothing to be done!
# To force make to build when no inputs have changed, use make -B <target>.
# 
# Usage examples:
# 
#    make                   - Run mad8 on LCLS_MAIN.mad8 
#    make maps              - Make the device lists and maps
#    make install           - Copies the lattice files output from mad8, 
#                             to /afs/slac/www/grp/ad/model/output/<today>/
# also (rarely used)                          
#    make icons             - Make the icons for the web site
#    make installicons      - Copies web icons to the web site
#
# Prerequisites:
#
# To use this makefile you'll need a pretty standard unix machine (linux or
# mac) that has awk, dot and rsync. You will also need mad (version8) executable
# as command "mad8". 
#
# -------------------------------------------------------------------------
# Auth: Greg White, SLAC, 26-mar-2014.
# Mod:  Greg White, 3-Apr-2014
#       Fixed main target name 
#       Greg White, 27-Mar-2014
#       Install line files also. Redirect font config warnings to dev null.  
# =========================================================================

# You can override this from the command line if you want a different 
# executable.
# 
MAD8=mad8

# Convert Postcript to PDF (of twiss plots), accomplished by ps2pdf, 
# produces nicer results than convert, at least on a mac. Both should
# be available in any unix distribution. 
%.pdf : %.ps
	ps2pdf $< 
#	convert -antialias -rotate 90 $< $@

%_opticsicon.png : %.ps
	convert -rotate 90 -scale 200x140 $< $@


# To make a PDF from a .dot file, use dot. On my mac this works but gets a 
# fontconfig warning, so the pipe of the stderr to grep to dev/null is just 
# to swallow fontconfig warnings so they never get to the screen.
%_map.pdf : %.dot
	dot -Tpdf $< -o $@ 

# Where do we install the mad outputs, all associated files.
#
INSTALLROOT=/afs/slac/www/grp/ad/model/output/lcls

# Define macros that evaluate to lists of files, mainly for help installing
#
MODELLATS=*.ps *.print *.tape *.echo 
OPTICSPDFS:=$(patsubst %.ps, %.pdf, $(wildcard *.ps)) 
OPTICSICONS:=$(patsubst %.ps, %_opticsicon.png, $(wildcard *.ps)) 
DOTS=LCLS.dot GSPEC.dot SPEC.dot
MAPS:=$(patsubst %.dot, %_map.pdf, $(DOTS))
MAPICONS:=$(patsubst %.dot, %_mapicon.gif, $(DOTS))
LINES:=$(patsubst %.dot, %_lines.dat, $(DOTS))
OPTS=$(DOTS) $(MAPS) $(MAPICONS) $(OPTICSICONS) $(LINES) 
WEB=.htaccess 

# Rules. lattice is the first target in the makefile, and therefore 
# the default. To make other things, give argument. To make all, issue "make all".
#
lattice : print
opticspdfs : $(OPTICSPDFS)
opticsicons : $(OPTICSICONS)
lines : $(LINES)
dots : $(DOTS)
maps : $(MAPS)
mapicons : $(MAPICONS)
all : lattice opticspdfs opticsicons dots maps mapicons

# LCLS Lattice output
#
print : LCLS_MAIN.mad8 *.xsif
	$(MAD8) $<


# Beam line device lists and maps
#
# There rules assume you have checked out optics/script, as well as 
# optics/etc/lattice/lcls/, since they use mad2dot from the script directory.
LCLS_lines.dat LCLS.dot : LCLS.print LCLS_survey.tape 
	awk -v width=38 -v height=4  -f ../../../script/mad2dot.awk LCLS_survey.tape \
         ../../../script/elementdevices.dat LCLS.print > LCLS.dot

SPEC_lines.dat SPEC.dot : SPEC.print SPEC_survey.tape 
	awk -v width=20 -v height=10 -f ../../../script/mad2dot.awk SPEC_survey.tape \
         ../../../script/elementdevices.dat SPEC.print > SPEC.dot

GSPEC_lines.dat GSPEC.dot : GSPEC.print GSPEC_survey.tape 
	awk -v height=10 -f ../../../script/mad2dot.awk GSPEC_survey.tape \
         ../../../script/elementdevices.dat GSPEC.print > GSPEC.dot

LCLS_map.pdf : LCLS.dot

SPEC_map.pdf : SPEC.dot

GSPEC_map.pdf : GSPEC.dot


# Icon files for maps on web site (rarely updated)
#
LCLS_mapicon.gif : LCLS.dot
	dot -Tgif -Gsize="8,1.5" -o $@ $? 2>&1 | grep Fontconfig >/dev/null 

SPEC_mapicon.gif : SPEC.dot
	dot -Tgif -Gsize="0.8,1.0" -o $@ $? 2>&1 | grep Fontconfig >/dev/null 

GSPEC_mapicon.gif : GSPEC.dot
	dot -Tgif -Gsize="0.3,0.6" -o $@ $? 2>&1 | grep Fontconfig >/dev/null 

# Create these two optics plot icons by hand because conversion to png creates one
# file per plot, and the ps files have many, but we only wnat the first one.
LCLS_opticsicon.png : LCLS.ps
	convert -rotate 90 -scale 200x140 $< $@
	(mv LCLS_opticsicon-0.png LCLS_opticsicon.png; rm LCLS_opticsicon-*.png)
SPEC_opticsicon.png : SPEC.ps
	convert -rotate 90 -scale 200x140 $< $@
	(mv SPEC_opticsicon-0.png SPEC_opticsicon.png; rm SPEC_opticsicon-*.png)

# Install output lattice files, beam path device lists and maps in common area
#
ifdef INSTALLDIR
install : 
	rsync -e ssh -v $(MODELLATS) $(OPTICSPDFS) $(WEB) $(INSTALLROOT)/$(INSTALLDIR)
	rsync -e ssh -v $(OPTS) $(WEB) $(INSTALLROOT)/$(INSTALLDIR)/opt
	rsync -e ssh -v  LCLS_MAIN.mad8 *.xsif $(INSTALLROOT)/$(INSTALLDIR)/src
else
install : all
	rsync -e ssh -v $(MODELLATS) $(OPTICSPDFS) $(WEB) $(INSTALLROOT)/`date  +"%d%b%y"`
	rsync -e ssh -v $(OPTS) $(WEB)$(INSTALLROOT)/`date  +"%d%b%y"`/opt
	rsync -e ssh -v  LCLS_MAIN.mad8  *.xsif $(INSTALLROOT)/`date +"%d%b%y"`/src
	make installlatest
endif


# Install latest
#
installlatest : 
	rsync -e ssh -v $(MODELLATS) $(WEB) $(OPTICSPDFS) $(INSTALLROOT)/latest
	rsync -e ssh -v $(OPTS) $(WEB) $(INSTALLROOT)/latest/opt
	rsync -e ssh -v LCLS_MAIN.mad8 *.xsif $(INSTALLROOT)/latest/src

# Make a convenience target you cna use to delete all outout files.
clean :
	rm -f $(MODELLATS) *.pdf *.gif *.dot print
