# POSCAR2TikZPic

Any information please contact dianwuwang@163.com

General information:

Create TikZ code from the POSCAR format file. POSCAR file is one of the input files of VASP(Vienna Ab initio simulation package), which contains the positions of the ions. The model can be rotated according to Eulerian angles. 

Usage:

1.Before running the code, please specify the value of related tags in the "User defined region" part of the code;

2.User can specify: the name of the input POSCAR format file, the Eulerian angles(phi,theta,kappa), viewing direction(x/y/z), element radius and element color. User can also decide: whether to draw mirror atoms at periodic boundaries, whether to draw axis indicator, the size of the axis indicator and the reference width of the TikZ picture;

3.Aftering running the code, you'll obtain an output file wihch contains the TikZ code of the model. Copy the TikZ code into the .tex file that you are working with(don't forget to write \usepackage{tikz} in the preamble of your .tex document) and compile the .tex file. 

Note:
1.The positions of POSCAR file should be given in direct(fractional) coordiantes

2.The POSCAR file in current repository is only an example file.
