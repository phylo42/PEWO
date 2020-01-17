#!/usr/bin/env python3

import sys
import re
import collections
print("Conversion from psiblast to fasta")
print("Usage: psiblast2fasta.py aln.psiblast aln.fasta")

f_in=open(sys.argv[1],"r")
f_out=open(sys.argv[2],"w")

#dict to see which header has already been found
headers=collections.OrderedDict()
#when reading all seq ids at 1st block (before 1st empty line)
#check if duplicate names
firstblock=1 
line_block=0
duplicate={} #map(line_block)=new_identifier
duplicate_index={} #map(identifier)=#duplicate_envountered_in_block
# read psiblast alignment
lines = f_in.readlines()
for line in lines:
        #skip empty lines, reset block at empty lines
        if (len(line.strip())<1):
                firstblock=0
                line_block=0
                continue;
        #load sequences
        elts=line.strip().split()
        #elts=re.split('\s+',line) //ajout '' before \n, for whatever obsure reason
	

        #identifier never encountered, register it
        if ( elts[0] not in headers ):
                headers[elts[0]]=elts[1]
        else:
                #if still in block 1
                if ( (firstblock==1)  and (elts[0] in headers) ):
                        #set counter of how many times we encountered this id
                        if (elts[0] not in duplicate_index):
                                duplicate_index[elts[0]]=0
                        else:
                                duplicate_index[elts[0]]=duplicate_index[elts[0]]+1
                        #create new id
                        duplicate[line_block]=elts[0]+'_'+str(duplicate_index[elts[0]])
                        print("duplicate at "+str(line_block)+" id set to "+duplicate[line_block])
                        headers[duplicate[line_block]]=""
                #add sequence to original or n-th duplicate depending on current block line
                if (line_block in duplicate):
                        headers[duplicate[line_block]]=headers[duplicate[line_block]]+elts[1]
                else:
                        headers[elts[0]]=headers[elts[0]]+elts[1]

        line_block=line_block+1

#write in output file
for key in headers.keys():
        f_out.write(">"+key+"\n"+headers[key]+"\n")

f_in.close()
f_out.close()

#print("DONE!")
