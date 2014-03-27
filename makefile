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
# Mod:  Greg White, 27-Mar-2014
#       Install line files also. Redirect font config warnings to dev null.  
# =========================================================================

# To make a PDF from a .dot file, use dot. On my mac this works but gets a 
# fontconfig warning, so the pipe of the stderr to grep to dev/null is just 
# to swallow fontconfig warnings so they never get to the screen.
%.pdf : %.dot
	dot -Tpdf $< -o $@ 2>&1 | grep Fontconfig >/dev/null 

LCLSLATS=LCLS.ps LCLS.print LCLS24OCT13.print LCLS_survey.tape LCLS_rmat.tape LCLS_twiss.tape LCLS.echo LCLSI.print
BSYLATS=BSY-52LINE.print BSY-52LINE.ps BSY-LCLS.print BSY-LCLS_survey.tape BSY-SFTDMP.print BSY-SFTDMP.ps
GSPECLATS=GSPEC.ps GSPEC.print GSPEC_survey.tape
SPECLATS=SPEC.ps SPEC.print SPEC_survey.tape
MODELLATS=$(LCLSLATS) $(BSYLATS) $(GSPECLATS) $(SPECLATS)
MAPS=LCLS.pdf SPEC.pdf GSPEC.pdf
LINES=lcls_lines.dat spec_lines.dat gspec_lines.dat
ICONS=lclsmapicon.gif gspecmapicon.gif specmapicon.gif


# Rules
#
lattice : $(MODELLATS)
lines : $(LINES)
maps : $(MAPS)
icons : $(ICONS)
all : lattice lines maps icons

# LCLS Lattice output
#
$(MODELOUTPUT) : LCLS_MAIN.mad8 LCLS_L1.xsif LCLS_L2.xsif LCLS_L3.xsif
	mad8 $<

# Beam line device lists and maps
#
# There rules assume you have checked out optics/script, as well as 
# optics/etc/lattice/lcls/, since they use mad2dot from the script directory.
lcls_lines.dat LCLS.dot : LCLS.print LCLS_survey.tape 
	awk -v width=38 -v height=4  -f ../../../script/mad2dot.awk LCLS_survey.tape \
         ../../../script/elementdevices.dat LCLS.print > LCLS.dot

spec_lines.dat SPEC.dot : SPEC.print SPEC_survey.tape 
	awk -v width=20 -v height=10 -f ../../../script/mad2dot.awk SPEC_survey.tape \
         ../../../script/elementdevices.dat SPEC.print > SPEC.dot

gspec_lines.dat GSPEC.dot : GSPEC.print GSPEC_survey.tape 
	awk -v height=10 -f ../../../script/mad2dot.awk GSPEC_survey.tape \
         ../../../script/elementdevices.dat GSPEC.print > GSPEC.dot

LCLS.pdf : LCLS.dot

SPEC.pdf : SPEC.dot

GSPEC.pdf : GSPEC.dot

# Icon files for maps on web site (rarely updated)
#
gspecmapicon.gif : GSPEC.dot
	dot -Tgif -Gsize="0.3,0.6" -o $@ $? 2>&1 | grep Fontconfig >/dev/null 

specmapicon.gif : SPEC.dot
	dot -Tgif -Gsize="0.8,1.0" -o $@ $? 2>&1 | grep Fontconfig >/dev/null 

lclsmapicon.gif : LCLS.dot
	dot -Tgif -Gsize="8,1.5" -o $@ $? 2>&1 | grep Fontconfig >/dev/null 

# Install output lattice files, beam path device lists and maps in common area
#
install : 
	rsync -e ssh -v $(MODELLATS) $(MAPS) $(LINES) /afs/slac/www/grp/ad/model/output/`date  +"%Y%m%d"`

# Install icons in web image directory
#
installicons : 
	rsync -e ssh -v $(ICONS) /afs/slac/www/grp/ad/model/images/
