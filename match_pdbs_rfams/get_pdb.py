import Bio
from Bio.PDB import PDBList
import sys

pdb_id = sys.argv[1]
cur_dir = sys.argv[2]

pdbl = PDBList()
pdbl.retrieve_pdb_file(pdb_id, file_format='pdb', pdir=cur_dir)