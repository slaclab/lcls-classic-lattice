# lcls-lattice

Lattice files for the historical LCLS through 2018

Original SLAC MAD lattice:
mad/

Bmad model:
bmad/

Some files depend on the LCLS_LATTICE environmental variable, which should point to the root of this repository.

`export $LCLS_LATTICE=<root>/lcls-lattice`
  
Run tao on the LCLS model:

`tao -init $LCLS_LATTICE/bmad/model/tao.init`



  
  


