import glob
import os
import re
import argparse

parser = argparse.ArgumentParser(description='Combine samples from different lanes into one')
parser.add_argument('-s', '--sample', dest = 'sample', help = 'sample name, e.g., 18774X1')
args = parser.parse_args()

def naturalSort(mylist):
    convert = lambda text: int(text) if text.isdigit() else text.lower()
    alphanum_key = lambda key: [ convert(c) for c in re.split('([0-9]+)', key) ]
    return sorted(mylist, key = alphanum_key)

# set file extensions
forwardExt='_R1_001.fastq.gz'
reverseExt='_R3_001.fastq.gz'
umiExt='_R2_001.fastq.gz'

# combine samples
sampleName=str(args.sample).split('_')[0]

forwardFiles=naturalSort(glob.glob(sampleName+'_*'+forwardExt))
os.system('cat '+' '.join(forwardFiles)+' > ./'+sampleName+forwardExt)

reverseFiles=naturalSort(glob.glob(sampleName+'_*'+reverseExt))
os.system('cat '+' '.join(reverseFiles)+' > ./'+sampleName+reverseExt)

umiFiles=naturalSort(glob.glob(sampleName+'_*'+umiExt))
os.system('cat '+' '.join(umiFiles)+' > ./'+sampleName+umiExt)
