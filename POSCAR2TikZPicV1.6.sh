#!/bin/sh
##################################
#Version Info
################################## 
#Any information please contact dianwuwang@163.com
#Script Description
#POSCAR2TikZPicV1.1.sh 20180314
#Generate tikzpicture, viewing from y direction
#POSCAR file must use direct coordinate
#Only for orthogonal box
#POSCAR2TikZPicV1.2.sh 20180315
#Add model rotation function according to Eulerian angles,reference: J. Hirth and J. Lothe, Theory of dislocations, 1982
#Add viewing frim x, y or z direction
#Add atom radius definition and scaling factor definition by user
#POSCAR2TikZPicV1.3.sh 20180315
#Add atom color radial shading function, so that atoms looks more like a shining sphere
#POSCAR2TikZPicV1.4.sh 20180317
#The POSCAR format is not restricted to POSCAR with selective dynamics
#Add axis indicator
#POSCAR2TikZPicV1.5.sh 20180321
#Plot mirror atoms at periodic boundary, add reference width for the output tikzpicture
#POSCAR2TikZPicV1.6.sh 20180323
#Fixed some bugs in calculating the length of the axis indicator and changed the algorithm in calculating axis indicator's position

#################################
#User defined region
#################################
#Define name of input POSCAR file, the POSCAR file must have "Direct" coordinate
POSFile="POSCAR"

#Define rotation angles, units in degrees.Reference:J. Hirth and J. Lothe, Theory of dislocations, 1982
phi=5; theta=-5;kappa=0;

#Decide viewing from which direction: "x" or "y" or "z"
ViewFrom="y"

#Define atom radius
ElementRadius[1]=0.1;ElementRadius[2]=0.1;ElementRadius[3]=0.1;ElementRadius[4]=0.1;ElementRadius[5]=0.1;ElementRadius[6]=0.1;

#Define element color, choices are: black,red,green,blue,cyan,magenta,yellow,gray,darkgray,lightgray,brown,lime,olive,orange,pink,purple,teal,violet and white. All color must be in lower case
#The order must is in line with the eleemnt order in POSCAR
#Redundunt ElementCol tag will not be used.
ElementCol[1]="black";ElementCol[2]="magenta";ElementCol[3]="red";ElementCol[4]="blue";ElementCol[5]="green";ElementCol[6]="yellow";

#Define whether to draw mirror of atoms at periodic boundary.  "TRUE" or "FALSE"
MirrorAtom="TRUE"
#If Mirroratom="TRUE", please specify the value of Deviation, which permits a deviation of the atom from its lattice site an amount "Deviation", units in Angstrom. This value is only for the purpose of drawing the atom at periodic boundary
Deviation=0.01

#Draw the axis indicator or not? "TRUE" or "FALSE"
AxisIndicator="TRUE"

#If AxisIndicator is TURE, please specify the variables below, the variables below can control the magnitude of the indicator
#ILength donotes the axis indicator reference length, the value of reference length equals to ILength*max(projected BoxSideLength in three direction after rotation) and the reference length gives the maximum length for the axis indicator in three directions
#Recommended value is ILength=0.08; 
ILength=0.08

#Define reference width of the TikZ picture, units in cm, a reference value is around RefWidth=8.3 for double column paper and RefWidth=17.6 for one column paper.
RefWidth=8.3

##################################
# Variables
##################################
InputCoords=$POSFile
OutFile1="TikZ_phi${phi}theta${theta}kappa${kappa}_${ViewFrom}.dat"

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
Var=$(sed -n '8p' ${InputCoords} | awk '{print $1}')
FirstChar=$(echo ${Var:0:1})
if [[ $FirstChar = "S" ]] || [[ $FirstChar = "s" ]];then
  NHeader=9
elif [[ $FirstChar = "D" ]] || [[ $FirstChar = "d" ]] || [[ $FirstChar = "C" ]] || [[ $FirstChar = "c" ]] ;then
  NHeader=8
fi

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

lo[1]=$(echo "scale=6;0-(${RotCenter[1]})" | bc)
lo[2]=$(echo "scale=6;0-(${RotCenter[2]})" | bc)
lo[3]=$(echo "scale=6;0-(${RotCenter[3]})" | bc)
hi[1]=$(echo "scale=6;(${L[1]})-(${RotCenter[1]})" | bc)
hi[2]=$(echo "scale=6;(${L[2]})-(${RotCenter[2]})" | bc)
hi[3]=$(echo "scale=6;(${L[3]})-(${RotCenter[3]})" | bc)

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

T11=$(echo "scale=6;(c($kappaRad))*(c($phiRad))-c($thetaRad)*(s($phiRad))*(s($kappaRad))" | bc -l)
T12=$(echo "scale=6;(c($kappaRad))*(s($phiRad))+c($thetaRad)*(s($kappaRad))*(c($phiRad))" | bc -l)
T13=$(echo "scale=6;(s($thetaRad))*(s($kappaRad))" | bc -l)
T21=$(echo "scale=6;(-s($kappaRad))*(c($phiRad))-(c($thetaRad))*(c($kappaRad))*(s($phiRad))" | bc -l)
T22=$(echo "scale=6;(-s($kappaRad))*(s($phiRad))+(c($thetaRad))*(c($kappaRad))*(c($phiRad))" | bc -l)
T23=$(echo "scale=6;(s($thetaRad))*(c($kappaRad))" | bc -l)
T31=$(echo "scale=6;(s($thetaRad))*(s($phiRad))" | bc -l)
T32=$(echo "scale=6;(-s($thetaRad))*(c($phiRad))" | bc -l)
T33=$(echo "scale=6;(c($thetaRad))" | bc -l)

TVertex_min[1]=999
TVertex_max[1]=-999
TVertex_min[2]=999
TVertex_max[2]=-999
TVertex_min[3]=999
TVertex_max[3]=-999
for ((i=1;i<=8;i++))
do
  TVertex_X[i]=$(echo "scale=6;($T11)*(${Vertex_X[$i]})+($T12)*(${Vertex_Y[$i]})+($T13)*(${Vertex_Z[$i]})" | bc -l)
  TVertex_Y[i]=$(echo "scale=6;($T21)*(${Vertex_X[$i]})+($T22)*(${Vertex_Y[$i]})+($T23)*(${Vertex_Z[$i]})" | bc -l)
  TVertex_Z[i]=$(echo "scale=6;($T31)*(${Vertex_X[$i]})+($T32)*(${Vertex_Y[$i]})+($T33)*(${Vertex_Z[$i]})" | bc -l)

  j=$(echo "${TVertex_min[1]} > ${TVertex_X[i]}" | bc)
  if [[ $j = "1" ]];then
    TVertex_min[1]=${TVertex_X[i]}
  fi

  j=$(echo "${TVertex_max[1]} < ${TVertex_X[i]}" | bc)
  if [[ $j = "1" ]];then
    TVertex_max[1]=${TVertex_X[i]}
  fi
  
  j=$(echo "${TVertex_min[2]} > ${TVertex_Y[i]}" | bc)
  if [[ $j = "1" ]];then
    TVertex_min[2]=${TVertex_Y[i]}
  fi

  j=$(echo "${TVertex_max[2]} < ${TVertex_Y[i]}" | bc)
  if [[ $j = "1" ]];then
    TVertex_max[2]=${TVertex_Y[i]}
  fi
  
  j=$(echo "${TVertex_min[3]} > ${TVertex_Z[i]}" | bc)
  if [[ $j = "1" ]];then
    TVertex_min[3]=${TVertex_Z[i]}
  fi

  j=$(echo "${TVertex_max[3]} < ${TVertex_Z[i]}" | bc)
  if [[ $j = "1" ]];then
    TVertex_max[3]=${TVertex_Z[i]}
  fi
done

#Maximum Length between the projected box vertex coordinate in x, y and z direction after rotation
VL[1]=$(echo "${TVertex_max[1]}-(${TVertex_min[1]})" | bc)
VL[2]=$(echo "${TVertex_max[2]}-(${TVertex_min[2]})" | bc)
VL[3]=$(echo "${TVertex_max[3]}-(${TVertex_min[3]})" | bc)

if [[ $AxisIndicator = "TRUE" ]];then
#Define axis indicator initial reference length
#Initially, axis indicator in three directions have the same lengths. Axis indicator initial reference length equals: max(Projected BoxLength after rotation) in certain plane times $s(the axis scale factor)
  s=$ILength
#Define the multiplier of axis indicator length, This factor "mA" places the origin of the axis indicator a distance mA*(axis length) away from the model.
  mA=3
  if [[ $ViewFrom = "x" ]];then
    flag=$(echo "${VL[2]} >= ${VL[3]}" | bc)
    if [[ $flag = "1" ]];then
      i=${VL[2]}
      AL=$(echo "scale=6;$i * ($s)" | bc)
    else
      i=${VL[3]}
      AL=$(echo "scale=6;$i * ($s)" | bc)
    fi
  elif [[ $ViewFrom = "y" ]];then
    flag=$(echo "${VL[1]} >= ${VL[3]}" | bc)
    if [[ $flag = "1" ]];then
      i=${VL[1]}
      AL=$(echo "scale=6;$i * ($s)" | bc)
    else
      i=${VL[3]}
      AL=$(echo "scale=6;$i * ($s)" | bc)
    fi
  elif [[ $ViewFrom = "z" ]];then
    flag=$(echo "${VL[1]} >= ${VL[2]}" | bc)
    if [[ $flag = "1" ]];then
      i=${VL[1]}
      AL=$(echo "scale=6;$i * ($s)" | bc)
    else
      i=${VL[2]}
      AL=$(echo "scale=6;$i * ($s)" | bc)
    fi
  fi
fi

#Write header of tikzpicture
for ((i=1;i<=$NSpecies;i++))
do
  j=${ElementCol[i]}
  if [[ $j = "red" ]] || [[ $j = "green" ]] || [[ $j = "blue" ]] || [[ $j = "cyan" ]] || [[ $j = "magenta" ]] || [[ $j = "yellow" ]] || [[ $j = "black" ]] || [[ $j = "gray" ]] || [[ $j = "darkgray" ]] || [[ $j = "lightgray" ]] || [[ $j = "brown" ]] || [[ $j = "lime" ]] || [[ $j = "olive" ]] || [[ $j = "orange" ]] || [[ $j = "pink" ]] || [[ $j = "purple" ]] || [[ $j = "teal" ]] || [[ $j = "violet" ]] || [[ $j = "white" ]] ;then
    echo "\\pgfdeclareradialshading{ballshading${j}}{\\pgfpoint{-10bp}{10bp}}{color(0bp)=(${j}!15!white); color(9bp)=(${j}!75!white);color(18bp)=(${j}!70!black); color(25bp)=(${j}!50!black);color(50bp)=(black)}" >> $OutFile1
    echo "" >> $OutFile1
  fi
done

#Compute scale factor of TikZ picture
#Define reference width of the TikZ picture, units in centimeter
MaxProjectedBoxLength=-999
for ((i=1;i<=3;i++))
do
  j=$(echo "$MaxProjectedBoxLength < ${VL[i]}" | bc)
  if [[ $j = "1" ]];then
    MaxProjectedBoxLength=${VL[i]}
    MaxDirection=$i
  fi
done

if [[ $AxisIndicator = "TRUE" ]];then
  AngstromWidth=$(echo "scale=4;$MaxProjectedBoxLength + ($AL)*$mA+($AL)" | bc)
else 
  AngstromWidth=$MaxProjectedBoxLength
fi

scale=$(echo "scale=4;$RefWidth / ($AngstromWidth)" | bc )

echo "\\begin{figure}" >> $OutFile1
echo "\\centering" >> $OutFile1
echo "\\begin{tikzpicture}[scale=$scale]" >> $OutFile1

#######################
#Draw the bounding box
#######################
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

############
#Draw atoms 
############
for ((i=1;i<=$Ntot;i++))
do
	j=$(echo "$i+$NHeader" | bc)
	x=$(sed -n ''$j'p' ${InputCoords} | awk '{print $1}')
	y=$(sed -n ''$j'p' ${InputCoords} | awk '{print $2}')
	z=$(sed -n ''$j'p' ${InputCoords} | awk '{print $3}')
	car[1]=$(echo "scale=6;(${x})*(${L[1]})-(${RotCenter[1]})" | bc)
	car[2]=$(echo "scale=6;(${y})*(${L[2]})-(${RotCenter[2]})" | bc)
	car[3]=$(echo "scale=6;(${z})*(${L[3]})-(${RotCenter[3]})" | bc)
#Coordinate reoation based on Eulerian angles
	Tcar[1]=$(echo "scale=6;($T11)*(${car[1]})+($T12)*(${car[2]})+($T13)*(${car[3]})" | bc -l)
	Tcar[2]=$(echo "scale=6;($T21)*(${car[1]})+($T22)*(${car[2]})+($T23)*(${car[3]})" | bc -l)
	Tcar[3]=$(echo "scale=6;($T31)*(${car[1]})+($T32)*(${car[2]})+($T33)*(${car[3]})" | bc -l)

	k=${ElementSpeciesIndex[$i]}
	if [[ $ViewFrom = "x" ]];then
		echo "\\pgfpathcircle{\pgfpoint{${Tcar[2]}cm}{${Tcar[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1 
		echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
		echo "\pgfusepath{}" >> $OutFile1
	elif [[ $ViewFrom = "y" ]];then
                echo "\\pgfpathcircle{\pgfpoint{${Tcar[1]}cm}{${Tcar[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                echo "\pgfusepath{}" >> $OutFile1
	elif [[ $ViewFrom = "z" ]];then
                echo "\\pgfpathcircle{\pgfpoint{${Tcar[1]}cm}{${Tcar[2]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                echo "\pgfusepath{}" >> $OutFile1
	fi

#Draw mirror atoms at periodic boundary
  if [[ $MirrorAtom = "TRUE" ]];then
	deltaXlo=$(echo "scale=6;(${car[1]})-(${lo[1]})" | bc)
        deltaXhi=$(echo "scale=6;(${car[1]})-(${hi[1]})" | bc)
        deltaYlo=$(echo "scale=6;(${car[2]})-(${lo[2]})" | bc)
        deltaYhi=$(echo "scale=6;(${car[2]})-(${hi[2]})" | bc)
        deltaZlo=$(echo "scale=6;(${car[3]})-(${lo[3]})" | bc)
        deltaZhi=$(echo "scale=6;(${car[3]})-(${hi[3]})" | bc)
        deltaXloABS=$(echo "scale=6;sqrt($deltaXlo^2)" | bc)
        deltaXhiABS=$(echo "scale=6;sqrt($deltaXhi^2)" | bc)
        deltaYloABS=$(echo "scale=6;sqrt($deltaYlo^2)" | bc)
        deltaYhiABS=$(echo "scale=6;sqrt($deltaYhi^2)" | bc)
        deltaZloABS=$(echo "scale=6;sqrt($deltaZlo^2)" | bc)
        deltaZhiABS=$(echo "scale=6;sqrt($deltaZhi^2)" | bc)

        IsXlo=$(echo "$deltaXloABS <= $Deviation" | bc)
        IsXhi=$(echo "$deltaXhiABS <= $Deviation" | bc)
        IsYlo=$(echo "$deltaYloABS <= $Deviation" | bc)
        IsYhi=$(echo "$deltaYhiABS <= $Deviation" | bc)
        IsZlo=$(echo "$deltaZloABS <= $Deviation" | bc)
        IsZhi=$(echo "$deltaZhiABS <= $Deviation" | bc)

	Dcar[1]=${car[1]}
	Dcar[2]=${car[2]}
	Dcar[3]=${car[3]}

	if [[ $IsXlo = "1" ]];then
		Dcar[1]=$(echo "scale=6;(${car[1]})+(${L[1]})" | bc)
	elif [[ $IsXhi = "1" ]];then
		Dcar[1]=$(echo "scale=6;(${car[1]})-(${L[1]})" | bc)
	fi

        if [[ $IsYlo = "1" ]];then
                Dcar[2]=$(echo "scale=6;(${car[2]})+(${L[2]})" | bc)
        elif [[ $IsYhi = "1" ]];then
                Dcar[2]=$(echo "scale=6;(${car[2]})-(${L[2]})" | bc)
        fi

        if [[ $IsZlo = "1" ]];then
                Dcar[3]=$(echo "scale=6;(${car[3]})+(${L[3]})" | bc)
        elif [[ $IsZhi = "1" ]];then
                Dcar[3]=$(echo "scale=6;(${car[3]})-(${L[3]})" | bc)
        fi

#Find equivalent position of atoms at periodic boundary
	if [[ ${Dcar[1]} = ${car[1]} ]] && [[ ${Dcar[2]} = ${car[2]} ]] && [[ ${Dcar[3]} = ${car[3]} ]];then
          NDup=0
	  continue
	elif [[ ${Dcar[1]} != ${car[1]} ]] && [[ ${Dcar[2]} = ${car[2]} ]] && [[ ${Dcar[3]} = ${car[3]} ]];then
          NDup=1
          carDup1[1]=${Dcar[1]}
          carDup1[2]=${Dcar[2]}
          carDup1[3]=${Dcar[3]}
        elif [[ ${Dcar[1]} = ${car[1]} ]] && [[ ${Dcar[2]} != ${car[2]} ]] && [[ ${Dcar[3]} = ${car[3]} ]];then
          NDup=1
          carDup1[1]=${Dcar[1]}
          carDup1[2]=${Dcar[2]}
          carDup1[3]=${Dcar[3]}
        elif [[ ${Dcar[1]} = ${car[1]} ]] && [[ ${Dcar[2]} = ${car[2]} ]] && [[ ${Dcar[3]} != ${car[3]} ]];then
          NDup=1
          carDup1[1]=${Dcar[1]}
          carDup1[2]=${Dcar[2]}
          carDup1[3]=${Dcar[3]}
        elif [[ ${Dcar[1]} != ${car[1]} ]] && [[ ${Dcar[2]} != ${car[2]} ]] && [[ ${Dcar[3]} = ${car[3]} ]];then
          NDup=3
          carDup1[1]=${car[1]}
          carDup1[2]=${Dcar[2]}
          carDup1[3]=${Dcar[3]}
          carDup2[1]=${Dcar[1]}
          carDup2[2]=${car[2]}
          carDup2[3]=${Dcar[3]}
          carDup3[1]=${Dcar[1]}
          carDup3[2]=${Dcar[2]}
          carDup3[3]=${Dcar[3]}
        elif [[ ${Dcar[1]} = ${car[1]} ]] && [[ ${Dcar[2]} != ${car[2]} ]] && [[ ${Dcar[3]} != ${car[3]} ]];then
          NDup=3
          carDup1[1]=${Dcar[1]}
          carDup1[2]=${car[2]}
          carDup1[3]=${Dcar[3]}
          carDup2[1]=${Dcar[1]}
          carDup2[2]=${Dcar[2]}
          carDup2[3]=${car[3]}
          carDup3[1]=${Dcar[1]}
          carDup3[2]=${Dcar[2]}
          carDup3[3]=${Dcar[3]}
        elif [[ ${Dcar[1]} != ${car[1]} ]] && [[ ${Dcar[2]} = ${car[2]} ]] && [[ ${Dcar[3]} != ${car[3]} ]];then
          NDup=3
          carDup1[1]=${car[1]}
          carDup1[2]=${Dcar[2]}
          carDup1[3]=${Dcar[3]}
          carDup2[1]=${Dcar[1]}
          carDup2[2]=${Dcar[2]}
          carDup2[3]=${car[3]}
          carDup3[1]=${Dcar[1]}
          carDup3[2]=${Dcar[2]}
          carDup3[3]=${Dcar[3]}
        elif [[ ${Dcar[1]} != ${car[1]} ]] && [[ ${Dcar[2]} != ${car[2]} ]] && [[ ${Dcar[3]} != ${car[3]} ]];then
          NDup=7
          carDup1[1]=${car[1]}
          carDup1[2]=${Dcar[2]}
          carDup1[3]=${Dcar[3]}
          carDup2[1]=${Dcar[1]}
          carDup2[2]=${car[2]}
          carDup2[3]=${Dcar[3]}
          carDup3[1]=${Dcar[1]}
          carDup3[2]=${Dcar[2]}
          carDup3[3]=${car[3]}
          carDup4[1]=${car[1]}
          carDup4[2]=${car[2]}
          carDup4[3]=${Dcar[3]}
          carDup5[1]=${Dcar[1]}
          carDup5[2]=${car[2]}
          carDup5[3]=${car[3]}
          carDup6[1]=${car[1]}
          carDup6[2]=${Dcar[2]}
          carDup6[3]=${car[3]}
          carDup7[1]=${Dcar[1]}
          carDup7[2]=${Dcar[2]}
          carDup7[3]=${Dcar[3]}
        fi

        if [[ $NDup = "1" ]];then
          TcarDup1[1]=$(echo "scale=6;($T11)*(${carDup1[1]})+($T12)*(${carDup1[2]})+($T13)*(${carDup1[3]})" | bc -l)
          TcarDup1[2]=$(echo "scale=6;($T21)*(${carDup1[1]})+($T22)*(${carDup1[2]})+($T23)*(${carDup1[3]})" | bc -l)
          TcarDup1[3]=$(echo "scale=6;($T31)*(${carDup1[1]})+($T32)*(${carDup1[2]})+($T33)*(${carDup1[3]})" | bc -l)
         
          if [[ $ViewFrom = "x" ]];then
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup1[2]}cm}{${TcarDup1[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
          elif [[ $ViewFrom = "y" ]];then
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup1[1]}cm}{${TcarDup1[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
          elif [[ $ViewFrom = "z" ]];then
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup1[1]}cm}{${TcarDup1[2]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
          fi
        elif [[ $NDup = "3" ]];then
          TcarDup1[1]=$(echo "scale=6;($T11)*(${carDup1[1]})+($T12)*(${carDup1[2]})+($T13)*(${carDup1[3]})" | bc -l)
          TcarDup1[2]=$(echo "scale=6;($T21)*(${carDup1[1]})+($T22)*(${carDup1[2]})+($T23)*(${carDup1[3]})" | bc -l)
          TcarDup1[3]=$(echo "scale=6;($T31)*(${carDup1[1]})+($T32)*(${carDup1[2]})+($T33)*(${carDup1[3]})" | bc -l)
          TcarDup2[1]=$(echo "scale=6;($T11)*(${carDup2[1]})+($T12)*(${carDup2[2]})+($T13)*(${carDup2[3]})" | bc -l)
          TcarDup2[2]=$(echo "scale=6;($T21)*(${carDup2[1]})+($T22)*(${carDup2[2]})+($T23)*(${carDup2[3]})" | bc -l)
          TcarDup2[3]=$(echo "scale=6;($T31)*(${carDup2[1]})+($T32)*(${carDup2[2]})+($T33)*(${carDup2[3]})" | bc -l)
          TcarDup3[1]=$(echo "scale=6;($T11)*(${carDup3[1]})+($T12)*(${carDup3[2]})+($T13)*(${carDup3[3]})" | bc -l)
          TcarDup3[2]=$(echo "scale=6;($T21)*(${carDup3[1]})+($T22)*(${carDup3[2]})+($T23)*(${carDup3[3]})" | bc -l)
          TcarDup3[3]=$(echo "scale=6;($T31)*(${carDup3[1]})+($T32)*(${carDup3[2]})+($T33)*(${carDup3[3]})" | bc -l)

          if [[ $ViewFrom = "x" ]];then
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup1[2]}cm}{${TcarDup1[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup2[2]}cm}{${TcarDup2[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup3[2]}cm}{${TcarDup3[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
          elif [[ $ViewFrom = "y" ]];then
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup1[1]}cm}{${TcarDup1[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup2[1]}cm}{${TcarDup2[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup3[1]}cm}{${TcarDup3[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
          elif [[ $ViewFrom = "z" ]];then
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup1[1]}cm}{${TcarDup1[2]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup2[1]}cm}{${TcarDup2[2]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup3[1]}cm}{${TcarDup3[2]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
          fi
        elif [[ $NDup = "7" ]];then
          TcarDup1[1]=$(echo "scale=6;($T11)*(${carDup1[1]})+($T12)*(${carDup1[2]})+($T13)*(${carDup1[3]})" | bc -l)
          TcarDup1[2]=$(echo "scale=6;($T21)*(${carDup1[1]})+($T22)*(${carDup1[2]})+($T23)*(${carDup1[3]})" | bc -l)
          TcarDup1[3]=$(echo "scale=6;($T31)*(${carDup1[1]})+($T32)*(${carDup1[2]})+($T33)*(${carDup1[3]})" | bc -l)
          TcarDup2[1]=$(echo "scale=6;($T11)*(${carDup2[1]})+($T12)*(${carDup2[2]})+($T13)*(${carDup2[3]})" | bc -l)
          TcarDup2[2]=$(echo "scale=6;($T21)*(${carDup2[1]})+($T22)*(${carDup2[2]})+($T23)*(${carDup2[3]})" | bc -l)
          TcarDup2[3]=$(echo "scale=6;($T31)*(${carDup2[1]})+($T32)*(${carDup2[2]})+($T33)*(${carDup2[3]})" | bc -l)
          TcarDup3[1]=$(echo "scale=6;($T11)*(${carDup3[1]})+($T12)*(${carDup3[2]})+($T13)*(${carDup3[3]})" | bc -l)
          TcarDup3[2]=$(echo "scale=6;($T21)*(${carDup3[1]})+($T22)*(${carDup3[2]})+($T23)*(${carDup3[3]})" | bc -l)
          TcarDup3[3]=$(echo "scale=6;($T31)*(${carDup3[1]})+($T32)*(${carDup3[2]})+($T33)*(${carDup3[3]})" | bc -l)
          TcarDup4[1]=$(echo "scale=6;($T11)*(${carDup4[1]})+($T12)*(${carDup4[2]})+($T13)*(${carDup4[3]})" | bc -l)
          TcarDup4[2]=$(echo "scale=6;($T21)*(${carDup4[1]})+($T22)*(${carDup4[2]})+($T23)*(${carDup4[3]})" | bc -l)
          TcarDup4[3]=$(echo "scale=6;($T31)*(${carDup4[1]})+($T32)*(${carDup4[2]})+($T33)*(${carDup4[3]})" | bc -l)
          TcarDup5[1]=$(echo "scale=6;($T11)*(${carDup5[1]})+($T12)*(${carDup5[2]})+($T13)*(${carDup5[3]})" | bc -l)
          TcarDup5[2]=$(echo "scale=6;($T21)*(${carDup5[1]})+($T22)*(${carDup5[2]})+($T23)*(${carDup5[3]})" | bc -l)
          TcarDup5[3]=$(echo "scale=6;($T31)*(${carDup5[1]})+($T32)*(${carDup5[2]})+($T33)*(${carDup5[3]})" | bc -l)
          TcarDup6[1]=$(echo "scale=6;($T11)*(${carDup6[1]})+($T12)*(${carDup6[2]})+($T13)*(${carDup6[3]})" | bc -l)
          TcarDup6[2]=$(echo "scale=6;($T21)*(${carDup6[1]})+($T22)*(${carDup6[2]})+($T23)*(${carDup6[3]})" | bc -l)
          TcarDup6[3]=$(echo "scale=6;($T31)*(${carDup6[1]})+($T32)*(${carDup6[2]})+($T33)*(${carDup6[3]})" | bc -l)
          TcarDup7[1]=$(echo "scale=6;($T11)*(${carDup7[1]})+($T12)*(${carDup7[2]})+($T13)*(${carDup7[3]})" | bc -l)
          TcarDup7[2]=$(echo "scale=6;($T21)*(${carDup7[1]})+($T22)*(${carDup7[2]})+($T23)*(${carDup7[3]})" | bc -l)
          TcarDup7[3]=$(echo "scale=6;($T31)*(${carDup7[1]})+($T32)*(${carDup7[2]})+($T33)*(${carDup7[3]})" | bc -l)

          if [[ $ViewFrom = "x" ]];then
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup1[2]}cm}{${TcarDup1[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup2[2]}cm}{${TcarDup2[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup3[2]}cm}{${TcarDup3[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup4[2]}cm}{${TcarDup4[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup5[2]}cm}{${TcarDup5[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup6[2]}cm}{${TcarDup6[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup7[2]}cm}{${TcarDup7[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
          elif [[ $ViewFrom = "y" ]];then
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup1[1]}cm}{${TcarDup1[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup2[1]}cm}{${TcarDup2[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup3[1]}cm}{${TcarDup3[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup4[1]}cm}{${TcarDup4[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup5[1]}cm}{${TcarDup5[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup6[1]}cm}{${TcarDup6[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup7[1]}cm}{${TcarDup7[3]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
          elif [[ $ViewFrom = "z" ]];then
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup1[1]}cm}{${TcarDup1[2]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup2[1]}cm}{${TcarDup2[2]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup3[1]}cm}{${TcarDup3[2]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup4[1]}cm}{${TcarDup4[2]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup5[1]}cm}{${TcarDup5[2]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup6[1]}cm}{${TcarDup6[2]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
                  echo "\\pgfpathcircle{\pgfpoint{${TcarDup7[1]}cm}{${TcarDup7[2]}cm}}{${ElementRadius[k]}cm}" >> $OutFile1
                  echo "\\pgfshadepath{ballshading${ElementCol[k]}}{0}" >> $OutFile1
                  echo "\pgfusepath{}" >> $OutFile1
          fi
	fi	
  fi
#printf "Processing... %6.2f %% \r" $(echo "scale=6;($i)/($Ntot)*100" | bc)
done

####################
#Add axis indicator
####################
#First put axis indicator in the rotation center, then rotate the axis indicator according to Eulerian angles
#Then displace the axis indicator to desiginated position according to a specific displacement, usually it is placed in the bottom-right of the figure.
if [[ $AxisIndicator = "TRUE" ]];then
#position of the axis indicator origin, note that the axis indicator origin is at the rotation center
  AO[1]=0
  AO[2]=0
  AO[3]=0
  #position of the indicator end point
  AX[1]=$AL
  AX[2]=0
  AX[3]=0
  AY[1]=0
  AY[2]=$AL
  AY[3]=0
  AZ[1]=0 
  AZ[2]=0
  AZ[3]=$AL

#rotate the indicator end point according to Eulerian angles, note that the items which equals to zero is removed from the equation.
  TAX[1]=$(echo "scale=6;$T11*(${AX[1]})" | bc -l)
  TAX[2]=$(echo "scale=6;$T21*(${AX[1]})" | bc -l)
  TAX[3]=$(echo "scale=6;$T31*(${AX[1]})" | bc -l)
  TAY[1]=$(echo "scale=6;$T12*(${AY[2]})" | bc -l)
  TAY[2]=$(echo "scale=6;$T22*(${AY[2]})" | bc -l)
  TAY[3]=$(echo "scale=6;$T32*(${AY[2]})" | bc -l)
  TAZ[1]=$(echo "scale=6;$T13*(${AZ[3]})" | bc -l)
  TAZ[2]=$(echo "scale=6;$T23*(${AZ[3]})" | bc -l)
  TAZ[3]=$(echo "scale=6;$T33*(${AZ[3]})" | bc -l)

#Adjust the indicator length in each direction
#First find out in which direction the indicator has the largest length, then readjust the other two indicators to have the same largest length
  if [[ $ViewFrom = "x" ]];then
    AL_TAY=$(echo " scale=6;sqrt((${TAY[2]})^2+(${TAY[3]})^2)" | bc)
    AL_TAZ=$(echo " scale=6;sqrt((${TAZ[2]})^2+(${TAZ[3]})^2)" | bc)

	flag=$(echo "$AL_TAY >= $AL_TAZ" | bc)
    if [[ $flag = "1" ]];then
      if [[ ${T21} = 0 ]] && [[ ${T31} = 0 ]];then
        AX[1]=0
      elif [[ ${T21} != 0 ]] && [[ ${T31} != 0 ]];then
        AX[1]=$(echo "scale=6;$AL_TAY / sqrt(${T21}^2+(${T31})^2)" | bc -l)
      fi
      TAX[2]=$(echo "scale=6;$T21*(${AX[1]})" | bc -l)
      TAX[3]=$(echo "scale=6;$T31*(${AX[1]})" | bc -l)

      if [[ ${T23} != 0 ]] && [[ ${T33} != 0 ]];then
        AZ[3]=$(echo "scale=6;$AL_TAY / sqrt(${T23}^2+(${T33})^2)" | bc -l)
      fi  	
      TAZ[2]=$(echo "scale=6;$T23*(${AZ[3]})" | bc -l)
      TAZ[3]=$(echo "scale=6;$T33*(${AZ[3]})" | bc -l)
    else
      if [[ ${T21} = 0 ]] && [[ ${T31} = 0 ]];then
        AX[1]=0
      elif [[ ${T21} != 0 ]] && [[ ${T31} != 0 ]];then
        AX[1]=$(echo "scale=6;$AL_TAZ / sqrt(${T21}^2+(${T31})^2)" | bc -l)
      fi
      TAX[2]=$(echo "scale=6;$T21*(${AX[1]})" | bc -l)
      TAX[3]=$(echo "scale=6;$T31*(${AX[1]})" | bc -l)

      if [[ ${T22} != 0 ]] && [[ ${T32} != 0 ]];then  	
        AY[2]=$(echo "scale=6;$AL_TAZ / sqrt(${T22}^2+(${T32})^2)" | bc -l)
      fi
      TAY[2]=$(echo "scale=6;$T22*(${AY[2]})" | bc -l)
      TAY[3]=$(echo "scale=6;$T32*(${AY[2]})" | bc -l)
    fi 
  elif [[ $ViewFrom = "y" ]];then
    AL_TAX=$(echo " scale=6;sqrt(${TAX[1]}^2+(${TAX[3]})^2)" | bc)
    AL_TAZ=$(echo " scale=6;sqrt(${TAZ[1]}^2+(${TAZ[3]})^2)" | bc)

	flag=$(echo "$AL_TAX >= $AL_TAZ" | bc)
    if [[ $flag = "1" ]];then
      if [[ ${T12} = 0 ]] && [[ ${T32} = 0 ]];then
        AY[2]=0
      elif [[ ${T12} != 0 ]] && [[ ${T32} != 0 ]];then
        AY[2]=$(echo "scale=6;$AL_TAX / sqrt(${T12}^2+(${T32})^2)" | bc -l)
      fi
      TAY[1]=$(echo "scale=6;$T12*(${AY[2]})" | bc -l)
      TAY[3]=$(echo "scale=6;$T32*(${AY[2]})" | bc -l)

      if [[ ${T13} != 0 ]] && [[ ${T33} != 0 ]];then
        AZ[3]=$(echo "scale=6;$AL_TAX / sqrt(${T13}^2+(${T33})^2)" | bc -l)
      fi
      TAZ[1]=$(echo "scale=6;$T13*(${AZ[3]})" | bc -l)
      TAZ[3]=$(echo "scale=6;$T33*(${AZ[3]})" | bc -l)
    else
      if [[ ${T12} = 0 ]] && [[ ${T32} = 0 ]];then
        AY[2]=0
      elif [[ ${T12} != 0 ]] && [[ ${T32} != 0 ]];then
        AY[2]=$(echo "scale=6;$AL_TAZ / sqrt(${T12}^2+(${T32})^2)" | bc -l)
      fi
      TAY[1]=$(echo "scale=6;$T12*(${AY[2]})" | bc -l)
      TAY[3]=$(echo "scale=6;$T32*(${AY[2]})" | bc -l)

      if [[ ${T11} != 0 ]] && [[ ${T31} != 0 ]];then
        AX[1]=$(echo "scale=6;$AL_TAZ / sqrt(${T11}^2+(${T31})^2)" | bc -l)
      fi
      TAX[1]=$(echo "scale=6;$T11*(${AX[1]})" | bc -l)
      TAX[3]=$(echo "scale=6;$T31*(${AX[1]})" | bc -l)
    fi 
  elif [[ $ViewFrom = "z" ]];then
    AL_TAX=$(echo " scale=6;sqrt(${TAX[1]}^2+(${TAX[2]})^2)" | bc)
    AL_TAY=$(echo " scale=6;sqrt(${TAY[1]}^2+(${TAY[2]})^2)" | bc)
  
    flag=$(echo "$AL_TAX >= $AL_TAY" | bc)
    if [[ $flag = "1" ]];then
      if [[ ${T13} = 0 ]] && [[ ${T23} = 0 ]];then
        AZ[3]=0
      elif [[ ${T13} != 0 ]] && [[ ${T23} != 0 ]];then
        AZ[3]=$(echo "scale=6;$AL_TAX / sqrt(${T13}^2+(${T23})^2)" | bc -l)
      fi
      TAZ[1]=$(echo "scale=6;$T13*(${AZ[3]})" | bc -l)
      TAZ[2]=$(echo "scale=6;$T23*(${AZ[3]})" | bc -l)
  	
      if [[ ${T12} != 0 ]] && [[ ${T22} != 0 ]];then
        AY[2]=$(echo "scale=6;$AL_TAX / sqrt(${T12}^2+(${T22})^2)" | bc -l)
      fi
      TAY[1]=$(echo "scale=6;$T12*(${AY[2]})" | bc -l)
      TAY[2]=$(echo "scale=6;$T22*(${AY[2]})" | bc -l)
    else
      if [[ ${T13} = 0 ]] && [[ ${T23} != 0 ]];then
        AZ[3]=0
      elif [[ ${T13} != 0 ]] && [[ ${T23} != 0 ]];then
        AZ[3]=$(echo "scale=6;$AL_TAY / sqrt(${T13}^2+(${T23})^2)" | bc -l)
      fi
      TAZ[1]=$(echo "scale=6;$T13*(${AZ[3]})" | bc -l)
      TAZ[2]=$(echo "scale=6;$T23*(${AZ[3]})" | bc -l)
  	
      if [[ ${T11} != 0 ]] && [[ ${T21} != 0 ]];then
        AX[1]=$(echo "scale=6;$AL_TAY / sqrt(${T11}^2+(${T21})^2)" | bc -l)
      fi
      TAX[1]=$(echo "scale=6;$T11*(${AX[1]})" | bc -l)
      TAX[2]=$(echo "scale=6;$T21*(${AX[1]})" | bc -l)
    fi 
  fi

  #Displace the axis indicator
  if [[ $ViewFrom = "x" ]];then
    AOShift[2]=$(echo "scale=6;${AO[2]}+(${TVertex_max[2]})+($AL)*$mA" | bc)
    AOShift[3]=$(echo "scale=6;${AO[3]}-(${TVertex_max[3]})" | bc) 
    TAXShift[2]=$(echo "scale=6;${TAX[2]}+(${TVertex_max[2]})+($AL)*$mA" | bc) 
    TAXShift[3]=$(echo "scale=6;${TAX[3]}-(${TVertex_max[3]})" | bc) 
    TAYShift[2]=$(echo "scale=6;${TAY[2]}+(${TVertex_max[2]})+($AL)*$mA" | bc) 
    TAYShift[3]=$(echo "scale=6;${TAY[3]}-(${TVertex_max[3]})" | bc) 
    TAZShift[2]=$(echo "scale=6;${TAZ[2]}+(${TVertex_max[2]})+($AL)*$mA" | bc) 
    TAZShift[3]=$(echo "scale=6;${TAZ[3]}-(${TVertex_max[3]})" | bc) 

    if [[ ${TAX[2]} != 0 ]] && [[ ${TAX[3]} != 0 ]];then
      echo "\\draw [->] (${AOShift[2]},${AOShift[3]})--(${TAXShift[2]},${TAXShift[3]});" >> $OutFile1
      echo "\\node [right] at (${TAXShift[2]},${TAXShift[3]}) {x};" >> $OutFile1
    elif [[ `echo "${TAX[2]} < 0" | bc` -eq 1 ]] && [[ ${TAX[3]} = 0 ]];then
      echo "\\draw [->] (${AOShift[2]},${AOShift[3]})--(${TAXShift[2]},${TAXShift[3]});" >> $OutFile1
      echo "\\node [left] at (${TAXShift[2]},${TAXShift[3]}) {x};" >> $OutFile1
    elif [[ `echo "${TAX[2]} > 0" | bc` -eq 1 ]] && [[ ${TAX[3]} = 0 ]];then
      echo "\\draw [->] (${AOShift[2]},${AOShift[3]})--(${TAXShift[2]},${TAXShift[3]});" >> $OutFile1
      echo "\\node [right] at (${TAXShift[2]},${TAXShift[3]}) {x};" >> $OutFile1
    elif [[ ${TAX[2]} = 0 ]] && [[ `echo "${TAX[3]} < 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[2]},${AOShift[3]})--(${TAXShift[2]},${TAXShift[3]});" >> $OutFile1
      echo "\\node [below] at (${TAXShift[2]},${TAXShift[3]}) {x};" >> $OutFile1
    elif [[ ${TAX[2]} = 0 ]] && [[ `echo "${TAX[3]} > 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[2]},${AOShift[3]})--(${TAXShift[2]},${TAXShift[3]});" >> $OutFile1
      echo "\\node [above] at (${TAXShift[2]},${TAXShift[3]}) {x};" >> $OutFile1
    elif [[ ${TAX[2]} = 0 ]] && [[ ${TAX[3]} = 0 ]];then
      echo "\\draw [-] (${AOShift[2]},${AOShift[3]})--(${TAXShift[2]},${TAXShift[3]});" >> $OutFile1
      echo "\\node [below] at (${TAXShift[2]},${TAXShift[3]}) {x};" >> $OutFile1
    fi

    if [[ ${TAY[2]} != 0 ]] && [[ ${TAY[3]} != 0 ]];then
      echo "\\draw [->] (${AOShift[2]},${AOShift[3]})--(${TAYShift[2]},${TAYShift[3]});" >> $OutFile1
      echo "\\node [right] at (${TAYShift[2]},${TAYShift[3]}) {y};" >> $OutFile1
    elif [[ `echo "${TAY[2]} < 0" | bc` -eq 1 ]] && [[ ${TAY[3]} = 0 ]];then
      echo "\\draw [->] (${AOShift[2]},${AOShift[3]})--(${TAYShift[2]},${TAYShift[3]});" >> $OutFile1
      echo "\\node [left] at (${TAYShift[2]},${TAYShift[3]}) {y};" >> $OutFile1
    elif [[ `echo "${TAY[2]} > 0" | bc` -eq 1 ]] && [[ ${TAY[3]} = 0 ]];then
      echo "\\draw [->] (${AOShift[2]},${AOShift[3]})--(${TAYShift[2]},${TAYShift[3]});" >> $OutFile1
      echo "\\node [right] at (${TAYShift[2]},${TAYShift[3]}) {y};" >> $OutFile1
    elif [[ ${TAY[2]} = 0 ]] && [[ `echo "${TAY[3]} < 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[2]},${AOShift[3]})--(${TAYShift[2]},${TAYShift[3]});" >> $OutFile1
      echo "\\node [below] at (${TAYShift[2]},${TAYShift[3]}) {y};" >> $OutFile1
    elif [[ ${TAY[2]} = 0 ]] && [[ `echo "${TAY[3]} > 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[2]},${AOShift[3]})--(${TAYShift[2]},${TAYShift[3]});" >> $OutFile1
      echo "\\node [above] at (${TAYShift[2]},${TAYShift[3]}) {y};" >> $OutFile1
    elif [[ ${TAY[2]} = 0 ]] && [[ ${TAY[3]} = 0 ]];then
      echo "\\draw [-] (${AOShift[2]},${AOShift[3]})--(${TAYShift[2]},${TAYShift[3]});" >> $OutFile1
      echo "\\node [below] at (${TAYShift[2]},${TAYShift[3]}) {y};" >> $OutFile1
    fi

    if [[ ${TAZ[2]} != 0 ]] && [[ ${TAZ[3]} != 0 ]];then
      echo "\\draw [->] (${AOShift[2]},${AOShift[3]})--(${TAZShift[2]},${TAZShift[3]});" >> $OutFile1
      echo "\\node [right] at (${TAZShift[2]},${TAZShift[3]}) {z};" >> $OutFile1
    elif [[ `echo "${TAZ[2]} < 0" | bc` -eq 1 ]] && [[ ${TAZ[3]} = 0 ]];then
      echo "\\draw [->] (${AOShift[2]},${AOShift[3]})--(${TAZShift[2]},${TAZShift[3]});" >> $OutFile1
      echo "\\node [left] at (${TAZShift[2]},${TAZShift[3]}) {z};" >> $OutFile1
    elif [[ `echo "${TAZ[2]} > 0" | bc` -eq 1 ]] && [[ ${TAZ[3]} = 0 ]];then
      echo "\\draw [->] (${AOShift[2]},${AOShift[3]})--(${TAZShift[2]},${TAZShift[3]});" >> $OutFile1
      echo "\\node [right] at (${TAZShift[2]},${TAZShift[3]}) {z};" >> $OutFile1
    elif [[ ${TAZ[2]} = 0 ]] && [[ `echo "${TAZ[3]} < 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[2]},${AOShift[3]})--(${TAZShift[2]},${TAZShift[3]});" >> $OutFile1
      echo "\\node [below] at (${TAZShift[2]},${TAZShift[3]}) {z};" >> $OutFile1
    elif [[ ${TAZ[2]} = 0 ]] && [[ `echo "${TAZ[3]} > 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[2]},${AOShift[3]})--(${TAZShift[2]},${TAZShift[3]});" >> $OutFile1
      echo "\\node [above] at (${TAZShift[2]},${TAZShift[3]}) {z};" >> $OutFile1
    elif [[ ${TAZ[2]} = 0 ]] && [[ ${TAZ[3]} = 0 ]];then
      echo "\\draw [-] (${AOShift[2]},${AOShift[3]})--(${TAZShift[2]},${TAZShift[3]});" >> $OutFile1
      echo "\\node [below] at (${TAZShift[2]},${TAZShift[3]}) {z};" >> $OutFile1
    fi
  elif [[ $ViewFrom = "y" ]];then
    AOShift[1]=$(echo "scale=6;${AO[1]}+(${TVertex_max[1]})+($AL)*$mA" | bc)
    AOShift[3]=$(echo "scale=6;${AO[3]}-(${TVertex_max[3]})" | bc)
    TAXShift[1]=$(echo "scale=6;${TAX[1]}+(${TVertex_max[1]})+($AL)*$mA" | bc)
    TAXShift[3]=$(echo "scale=6;${TAX[3]}-(${TVertex_max[3]})" | bc)
    TAYShift[1]=$(echo "scale=6;${TAY[1]}+(${TVertex_max[1]})+($AL)*$mA" | bc)
    TAYShift[3]=$(echo "scale=6;${TAY[3]}-(${TVertex_max[3]})" | bc)
    TAZShift[1]=$(echo "scale=6;${TAZ[1]}+(${TVertex_max[1]})+($AL)*$mA" | bc)
    TAZShift[3]=$(echo "scale=6;${TAZ[3]}-(${TVertex_max[3]})" | bc)
	
   if [[ ${TAX[1]} != 0 ]] && [[ ${TAX[3]} != 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[3]})--(${TAXShift[1]},${TAXShift[3]});" >> $OutFile1
      echo "\\node [right] at (${TAXShift[1]},${TAXShift[3]}) {x};" >> $OutFile1
    elif [[ `echo "${TAX[1]} < 0" | bc` -eq 1 ]] && [[ ${TAX[3]} = 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[3]})--(${TAXShift[1]},${TAXShift[3]});" >> $OutFile1
      echo "\\node [left] at (${TAXShift[1]},${TAXShift[3]}) {x};" >> $OutFile1
    elif [[ `echo "${TAX[1]} > 0" | bc` -eq 1 ]] && [[ ${TAX[3]} = 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[3]})--(${TAXShift[1]},${TAXShift[3]});" >> $OutFile1
      echo "\\node [right] at (${TAXShift[1]},${TAXShift[3]}) {x};" >> $OutFile1
    elif [[ ${TAX[1]} = 0 ]] && [[ `echo "${TAX[3]} < 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[3]})--(${TAXShift[1]},${TAXShift[3]});" >> $OutFile1
      echo "\\node [below] at (${TAXShift[1]},${TAXShift[3]}) {x};" >> $OutFile1
    elif [[ ${TAX[1]} = 0 ]] && [[ `echo "${TAX[3]} > 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[3]})--(${TAXShift[1]},${TAXShift[3]});" >> $OutFile1
      echo "\\node [above] at (${TAXShift[1]},${TAXShift[3]}) {x};" >> $OutFile1
    elif [[ ${TAX[1]} = 0 ]] && [[ ${TAX[3]} = 0 ]];then
      echo "\\draw [-] (${AOShift[1]},${AOShift[3]})--(${TAXShift[1]},${TAXShift[3]});" >> $OutFile1
      echo "\\node [below] at (${TAXShift[1]},${TAXShift[3]}) {x};" >> $OutFile1
    fi
	
    if [[ ${TAY[1]} != 0 ]] && [[ ${TAY[3]} != 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[3]})--(${TAYShift[1]},${TAYShift[3]});" >> $OutFile1
      echo "\\node [right] at (${TAYShift[1]},${TAYShift[3]}) {y};" >> $OutFile1
    elif [[ `echo "${TAY[1]} < 0" | bc` -eq 1 ]] && [[ ${TAY[3]} = 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[3]})--(${TAYShift[1]},${TAYShift[3]});" >> $OutFile1
      echo "\\node [left] at (${TAYShift[1]},${TAYShift[3]}) {y};" >> $OutFile1
    elif [[ `echo "${TAY[1]} > 0" | bc` -eq 1 ]] && [[ ${TAY[3]} = 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[3]})--(${TAYShift[1]},${TAYShift[3]});" >> $OutFile1
      echo "\\node [right] at (${TAYShift[1]},${TAYShift[3]}) {y};" >> $OutFile1
    elif [[ ${TAY[1]} = 0 ]] && [[ `echo "${TAY[3]} < 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[3]})--(${TAYShift[1]},${TAYShift[3]});" >> $OutFile1
      echo "\\node [below] at (${TAYShift[1]},${TAYShift[3]}) {y};" >> $OutFile1
    elif [[ ${TAY[1]} = 0 ]] && [[ `echo "${TAY[3]} > 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[3]})--(${TAYShift[1]},${TAYShift[3]});" >> $OutFile1
      echo "\\node [above] at (${TAYShift[1]},${TAYShift[3]}) {y};" >> $OutFile1
    elif [[ ${TAY[1]} = 0 ]] && [[ ${TAY[3]} = 0 ]];then
      echo "\\draw [-] (${AOShift[1]},${AOShift[3]})--(${TAYShift[1]},${TAYShift[3]});" >> $OutFile1
      echo "\\node [below] at (${TAYShift[1]},${TAYShift[3]}) {y};" >> $OutFile1
    fi

    if [[ ${TAZ[1]} != 0 ]] && [[ ${TAZ[3]} != 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[3]})--(${TAZShift[1]},${TAZShift[3]});" >> $OutFile1
      echo "\\node [right] at (${TAZShift[1]},${TAZShift[3]}) {z};" >> $OutFile1
    elif [[ `echo "${TAZ[1]} < 0" | bc` -eq 1 ]] && [[ ${TAZ[3]} = 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[3]})--(${TAZShift[1]},${TAZShift[3]});" >> $OutFile1
      echo "\\node [left] at (${TAZShift[1]},${TAZShift[3]}) {z};" >> $OutFile1
    elif [[ `echo "${TAZ[1]} > 0" | bc` -eq 1 ]] && [[ ${TAZ[3]} = 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[3]})--(${TAZShift[1]},${TAZShift[3]});" >> $OutFile1
      echo "\\node [right] at (${TAZShift[1]},${TAZShift[3]}) {z};" >> $OutFile1
    elif [[ ${TAZ[1]} = 0 ]] && [[ `echo "${TAZ[3]} < 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[3]})--(${TAZShift[1]},${TAZShift[3]});" >> $OutFile1
      echo "\\node [below] at (${TAZShift[1]},${TAZShift[3]}) {z};" >> $OutFile1
    elif [[ ${TAZ[1]} = 0 ]] && [[ `echo "${TAZ[3]} > 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[3]})--(${TAZShift[1]},${TAZShift[3]});" >> $OutFile1
      echo "\\node [above] at (${TAZShift[1]},${TAZShift[3]}) {z};" >> $OutFile1
    elif [[ ${TAZ[1]} = 0 ]] && [[ ${TAZ[3]} = 0 ]];then
      echo "\\draw [-] (${AOShift[1]},${AOShift[3]})--(${TAZShift[1]},${TAZShift[3]});" >> $OutFile1
      echo "\\node [below] at (${TAZShift[1]},${TAZShift[3]}) {z};" >> $OutFile1
    fi
  elif [[ $ViewFrom = "z" ]];then
    AOShift[1]=$(echo "scale=6;${AO[1]}+(${TVertex_max[1]})+($AL)*$mA" | bc)
    AOShift[2]=$(echo "scale=6;${AO[2]}-(${TVertex_max[2]})" | bc)
    TAXShift[1]=$(echo "scale=6;${TAX[1]}+(${TVertex_max[1]})+($AL)*$mA" | bc)
    TAXShift[2]=$(echo "scale=6;${TAX[2]}-(${TVertex_max[2]})" | bc)
    TAYShift[1]=$(echo "scale=6;${TAY[1]}+(${TVertex_max[1]})+($AL)*$mA" | bc)
    TAYShift[2]=$(echo "scale=6;${TAY[2]}-(${TVertex_max[2]})" | bc)
    TAZShift[1]=$(echo "scale=6;${TAZ[1]}+(${TVertex_max[1]})+($AL)*$mA" | bc)
    TAZShift[2]=$(echo "scale=6;${TAZ[2]}-(${TVertex_max[2]})" | bc)
   if [[ ${TAX[1]} != 0 ]] && [[ ${TAX[2]} != 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[2]})--(${TAXShift[1]},${TAXShift[2]});" >> $OutFile1
      echo "\\node [right] at (${TAXShift[1]},${TAXShift[2]}) {x};" >> $OutFile1
    elif [[ `echo "${TAX[1]} < 0" | bc` -eq 1 ]] && [[ ${TAX[2]} = 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[2]})--(${TAXShift[1]},${TAXShift[2]});" >> $OutFile1
      echo "\\node [left] at (${TAXShift[1]},${TAXShift[2]}) {x};" >> $OutFile1
    elif [[ `echo "${TAX[1]} > 0" | bc` -eq 1 ]] && [[ ${TAX[2]} = 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[2]})--(${TAXShift[1]},${TAXShift[2]});" >> $OutFile1
      echo "\\node [right] at (${TAXShift[1]},${TAXShift[2]}) {x};" >> $OutFile1
    elif [[ ${TAX[1]} = 0 ]] && [[ `echo "${TAX[2]} < 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[2]})--(${TAXShift[1]},${TAXShift[2]});" >> $OutFile1
      echo "\\node [below] at (${TAXShift[1]},${TAXShift[2]}) {x};" >> $OutFile1
    elif [[ ${TAX[1]} = 0 ]] && [[ `echo "${TAX[2]} > 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[2]})--(${TAXShift[1]},${TAXShift[2]});" >> $OutFile1
      echo "\\node [above] at (${TAXShift[1]},${TAXShift[2]}) {x};" >> $OutFile1
    elif [[ ${TAX[1]} = 0 ]] && [[ ${TAX[2]} = 0 ]];then
      echo "\\draw [-] (${AOShift[1]},${AOShift[2]})--(${TAXShift[1]},${TAXShift[2]});" >> $OutFile1
      echo "\\node [below] at (${TAXShift[1]},${TAXShift[2]}) {x};" >> $OutFile1
    fi
	
    if [[ ${TAY[1]} != 0 ]] && [[ ${TAY[2]} != 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[2]})--(${TAYShift[1]},${TAYShift[2]});" >> $OutFile1
      echo "\\node [right] at (${TAYShift[1]},${TAYShift[2]}) {y};" >> $OutFile1
    elif [[ `echo "${TAY[1]} < 0" | bc` -eq 1 ]] && [[ ${TAY[2]} = 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[2]})--(${TAYShift[1]},${TAYShift[2]});" >> $OutFile1
      echo "\\node [left] at (${TAYShift[1]},${TAYShift[2]}) {y};" >> $OutFile1
    elif [[ `echo "${TAY[1]} > 0" | bc` -eq 1 ]] && [[ ${TAY[2]} = 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[2]})--(${TAYShift[1]},${TAYShift[2]});" >> $OutFile1
      echo "\\node [right] at (${TAYShift[1]},${TAYShift[2]}) {y};" >> $OutFile1
    elif [[ ${TAY[1]} = 0 ]] && [[ `echo "${TAY[2]} < 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[2]})--(${TAYShift[1]},${TAYShift[2]});" >> $OutFile1
      echo "\\node [below] at (${TAYShift[1]},${TAYShift[2]}) {y};" >> $OutFile1
    elif [[ ${TAY[1]} = 0 ]] && [[ `echo "${TAY[2]} > 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[2]})--(${TAYShift[1]},${TAYShift[2]});" >> $OutFile1
      echo "\\node [above] at (${TAYShift[1]},${TAYShift[2]}) {y};" >> $OutFile1
    elif [[ ${TAY[1]} = 0 ]] && [[ ${TAY[2]} = 0 ]];then
      echo "\\draw [-] (${AOShift[1]},${AOShift[2]})--(${TAYShift[1]},${TAYShift[2]});" >> $OutFile1
      echo "\\node [below] at (${TAYShift[1]},${TAYShift[2]}) {y};" >> $OutFile1
    fi

    if [[ ${TAZ[1]} != 0 ]] && [[ ${TAZ[2]} != 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[2]})--(${TAZShift[1]},${TAZShift[2]});" >> $OutFile1
      echo "\\node [right] at (${TAZShift[1]},${TAZShift[2]}) {z};" >> $OutFile1
    elif [[ `echo "${TAZ[1]} < 0" | bc` -eq 1 ]] && [[ ${TAZ[2]} = 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[2]})--(${TAZShift[1]},${TAZShift[2]});" >> $OutFile1
      echo "\\node [left] at (${TAZShift[1]},${TAZShift[2]}) {z};" >> $OutFile1
    elif [[ `echo "${TAZ[1]} > 0" | bc` -eq 1 ]] && [[ ${TAZ[2]} = 0 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[2]})--(${TAZShift[1]},${TAZShift[2]});" >> $OutFile1
      echo "\\node [right] at (${TAZShift[1]},${TAZShift[2]}) {z};" >> $OutFile1
    elif [[ ${TAZ[1]} = 0 ]] && [[ `echo "${TAZ[2]} < 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[2]})--(${TAZShift[1]},${TAZShift[2]});" >> $OutFile1
      echo "\\node [below] at (${TAZShift[1]},${TAZShift[2]}) {z};" >> $OutFile1
    elif [[ ${TAZ[1]} = 0 ]] && [[ `echo "${TAZ[2]} > 0" | bc` -eq 1 ]];then
      echo "\\draw [->] (${AOShift[1]},${AOShift[2]})--(${TAZShift[1]},${TAZShift[2]});" >> $OutFile1
      echo "\\node [above] at (${TAZShift[1]},${TAZShift[2]}) {z};" >> $OutFile1
    elif [[ ${TAZ[1]} = 0 ]] && [[ ${TAZ[2]} = 0 ]];then
      echo "\\draw [-] (${AOShift[1]},${AOShift[2]})--(${TAZShift[1]},${TAZShift[2]});" >> $OutFile1
      echo "\\node [below] at (${TAZShift[1]},${TAZShift[2]}) {z};" >> $OutFile1
    fi
  fi
fi

echo "\\end{tikzpicture}" >> $OutFile1
echo "\\end{figure}" >> $OutFile1

###############################################
echo "Completed!Please check file: ${OutFile1}"
