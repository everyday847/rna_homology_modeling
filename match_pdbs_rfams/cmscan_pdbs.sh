#!/bin/bash

## Usage: ./cmscan_pdbs.sh nrlist_3.96_4.0A.csv directory/for/tmp/output/PDBs/
nonredundant_pdb=$1 # nonredundant PDB file downloaded from here: http://rna.bgsu.edu/rna3dhub/nrlist/release/3.96
cur_dir=$2 

# Get the PDB id's for the best representative PDB as annotated in the 
# non-redundant PDB CSV file 
pdb_list=$(cat $1 | cut -d ',' -f2 | sed -e 's/^"//' -e 's/"$//' | cut -d '|' -f1)
# For each PDB ID
for cur_id in $pdb_list; do 
	echo $cur_id
	
	# Two methods to get PDB ID: 
	# 1. Uses get_pdb script and requires Python's Bio library
	# 2. Directly wget from PDB 
	
	# 1.
	# python get_pdb.py $cur_id $cur_dir
	# mv 'pdb'$cur_id'.ent' $cur_id'.pdb'
	
	# 2.
	wget "http://www.rcsb.org/pdb/files/"$cur_id".pdb"
	
	# Clean PDB of HETATOM lines and get fasta
	grep 'ATOM' $cur_id'.pdb' > $cur_id'_filtered.pdb'
	pdb2fasta.py $cur_id'_filtered.pdb' > $cur_id'.fasta'

	# Get length of fasta after first line for the length cutoff
	seq_length=$(tail -n +2 $cur_id'.fasta' | awk '{print length}' | sort -n | tail -1)

	if (( $seq_length < 500 )); then # Don't run huge cmscan runs
		# Run Infernal's cmscan over the full compressed Rfam.cm
		cmscan Rfam.cm $cur_id'.fasta' > cm_hits.dat
		# Proceed if there's at least one alignment
		num_hits=$(grep "\!" cm_hits.dat | wc -l)
		if (( $num_hits > 0)); then 
			# Only work with the top alignment
			hit_line=$(grep "\!" cm_hits.dat | head -n 1)
			# Get alignments that have E values at least 0.0001
			e_val=$(echo $hit_line | awk '{print $3}')
			e_val=$(printf "%.5f\n" $e_val)
			pass_thresh=$(echo $e_val'<0.0001' | bc -l)
			if [ "$pass_thresh" == "1" ]; then
				# Tabulate (PDB ID, family name) for each hit
				family_name=$(echo $hit_line | awk '{print $6}')
				echo $cur_id" "$family_name >> all_hits.dat
			fi
		fi

		rm cm_hits.dat
	fi
	rm $cur_id'.pdb'
	rm $cur_id'_filtered.pdb'
	rm $cur_id'.fasta'
done