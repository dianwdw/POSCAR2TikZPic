#!/bin/sh
##################################
#Version Info
################################## 
#For any information please contact dianwuwang@163.com
#Script Description
#POSCAR2TikzPicV1.1 20180314
#Generate tikzpicture, viewing from y direction
#POSCAR file must use direct coordinate
#Only for orthogonal box
###################################

###################################################
#Hint
###################################################
echo "*****************************************************"
echo "The input POSCAR file must have the following format:"
echo "----------------"
echo "line1:	Comment line"
echo "line2:	3.57"
echo "line3:	0.0 0.5 0.5"
echo "line4:	0.5 0.0 0.5"
echo "line5:	0.5 0.5 0.0"
echo "line6:	Ni Al"
echo "line7:	20 30"
echo "line8:	Selective dynamics"
echo "line9:	Direct"
echo "line10:	0.00 0.00 0.00 F F T"
echo "line11:	0.25 0.25 0.25 T T T"
echo "line12:	...  ...  ..."
echo "......"
echo "----------------"

##################################
# Variables
##################################
InputCoords="CONTCAR"
OutFile1="tikzpicture.dat"

if [ ! -f ${InputCoords} ];then
  echo "Error! No ${InputCoords} file in current folder, please check current folder"
  exit
fi

if [ ! -f ${OutFile1} ];then
  touch $OutFile1
else  
  rm $OutFile1
fi


sed -i 's/\r/ /g' ${InputCoords}
#-First $NHeader lines are header of the POSCAR file
NHeader=9

###################################################
# Extract information from the input POSCAR file
###################################################
echo "Information for input POSCAR file:"

#-Get number of element species
NSpecies=$(sed -n '7p' ${InputCoords} | awk '{print NF}' )
echo "NSepcies= " $NSpecies

#-Array AtomSpeciesName
ElementStartLine[0]=$(echo "$NHeader +1" | bc)
ElementNum[0]=0
SumElementNum=0
Ntot=0
for((i=1;i<=${NSpecies};i++));
do
	ElementName[i]=$(sed -n '6p' ${InputCoords} | awk '{print $'$i'}')
	ElementNum[i]=$(sed -n '7p' ${InputCoords} | awk '{print $'$i'}' )

#-Start line number for each atom species	
	j=$(echo "$i - 1" | bc)
	ElementStartLine[i]=$(echo "${ElementStartLine[j]}+${ElementNum[j]}" | bc) 
	echo "ElementName[$i]= " ${ElementName[i]}, "ElementStartLine[$i]= " ${ElementStartLine[i]}

#Define array AtomSpeciesName
	for ((k=1;k<=${ElementNum[i]};k++))
	do
		iAtom=$(echo "$SumElementNum+$k" | bc)
		AtomSpeciesName0[iAtom]=${ElementName[i]}
		AtomSubindex[iAtom]=$k
	done

#Sum the number of atoms from atom species to atom species
	SumElementNum=$(echo "$SumElementNum + ${ElementNum[i]}" | bc | awk '{print $1}')
done

#-Total number of atoms in the system
	Ntot=$SumElementNum
	echo "Ntot= " $Ntot
	echo "------------------------------------"
echo $NSys


La=$(sed -n '3p' ${InputCoords} | awk '{print $1}')
Lb=$(sed -n '4p' ${InputCoords} | awk '{print $2}')
Lc=$(sed -n '5p' ${InputCoords} | awk '{print $3}')

#Write header of tikzpicture
echo "\\begin{figure}[htbp]" >> $OutFile1
echo "\\centering" >> $OutFile1
echo "\\begin{tikzpicture}[scale=0.3]" >> $OutFile1
echo "\\draw [help lines] (0,0) -- ($La,0) -- ($La,$Lc) -- (0,$Lc) -- (0,0);" >> $OutFile1

for ((i=1;i<=$Ntot;i++))
do
	j=$(echo "$i+$NHeader" | bc)
	x=$(sed -n ''$j'p' ${InputCoords} | awk '{print $1}')
	y=$(sed -n ''$j'p' ${InputCoords} | awk '{print $2}')
	z=$(sed -n ''$j'p' ${InputCoords} | awk '{print $3}')
	xcar=$(echo "${x}*${La}" | bc)
	ycar=$(echo "${y}*${Lb}" | bc)
	zcar=$(echo "${z}*${Lc}" | bc)
	echo -e "\\draw [fill] ( $xcar , $zcar ) \t circle [radius=0.1];" >> $OutFile1
done

echo "\\end{tikzpicture}" >> $OutFile1
echo "\\end{figure}" >> $OutFile1

###############################################
echo "Completed!Please check file: ${OutFile1}"
