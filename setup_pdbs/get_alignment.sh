#!/bin/bash

rcsb_hit_file=$1
pdb_dir=$2

pdb_list=$(cat $1 | awk '{print $1}')
#pdb_list="4XNR"
for pdb_id in $pdb_list; do 
	wget "http://www.rcsb.org/pdb/files/"$pdb_id".pdb"
	grep 'ATOM' $pdb_id'.pdb' > $pdb_id'_filtered.pdb'
	pdb2fasta.py $pdb_id'_filtered.pdb' > $pdb_id".fasta"
	seq_length=$(cat $pdb_id".fasta" | head -n 2 | tail -n 1 | awk '{print length}')
	# Trying to get only the first chain...
	resids=$(cat $pdb_id".fasta" | head -n 1 | cut -d ' ' -f2-)
	pdbslice.py $pdb_id'_filtered.pdb' -subset $resids "subset_"
	mv "subset_"$pdb_id"_filtered.pdb" $pdb_id"_filtered.pdb"
	renumber_pdb_in_place.py $pdb_id'_filtered.pdb' "A:1-"$seq_length
	mv $pdb_id'_filtered.pdb' $pdb_id'.pdb' 
	pdb2fasta.py $pdb_id'.pdb' > $pdb_id".fasta"
	cmscan Rfam.cm $pdb_id".fasta" > sample_output.dat
	num_hits=$(grep -n "^>> " sample_output.dat | wc -l)
	start_align=$(grep -n "^>> " sample_output.dat | head -n 1 | cut -d ":" -f1)
	end_align=$(grep -n "^Internal" sample_output.dat | head -n 1 | cut -d ":" -f1)
	if (( $num_hits > 1 )); then
		end_align=$(grep -n "^>> " sample_output.dat | head -n 2 | tail -n 1 | cut -d ":" -f1)
	fi
	head -n $(($end_align-1)) sample_output.dat | tail -n +$start_align > $pdb_id'.align'
	mv $pdb_id'.fasta' $pdb_dir
	mv $pdb_id'.pdb' $pdb_dir
	mv $pdb_id'.align' $pdb_dir
done