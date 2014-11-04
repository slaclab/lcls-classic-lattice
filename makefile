#
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
# NOTE2: This makefile should be run by GNU make. On some OS, eg Solaris, use 
# gmake command rather than make.
# 
# Usage examples:
# 
#    make                    - (Default) Only run mad8 on LCLS_MAIN.mad8. 
#    make maps               - Make the device lists and maps
#    make all                - Makes all mad output, maps, device lists and icons.
#    make INSTALLDIR=<dirname> install 
#                            - Releases files to the web, in a dir that matches
#                              the CVS tag.
#                              /afs/slac/www/grp/ad/model/output/lcls/<dirname>
#    make installlatest      - Releases files and updates to the web
#                              /afs/slac/www/grp/ad/model/output/lcls/latest
# Also (rarely used):
#                          
#    make icons              - Make the icons for the web site
#    make installicons       - Copies web icons to the web site
#
# Typical usage cycle:
#
#    cvs co optics/etc/lattice/lcls
#    cvs co optics/script
#    cd optics/etc/lattice/lcls
#    make
#    make all
#
# To release optics files:
#
#    cvs commit -m "my changes" optics/etc/lattice/lcls 
#    cvs rtag v19AUG2014 
#    make INSTALLDIR=19AUG2014 install
#    make installlatest
# 
# Prerequisites:
#
# To use this makefile you'll need a pretty standard unix machine (linux or
# mac) that has the GNU toolset (specifically gmake, gawk), plus dot and rsync. 
#
# You will also need mad (version8) executable, either as command "mad8" or
# tell make where it is, like this:
#  
#     make MAD8=/afs/slac.stanford.edu/u/ad/mdw/mad8.52/mad 
#
# -------------------------------------------------------------------------
# Auth: Greg White, SLAC, 26-mar-2014.
# Mod:  Greg White, SLAC, 3-Nov-2014
#       Make compatible with Solaris; use explicit frame selection in convert 
#       command instead of mv and rm, and awk -> gawk. Fixed install rsync.
#       Mark Woodley, SLAC, 22-oct-2014.
#       Point MAD8 to standard SLAC codes area
#       Greg White, 19-Aug-2014
#       Delete obsolete files from latest/ install directory as part of sync.
#       Added staging the release. Removed 
#       Greg White, 10-Apr-2014
#       Improve map icons. Some windows browsers showed just whitespace, so
#       converted to using convert and producing pngs.
#       Greg White, 3-Apr-2014
#       Fixed main target name 
#       Greg White, 27-Mar-2014
#       Install line files also. Redirect font config warnings to dev null.  
# =========================================================================

# 
# MACROS
#

# You can override this from the command line if you want a different 
# executable.
# 
MAD8=/afs/slac/g/ilc/codes/mad8.52/mad

# Default dir in which to install the mad outputs, and all associated files.
#
INSTALLROOT=/afs/slac/www/grp/ad/model/output/lcls

# To convert Postcript to PDF (of twiss plots), use ps2pdf. 
%.pdf : %.ps
	ps2pdf $< 

# To make png icon files from postscript, use convert.
%_opticsicon.png : %.ps
	convert -rotate 90 -scale 200x140 $< $@

# To make a PDF from a .dot file, use dot. 
%_map.pdf : %.dot
	dot -Tpdf $< -o $@

# Define macros that evaluate to lists of files, mainly for help installing
#
MODELLATS=*.ps *.print *.tape *.echo 
ELEMENTDEVICES=../../../script/elementdevices.dat
OPTICSPDFS:=$(patsubst %.ps, %.pdf, $(wildcard *.ps)) 
OPTICSICONS:=$(patsubst %.ps, %_opticsicon.png, $(wildcard *.ps)) 
DOTS=LCLS.dot GSPEC.dot SPEC.dot
MAPS:=$(patsubst %.dot, %_map.pdf, $(DOTS))
MAPICONS:=$(patsubst %.dot, %_mapicon.png, $(DOTS))
LINES:=$(patsubst %.dot, %_lines.dat, $(DOTS))
OPTS=$(DOTS) $(MAPS) $(MAPICONS) $(OPTICSICONS) $(LINES) 
WEB=.htaccess 

#
# RULES
#

# Lattice is the first target in the makefile, and therefore 
# the default. To make other things, give argument. To make all, 
# issue "make all".
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
ifdef OUTPUTDIR
	rsync $(MODELLATS) $(OUTPUTDIR)
endif

# Beam line device lists and maps
#
# There rules assume you have checked out optics/script, as well as 
# optics/etc/lattice/lcls/, since they use mad2dot from the script directory.
#
LCLS_lines.dat LCLS.dot : LCLS_survey.tape $(ELEMENTDEVICES) LCLS.print  
	gawk -v width=38 -v height=4  -f ../../../script/mad2dot.awk $+ > LCLS.dot

SPEC_lines.dat SPEC.dot : SPEC_survey.tape $(ELEMENTDEVICES) SPEC.print 
	gawk -v width=20 -v height=10 -f ../../../script/mad2dot.awk $+ > SPEC.dot

GSPEC_lines.dat GSPEC.dot : GSPEC_survey.tape $(ELEMENTDEVICES) GSPEC.print
	gawk -v height=10 -f ../../../script/mad2dot.awk $+ > GSPEC.dot

LCLS_map.pdf : LCLS.dot

SPEC_map.pdf : SPEC.dot

GSPEC_map.pdf : GSPEC.dot


# Icon files for maps on web site (rarely updated)
#
LCLS_mapicon.png : LCLS_map.pdf
	convert -scale 800 $? $@ 

SPEC_mapicon.png : SPEC_map.pdf
	convert -scale 60 $? $@ 

GSPEC_mapicon.png : GSPEC_map.pdf
	convert -scale 40 $? $@ 


# Create these two optics plot icons by hand because we only want the 
# first frame from the PS. 
LCLS_opticsicon.png : LCLS.ps
	convert -rotate 90 -scale 200x140 'LCLS.ps[0]' $@
SPEC_opticsicon.png : SPEC.ps
	convert -rotate 90 -scale 200x140 'SPEC.ps[0]' $@


# Prepare the files to install in a local staging directory. Do this for
# two reasons; first we can check what will be synced, second, this way we can
# use --delete on the production rsync to remove files on the server that are
# no longer wanted, which is only possible if one syncs whole directories as
# opposed to lists of files.
#
stage :
	mkdir -p .installstage
	rsync -az $(MODELLATS) $(OPTICSPDFS) $(WEB) .installstage
	rsync -az $(OPTS) $(WEB) $(ELEMENTDEVICES) .installstage/opt
	rsync -az  LCLS_MAIN.mad8 *.xsif .installstage/src

# Install output lattice files, beam path device lists and maps in release area
#
install : stage
	rsync -azv .installstage/ $(INSTALLROOT)/$(INSTALLDIR)

# Install latest
#
# Note use of / at end of direcory names in rsync, which with --delete 
# has the desired effect of synchronizing the contents of the directories,
# and deleting any files in latest/ that are not also found in .installstage/,
# thus pruning out files we no longer wish to publish. 
#
installlatest : stage
	rsync -e ssh -r --delete -v .installstage/ $(INSTALLROOT)/latest/


# Clean is a convenience target to delete all output files.
#
clean :
	rm -f $(MODELLATS) *.pdf *.png *.dot print
	rm -fr .installstage
