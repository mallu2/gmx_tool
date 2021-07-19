#!/usr/bin/bash

if [ "$1" != "" ]; then
    echo "Positional parameter 1 contains something"
else
    echo "Positional parameter 1 is empty"
fi

protein="$1"
echo $protein
GMX_settings="$2"
replica="$3"

#mkdir 01-solv
#mkdir 02-mg
#mkdir 02-ions
#mkdir 03-min
mkdir 04-nvt
#mkdir 05-npt
#mkdir 06-prod


##cd 00-topo
##gmx_mpi pdb2gmx -f ${protein}.pdb -p ${protein}.top -o ${protein}_proc.gro -ignh -merge interactive 
##cd ..

#cd 01-solv
#cp ../00-topo/${protein}.top .
#cp ../00-topo/*.itp .
#cp ~/amber99sbws.ff/tip4p2005.gro .
#cp ../00-topo/${protein}_proc.gro .
#gmx_mpi editconf -f ${protein}_proc.gro -o ${protein}_newbox.gro -d 1.0 -bt cubic
#### boxtypes: cubic, triclinic, octahedron, dodecahedron
###
####gmx_mpi solvate -cp ${protein}_newbox.gro -cs spc216.gro -o ${protein}_solv.gro -p ${protein}.top
#gmx_mpi solvate -cp ${protein}_newbox.gro -cs tip4p2005.gro -o ${protein}_solv.gro -p ${protein}.top
#cd ..      #
##           #
##
#cd 02-mg 
#cp ../$GMX_settings/ions.mdp .
#cp ../01-solv/${protein}.top .
#cp ../01-solv/${protein}_solv.gro .
#cp ../00-topo/*.itp .
#gmx_mpi grompp -f ions.mdp -c ${protein}_solv.gro -p ${protein}.top -o ions.tpr
#
#gmx_mpi genion -s ions.tpr -o ${protein}_solv_mg.gro -p ${protein}.top -pname MG -pq 2 -conc 0.005
#
#cd ..
#
#cd 02-ions 
#cp ../$GMX_settings/ions.mdp .
#cp ../02-mg/${protein}.top .
#cp ../02-mg/${protein}_solv_mg.gro .
#cp ../00-topo/*.itp .
#gmx_mpi grompp -f ions.mdp -c ${protein}_solv_mg.gro -p ${protein}.top -o ions.tpr
#
#gmx_mpi genion -s ions.tpr -o ${protein}_solv_ions.gro -p ${protein}.top -pname K -nname CL -conc 0.15 -neutral 
#
#cd ..
#
#
#
#
#cd 03-min
#for i in 1 2 3 4 5  
#do 
#	mkdir $i
#	cd $i
#	cp ../../$GMX_settings/minim.mdp .
#	cp ../../$GMX_settings/sub_min.sh .
#	cp ../../02-ions/${protein}.top .
#	cp ../../02-ions/${protein}_solv_ions.gro .
#	cp ../../00-topo/*.itp .
#	gmx_mpi grompp -f minim.mdp -c ${protein}_solv_ions.gro -p ${protein}.top -o min.tpr
#	sbatch sub_min.sh
#	cd ..
#done
#gmx_mpi grompp -f minim.mdp -c ${protein}_solv_ions.gro -p ${protein}.top -o min.tpr 

#sbatch sub_min.sh
#
#cd ..
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

cd 04-nvt/
for i in 1 2 3 4 5  
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
#cp ../../$GMX_settings/nvt.mdp .
#cp ../../$GMX_settings/sub_nvt.sh .
#cp ../../03-min/$replica/${protein}.top .
#cp ../../03-min/$replica/min.gro .
#cp ../../00-topo/*.itp .
#
#gmx_mpi grompp -f nvt.mdp -c min.gro -r min.gro -p ${protein}.top -o nvt.tpr 

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
#
#cd 05-npt/
#for i in 1 2 3 4 5  
#do 
#	mkdir $i
#	cd $i
#	cp ../../$GMX_settings/npt.mdp . 
#	cp ../../$GMX_settings/sub_npt.sh . 
#	cp ../../04-nvt/$i/${protein}.top .
#	cp ../../04-nvt/$i/nvt.gro .
#	cp ../../04-nvt/$i/nvt.cpt .
#	cp ../../04-nvt/$i/*itp .
#        gmx_mpi grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p ${protein}.top -o npt.tpr
#        sbatch sub_npt.sh
#	cd ..
#done
#sbatch sub_npt.sh
#
#gmx_mpi energy -f npt.edr -o ${protein}_npt_pressure.xvg
#gmx_mpi energy -f npt.edr -o ${protein}_npt_density.xvg



#cd 06-prod
#for i in 1 2 3 4 5  
#do 
#	#mkdir $i
#	cd $i
#	#cp ../../$GMX_settings/md_prod_NMR.mdp . 
#	#cp ../../$GMX_settings/sub_DNA.sh . 
#	#cp ../../05-npt/$i/${protein}.top .
#	#cp ../../05-npt/$i/npt.gro .
#	#cp ../../05-npt/$i/npt.cpt .
#	#cp ../../05-npt/$i/*itp .
#	#cp ../../DNA_bonds.itp .
#	gmx_mpi grompp -f md_prod_NMR.mdp -c npt.gro -r npt.gro -t npt.cpt -p ${protein}.top -o md_prod.tpr
#	cd ..
#done
#
#gmx_mpi grompp -f md_prod.mdp -c npt.gro -r npt.gro -t npt.cpt -p ${protein}.top -o md_DNA.tpr

#cd 07-prod
#cp ../$GMX_settings/md_prod.mdp . 
#cp ../$GMX_settings/sub_md.sh . 
#cp ../06-DNA_Equil/${protein}.top .
#cp ../06-DNA_Equil/md_DNA.gro .
#cp ../06-DNA_Equil/md_DNA.cpt .
#cp ../06-DNA_Equil/*itp .
#
#gmx_mpi grompp -f md_prod.mdp -c npt.gro -r npt.gro -t npt.cpt -p ${protein}.top -o md.tpr
