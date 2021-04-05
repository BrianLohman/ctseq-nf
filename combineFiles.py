import glob
import os
import re
import argparse

parser = argparse.ArgumentParser(description='Combine samples from different lanes into one')
parser.add_argument('-f', '--fastq', dest = 'fastq', help = 'directory that contains original fastqs')
parser.add_argument('-c', '--combined', dest = 'combined', help = 'directory that contains combined fastqs')
parser.add_argument('-r', '--run', dest = 'run', help = 'run name')
#parser.add_argument('-n', '--nsamples', dest = 'nsamples', help = 'number of samples')
args = parser.parse_args()

def naturalSort(mylist):
    #got code from https://stackoverflow.com/questions/4836710/does-python-have-a-built-in-function-for-string-natural-sort
    convert = lambda text: int(text) if text.isdigit() else text.lower()
    alphanum_key = lambda key: [ convert(c) for c in re.split('([0-9]+)', key) ]
    return sorted(mylist, key = alphanum_key)

# this is the dir where all the fastqs are
oldDir=str(args.fastq)

# this is the dir where you want the combined fastq files to go
newDir=str(args.combined)

# set file extensions
forwardExt='_R1_001.fastq.gz'
reverseExt='_R3_001.fastq.gz'
umiExt='_R2_001.fastq.gz'

# set run name
runName=str(args.run)

# get number of samples
n = len(set([i.split('/')[-1].split('_')[0] for i in glob.glob(args.fastq+'/*R1_001.fastq.gz')]))

# change working directory to where fastqs are
os.chdir(oldDir)

# combine samples
for i in range(1,n+1,1): #(start,end(N+1), step size)
    sampleName=runName+str(i)
    #print("processing "+sampleName)
    forwardFiles=naturalSort(glob.glob(sampleName+'_*'+forwardExt))
    os.system('cat '+' '.join(forwardFiles)+' > '+newDir+sampleName+forwardExt)

    reverseFiles=naturalSort(glob.glob(sampleName+'_*'+reverseExt))
    os.system('cat '+' '.join(reverseFiles)+' > '+newDir+sampleName+reverseExt)

    umiFiles=naturalSort(glob.glob(sampleName+'_*'+umiExt))
    os.system('cat '+' '.join(umiFiles)+' > '+newDir+sampleName+umiExt)
