#!/bin/sh
##################################
#Version Info
################################## 
#For any information please contact dianwuwang@163.com
#Script Description
#POSCAR2TikZPicV1.1.sh 20180314
#Generate tikzpicture, viewing from y direction
#POSCAR file must use direct coordinate
#Only for orthogonal box
#POSCAR2TikZPicV1.2.sh 20180315
#Add model rotation function according to Eulerian angles,reference: J. Hirth and J. Lothe, Theory of dislocations, 1982
#Add choices for user: viewing frim x, y or z direction
#Add user specified value: element radius,element color, scaling factor
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

#################################
#User defined region
#################################
#Define rotation angles, units in degrees.Eeference:J. Hirth and J. Lothe, Theory of dislocations, 1982
theta=-5; phi=185; kappa=0;

#Decide viewing from which direction: "x" or "y" or "z" or "-x" or "-y" or "-z"
ViewFrom="y"

#scaling factor in TikZ
scale=0.3

#Define atom radius, units in Angstrom
ElementRadius[1]=0.1;ElementRadius[2]=0.2;ElementRadius[3]=0.1;ElementRadius[4]=0.1;ElementRadius[5]=0.1;ElementRadius[6]=0.1;

#Define element color, choices are: black,red,green,blue,cyan,magenta,yellow,gray,darkgray,lightgray,brown,lime,olive,orange,pink,purple,teal,violet and white.
#The order must is in line with the eleemnt order in POSCAR
#Redundunt ElementCol tag will not be used.
ElementCol[1]="black";ElementCol[2]="magenta";ElementCol[3]="red";ElementCol[4]="blue";ElementCol[5]="green";ElementCol[6]="yellow";

##################################
# Variables
##################################
InputCoords="CONTCAR"
OutFile1="tikzpicture_${ViewFrom}_theta${theta}phi${phi}kappa${kappa}.dat"

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
		ElementSpeciesIndex[iAtom]=$i
	done

#Sum the number of atoms from atom species to atom species
	SumElementNum=$(echo "$SumElementNum + ${ElementNum[i]}" | bc | awk '{print $1}')
done

#-Total number of atoms in the system
	Ntot=$SumElementNum
	echo "Ntot= " $Ntot
	echo "------------------------------------"
echo $NSys


L[1]=$(sed -n '3p' ${InputCoords} | awk '{print $1}')
L[2]=$(sed -n '4p' ${InputCoords} | awk '{print $2}')
L[3]=$(sed -n '5p' ${InputCoords} | awk '{print $3}')

#Define rotation center
RotCenter[1]=$(echo "scale=6;${L[1]} / 2" | bc)
RotCenter[2]=$(echo "scale=6;${L[2]} / 2" | bc)
RotCenter[3]=$(echo "scale=6;${L[3]} / 2" | bc)

lo[1]=$(echo "scale=6;0-${RotCenter[1]}" | bc)
lo[2]=$(echo "scale=6;0-${RotCenter[2]}" | bc)
lo[3]=$(echo "scale=6;0-${RotCenter[3]}" | bc)
hi[1]=$(echo "scale=6;${L[1]}-${RotCenter[1]}" | bc)
hi[2]=$(echo "scale=6;${L[2]}-${RotCenter[2]}" | bc)
hi[3]=$(echo "scale=6;${L[3]}-${RotCenter[3]}" | bc)

#Define 8 vertices of the simulation box
Vertex_X[1]=${lo[1]}
Vertex_Y[1]=${lo[2]}
Vertex_Z[1]=${lo[3]}
Vertex_X[2]=${hi[1]}
Vertex_Y[2]=${lo[2]}
Vertex_Z[2]=${lo[3]}
Vertex_X[3]=${hi[1]}
Vertex_Y[3]=${lo[2]}
Vertex_Z[3]=${hi[3]}
Vertex_X[4]=${lo[1]}
Vertex_Y[4]=${lo[2]}
Vertex_Z[4]=${hi[3]}
Vertex_X[5]=${lo[1]}
Vertex_Y[5]=${hi[2]}
Vertex_Z[5]=${lo[3]}
Vertex_X[6]=${hi[1]}
Vertex_Y[6]=${hi[2]}
Vertex_Z[6]=${lo[3]}
Vertex_X[7]=${hi[1]}
Vertex_Y[7]=${hi[2]}
Vertex_Z[7]=${hi[3]}
Vertex_X[8]=${lo[1]}
Vertex_Y[8]=${hi[2]}
Vertex_Z[8]=${hi[3]}

#Define Eulerian angles, reference:J. Hirth and J. Lothe, Theory of dislocations, 1982
pi=$(echo "scale=8;a(1)*4" | bc -l)
thetaRad=$(echo "scale=6;${theta}/180*$pi " | bc -l)
phiRad=$(echo "scale=6;${phi}/180*$pi " | bc -l)
kappaRad=$(echo "scale=6;${kappa}/180*$pi " | bc -l)

for ((i=1;i<=8;i++))
do
        TVertex_X[$i]=$(echo "scale=6;(c($kappaRad)*c($phiRad)-c($thetaRad)*s($phiRad)*s($kappaRad))*${Vertex_X[$i]}+(c($kappaRad)*s($phiRad)+c($thetaRad)*s($kappaRad)*c($phiRad))*${Vertex_Y[$i]}+s($thetaRad)*s($kappaRad)*${Vertex_Z[$i]} " | bc -l)
        TVertex_Y[$i]=$(echo "scale=6;(-s($kappaRad)*c($phiRad)-c($thetaRad)*c($kappaRad)*s($phiRad))*${Vertex_X[$i]}+(-s($kappaRad)*s($phiRad)+c($thetaRad)*c($kappaRad)*c($phiRad))*${Vertex_Y[$i]}+s($thetaRad)*c($kappaRad)*${Vertex_Z[$i]} " | bc -l)
        TVertex_Z[$i]=$(echo "scale=6;s($thetaRad)*s($phiRad)*${Vertex_X[$i]}-s($thetaRad)*c($phiRad)*${Vertex_Y[$i]}+c($thetaRad)*${Vertex_Z[$i]}" | bc -l)
done

#Write header of tikzpicture
echo "\\begin{figure}[htbp]" >> $OutFile1
echo "\\centering" >> $OutFile1
echo "\\begin{tikzpicture}[scale=$scale]" >> $OutFile1

if [[ $ViewFrom = "x" ]];then
        echo "\\draw [help lines] (${TVertex_Y[2]},${TVertex_Z[2]}) -- (${TVertex_Y[6]},${TVertex_Z[6]}) -- (${TVertex_Y[7]},${TVertex_Z[7]}) -- (${TVertex_Y[3]},${TVertex_Z[3]}) -- (${TVertex_Y[2]},${TVertex_Z[2]})--(${TVertex_Y[1]},${TVertex_Z[1]})--(${TVertex_Y[5]},${TVertex_Z[5]})--(${TVertex_Y[8]},${TVertex_Z[8]})--(${TVertex_Y[4]},${TVertex_Z[4]})--(${TVertex_Y[1]},${TVertex_Z[1]});" >> $OutFile1
        echo "\\draw [help lines] (${TVertex_Y[3]},${TVertex_Z[3]}) -- (${TVertex_Y[4]},${TVertex_Z[4]});" >> $OutFile1
        echo "\\draw [help lines] (${TVertex_Y[5]},${TVertex_Z[5]}) -- (${TVertex_Y[6]},${TVertex_Z[6]});" >> $OutFile1
        echo "\\draw [help lines] (${TVertex_Y[7]},${TVertex_Z[7]}) -- (${TVertex_Y[8]},${TVertex_Z[8]});" >> $OutFile1
elif [[ $ViewFrom = "y" ]];then
	echo "\\draw [help lines] (${TVertex_X[1]},${TVertex_Z[1]}) -- (${TVertex_X[2]},${TVertex_Z[2]}) -- (${TVertex_X[3]},${TVertex_Z[3]}) -- (${TVertex_X[4]},${TVertex_Z[4]}) -- (${TVertex_X[1]},${TVertex_Z[1]})--(${TVertex_X[5]},${TVertex_Z[5]})--(${TVertex_X[6]},${TVertex_Z[6]})--(${TVertex_X[7]},${TVertex_Z[7]})--(${TVertex_X[8]},${TVertex_Z[8]})--(${TVertex_X[5]},${TVertex_Z[5]});" >> $OutFile1
	echo "\\draw [help lines] (${TVertex_X[2]},${TVertex_Z[2]}) -- (${TVertex_X[6]},${TVertex_Z[6]});" >> $OutFile1
	echo "\\draw [help lines] (${TVertex_X[3]},${TVertex_Z[3]}) -- (${TVertex_X[7]},${TVertex_Z[7]});" >> $OutFile1
	echo "\\draw [help lines] (${TVertex_X[4]},${TVertex_Z[4]}) -- (${TVertex_X[8]},${TVertex_Z[8]});" >> $OutFile1
elif [[ $ViewFrom = "z" ]];then
        echo "\\draw [help lines] (${TVertex_X[1]},${TVertex_Y[1]}) -- (${TVertex_X[2]},${TVertex_Y[2]}) -- (${TVertex_X[6]},${TVertex_Y[6]}) -- (${TVertex_X[5]},${TVertex_Y[5]}) -- (${TVertex_X[1]},${TVertex_Y[1]})--(${TVertex_X[4]},${TVertex_Y[4]})--(${TVertex_X[3]},${TVertex_Y[3]})--(${TVertex_X[7]},${TVertex_Y[7]})--(${TVertex_X[8]},${TVertex_Y[8]})--(${TVertex_X[4]},${TVertex_Y[4]});" >> $OutFile1
        echo "\\draw [help lines] (${TVertex_X[2]},${TVertex_Y[2]}) -- (${TVertex_X[3]},${TVertex_Y[3]});" >> $OutFile1
        echo "\\draw [help lines] (${TVertex_X[6]},${TVertex_Y[6]}) -- (${TVertex_X[7]},${TVertex_Y[7]});" >> $OutFile1
        echo "\\draw [help lines] (${TVertex_X[5]},${TVertex_Y[5]}) -- (${TVertex_X[8]},${TVertex_Y[8]});" >> $OutFile1
fi

#Draw atoms 
for ((i=1;i<=$Ntot;i++))
do
	j=$(echo "$i+$NHeader" | bc)
	x=$(sed -n ''$j'p' ${InputCoords} | awk '{print $1}')
	y=$(sed -n ''$j'p' ${InputCoords} | awk '{print $2}')
	z=$(sed -n ''$j'p' ${InputCoords} | awk '{print $3}')
	car[1]=$(echo "scale=6;${x}*${L[1]}-${RotCenter[1]}" | bc)
	car[2]=$(echo "scale=6;${y}*${L[2]}-${RotCenter[2]}" | bc)
	car[3]=$(echo "scale=6;${z}*${L[3]}-${RotCenter[3]}" | bc)
#Coordinate reoation based on Eulerian angles

	Tcar[1]=$(echo "scale=6;(c($kappaRad)*c($phiRad)-c($thetaRad)*s($phiRad)*s($kappaRad))*${car[1]}+(c($kappaRad)*s($phiRad)+c($thetaRad)*s($kappaRad)*c($phiRad))*${car[2]}+s($thetaRad)*s($kappaRad)*${car[3]} " | bc -l)
	Tcar[2]=$(echo "scale=6;(-s($kappaRad)*c($phiRad)-c($thetaRad)*c($kappaRad)*s($phiRad))*${car[1]}+(-s($kappaRad)*s($phiRad)+c($thetaRad)*c($kappaRad)*c($phiRad))*${car[2]}+s($thetaRad)*c($kappaRad)*${car[3]} " | bc -l)
	Tcar[3]=$(echo "scale=6;s($thetaRad)*s($phiRad)*${car[1]}-s($thetaRad)*c($phiRad)*${car[2]}+c($thetaRad)*${car[3]}" | bc -l)

	k=${ElementSpeciesIndex[$i]}
	if [[ $ViewFrom = "x" ]];then
		echo -e "\\path [fill=${ElementCol[k]}] (${Tcar[2]},${Tcar[3]}) circle [radius=${ElementRadius[k]}];" >> $OutFile1
	elif [[ $ViewFrom = "y" ]];then
		echo -e "\\path [fill=${ElementCol[k]}] (${Tcar[1]},${Tcar[3]}) circle [radius=${ElementRadius[k]}];" >> $OutFile1
	elif [[ $ViewFrom = "z" ]];then
		echo -e "\\path [fill=${ElementCol[k]}] (${Tcar[1]},${Tcar[2]}) circle [radius=${ElementRadius[k]}];" >> $OutFile1
	fi
done

echo "\\end{tikzpicture}" >> $OutFile1
echo "\\end{figure}" >> $OutFile1

###############################################
echo "Completed!Please check file: ${OutFile1}"
