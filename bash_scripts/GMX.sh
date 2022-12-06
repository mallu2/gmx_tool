#!/usr/bin/bash

if [ "$1" != "" ]; then
    echo "Positional parameter 1 contains something"
else
    echo "Positional parameter 1 is empty"
fi

protein="$1"
echo $protein
GMX_settings="$2"

if [ "$1" == "makedir" ]; then
	mkdir 01-solv
	mkdir 02-mg
	mkdir 02-ions
	mkdir 03-min
	mkdir 04-nvt
	mkdir 05-npt
	mkdir 06-prod
fi

##cd 00-topo
##gmx_mpi pdb2gmx -f ${protein}.pdb -p ${protein}.top -o ${protein}_proc.gro -ignh -merge interactive 
##cd ..

if [ "$3" == "solvate" ]; then

	cd 01-solv
	for i in 2 3 #1 2 3 4 5  
	do 
		mkdir $i
		cp ../00-topo/${protein}.top $i
		cp ../00-topo/*.itp $i
		cp ~/amber99sbws.ff/tip4p2005.gro $i
		cp ../00-topo/${protein}_proc.gro $i
		cd $i
		gmx_mpi editconf -f ${protein}_proc.gro -o ${protein}_newbox.gro -d 1.0 -bt dodecahedron
		### boxtypes: cubic, triclinic, octahedron, dodecahedron
		
		gmx_mpi solvate -cp ${protein}_newbox.gro -cs tip4p2005.gro -o ${protein}_solv.gro -p ${protein}.top
		cd ..      
	done
	cd ..           
	
	cd 02-mg 
	for i in 2 3 #1 2 3 4 5  
	do 
		mkdir $i
		cp ../$GMX_settings/ions.mdp $i
		cp ../01-solv/$i/${protein}.top $i
		cp ../01-solv/$i/${protein}_solv.gro $i
		cd $i
		gmx_mpi grompp -f ions.mdp -c ${protein}_solv.gro -p ${protein}.top -o ions.tpr
		
		gmx_mpi genion -s ions.tpr -o ${protein}_solv_mg.gro -p ${protein}.top -pname MG -pq 2 -conc 0.005
		cd ..
	done
	cd ..
	
	cd 02-ions 
	for i in 2 3 # 1 4 5  
	do 
		mkdir $i
		cp ../$GMX_settings/ions.mdp $i
		cp ../02-mg/$i/${protein}.top $i
		cp ../02-mg/$i/${protein}_solv_mg.gro $i
		cd $i
		gmx_mpi grompp -f ions.mdp -c ${protein}_solv_mg.gro -p ${protein}.top -o ions.tpr
		
		gmx_mpi genion -s ions.tpr -o ${protein}_solv_ions.gro -p ${protein}.top -pname K -nname CL -conc 0.15 -neutral 
		cd ..
	done
	cd ..
fi

if [ "$3" == "min" ]; then
	cd 03-min
	for i in 2 3 # 1 4 5  
	do 
		mkdir $i
		cd $i
		cp ../../$GMX_settings/minim.mdp .
		cp ../../$GMX_settings/sub_min.sh .
		cp ../../02-ions/$i/${protein}.top .
		cp ../../02-ions/$i/${protein}_solv_ions.gro .
		cp ../../00-topo/*.itp .
		gmx_mpi grompp -f minim.mdp -c ${protein}_solv_ions.gro -p ${protein}.top -o min.tpr
		sbatch sub_min.sh
		cd ..
	done
	cd ..
fi

#
##cd 03-min
##check potential energy 
##fmax should be aroun 1000 kJ mol^-1 nm^-1
##Epot should be negative and in the order of 10^5 to 10^6
#
#gmx_mpi energy -f min.edr -o ${protein}_min_potential.xvg
#12
#
#
#xmgrace ${protein}_min_potential.xvg
#gmx_mpi trjconv -f ../min.trr -s ../1efa_noTetra_leap_addedTER_chainNum_solv_ions.gro -o min.pdb -pbc nojump

#cd ..

if [ "$3" == "nvt" ]; then
	cd 04-nvt/
	for i in 2 3 # 1 4 5  
	do 
		mkdir $i
		cd $i
		cp ../../$GMX_settings/nvt.mdp .
		cp ../../$GMX_settings/sub_nvt.sh .
		cp ../../03-min/$i/${protein}.top .
		cp ../../03-min/$i/min.gro .
		cp ../../00-topo/*.itp .
		
		gmx_mpi grompp -f nvt.mdp -c min.gro -r min.gro -p ${protein}.top -o nvt.tpr 
		cd ..
	done
	cd ..
fi

#sbatch sub_nvt.sh #16 nodes
#
#cd ..
##check the temperatur
#gmx_mpi energy -f nvt.edr -o ${protein}_nvt_temperature.xvg
#17
#
#
#xmgrace ${protein}_nvt_temperature.xvg
#cd ..

if [ "$3" == "npt" ]; then
	cd 05-npt/
	for i in 2 3 #1 2 3 4 5  
	do 
		mkdir $i
		cd $i
		cp ../../$GMX_settings/npt.mdp . 
		cp ../../$GMX_settings/sub_npt.sh . 
		cp ../../04-nvt/$i/${protein}.top .
		cp ../../04-nvt/$i/nvt.gro .
		cp ../../04-nvt/$i/nvt.cpt .
		cp ../../04-nvt/$i/*itp .
	        gmx_mpi grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p ${protein}.top -o npt.tpr
	        sbatch sub_npt.sh
		cd ..
	done
fi

#sbatch sub_npt.sh

#gmx_mpi energy -f npt.edr -o ${protein}_npt_pressure.xvg
#gmx_mpi energy -f npt.edr -o ${protein}_npt_density.xvg


echo "prepare folder 1 with topology and DNA_bonds.itp!"

if [ "$3" == "prod" ]; then
	cd 06-prod
	for i in 1 2 3 # 1 4 5  
	do 
		cp -r ../06-topo $i
		cd $i
		cp ../../$GMX_settings/md_prod.mdp . 
		cp ../../05-npt/$i/npt.gro .
		cp ../../05-npt/$i/npt.cpt .
		cp ../../05-npt/$i/*itp .
		gmx_mpi grompp -f md_prod.mdp -c npt.gro -r npt.gro -t npt.cpt -p ${protein}.top -o topol.tpr
		cd ..
	done
fi

#gmx_mpi grompp -f md_prod.mdp -c npt.gro -r npt.gro -t npt.cpt -p ${protein}.top -o md_DNA.tpr

