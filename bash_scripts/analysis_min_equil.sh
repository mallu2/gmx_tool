#!/usr/bin/bash

##check potential energy 
##fmax should be around 1000 kJ mol^-1 nm^-1
##Epot should be negative and in the order of 10^5 to 10^6

protein="$1"

#cd 03-min
#mkdir check_minim
#
#for i in 1 2 3 4 5  
#do 
#	mkdir check_minim/$i
#	cd $i
#	echo "10" | gmx_mpi energy -f min.edr -o ${protein}_min_potential.xvg  
#	mv ${protein}_min_potential.xvg ../check_minim/$i
#	cd ..
#done

cd 04-nvt

mkdir check_nvt

for i in 1 2 3 4 5  
do 
	mkdir check_nvt/$i
	cd $i
        echo "16" | gmx_mpi energy -f nvt.edr -o ${protein}_nvt_temperature.xvg
	mv ${protein}_nvt_temperature.xvg ../check_nvt/$i
	cd ..
done

cd ../05-npt

mkdir check_npt

for i in 1 2 3 4 5  
do 
	mkdir check_npt/$i
	cd $i
	
	echo "18" | gmx_mpi energy -f npt.edr -o ${protein}_npt_pressure.xvg
	echo "24" | gmx_mpi energy -f npt.edr -o ${protein}_npt_density.xvg
	mv ${protein}_npt_pressure.xvg ../check_npt/$i
	mv ${protein}_npt_density.xvg ../check_npt/$i
	cd ..
done
cd ..
