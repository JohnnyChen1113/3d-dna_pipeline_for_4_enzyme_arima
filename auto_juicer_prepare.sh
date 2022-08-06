#!/usr/bin/env bash

####################################
# Title: This script is for prepare juicer.sh input automaticlly.
# Author: Junhao Chen
# email: junhao.chen.1@slu.edu
# date: 2022-08-05
# version: 0.1.0
####################################

# software requirement:
- seqkit
- bwa
- samtools

genome=${1}
genome_name=${genome%.*}
hic_folder=${2}
juicer_path=/mnt/a16/01_turtle_genome_project/3ddna/juicer
enzyme=Arima
threads=24
# help
if [ -z ${1} ]
then
  echo "Usage: soft link the genome to current directory"
  echo "Activate the 3ddna env"
  echo "nohup bash ${0} <genome file> <HiC file folder absolute path> > <log> &"
  exit
fi

# create folder according to genome name
if [ ! -d ${genome_name} ]
then
  echo "[INFO] Start create the folders..." && \
    mkdir -p ${genome_name} && \
    mkdir -p ${genome_name}/reference && \
    ln -s ${hic_folder} ${genome_name}/fastq && \
  echo "[INFO] ${genome_name} folder created!"
  sleep 2s
else
  if [ -d ${genome_name}/align -a -d ${genome_name}/splits ]
  then
    echo "[WARNING] You have to remove the ${genome_name}/align and ${genome_name}/splits folder before run this script."
    exit
   else
     echo "[WARNING] The folder ${genome_name} already exist, do next step..."
   fi
fi

# cut the genome
if [ $? -eq 0 ]
then
  if [ ! -s ${genome_name}/reference/${genome_name}_w60.fasta ]
  then
    echo "[INFO] Start cut the genome into 60 words..." && \
    seqkit seq -w 60 ${genome} -o ${genome_name}/reference/${genome_name}_w60.fasta && \
    echo "[INFO] The genome cut already done!"
  else
    echo "[WARNING] The 60 word genome seems already done, do next step..."
  fi
else
  echo "[ERROR] The step before cut genome seems failed. please check it mannully!"
  exit
fi

# enzyme digest
if [ $? -eq 0 ]
then
  if [ ! -s ${genome_name}/reference/${genome_name}_${enzyme}.txt ]
  then
    echo "[INFO] Start generate the enzyme file...It may take hours to process this step, please have patience..." && \
    python ${juicer_path}/misc/generate_site_positions.py ${enzyme} ${genome_name} ${genome_name}/reference/${genome_name}_w60.fasta  && mv ${genome_name}_${enzyme}.txt ${genome_name}/reference && \
    echo "[INFO] the enzyme file finished!"
  else
    echo "[WARNING] The ${genome_name}_${enzyme}.txt exist. Do next step..."
  fi
else
  echo "[ERROR] The step before enzyme digest seems failed. please check it mannully!"
  exit
fi

# chrom len
if [ $? -eq 0 ]
then
  if [ ! -s ${genome_name}/reference/${genome_name}.chrom.sizes ]
  then
    echo "[INFO] Start generate the genome lenth file..." && \
    seqkit fx2tab -n -l ${genome_name}/reference/${genome_name}_w60.fasta -o ${genome_name}/reference/${genome_name}.chrom.sizes && \
    echo "[INFO] The genome lenth already calculated!"
  else
    echo "[WARNING] The ${genome_name}.chrom.sizes exist. Do next step..."
  fi
else
  echo "[ERROR] The step before chrom len seems failed. please check it mannully!"
  exit
fi

# build bwa index
if [ $? -eq 0 ]
then
  if [ ! -s ${genome_name}/reference/${genome_name}_w60.fasta.sa ]
  then
    echo "[INFO] Start build the bwa index..." && \
    bwa index ${genome_name}/reference/${genome_name}_w60.fasta && \
    echo "[INFO] The bwa index aleady done!"
  else
    echo "[WARNING] The ${genome_name}_w60.fasta.sa exist means the bwa index already done. Now you can run juicer.sh!"
  fi
else
  echo "[ERROR] The step before chrom len seems failed. please check it mannully!"
  exit
fi

# print the jucier.sh scripts
echo "[INFO] This is the juicer.sh script. you can copy it and run directly."
echo "===================================="
echo "#!/usr/bin/env bash"
echo "bash ${juicer_path}/CPU/juicer.sh \ "
echo "-g ${genome_name} \ "
echo "-d ${PWD}/${genome_name} \ "
echo "-D ${juicer_path} \ "
echo "-z ${PWD}/${genome_name}/reference/${genome_name}_w60.fasta \ "
echo "-y ${PWD}/${genome_name}/reference/${genome_name}_${enzyme}.txt \ "
echo "-p ${PWD}/${genome_name}/reference/${genome_name}.chrom.sizes \ "
echo "-s ${enzyme} \ "
echo "-t ${threads} "
