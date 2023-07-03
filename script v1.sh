#!/bin/bash

# Define list of SRPs
sed -i 's/\r$//' list.csv # for Windows!! Remove CR!!
SRPs=()
while IFS= read -r line; do
    SRPs+=("$line")
done < list.csv

# Add more SRPs as needed
threads=24 # Number of CPU threads to use for fasterq-dump and salmon


# Define error handler
error_handler() {
    local LINE=$1
    local STATUS=$2
    local ERROR_MSG=$3
    local LOG_FILE="error-log.txt"
    local TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

    echo "---- Error Report ----" >> $LOG_FILE
    echo "Timestamp: ${TIMESTAMP}" >> $LOG_FILE
    echo "Error occurred at line: ${LINE}." >> $LOG_FILE
    echo "Line exited with status: ${STATUS}." >> $LOG_FILE

    # Capture the error message if provided.
    if [ -n "${ERROR_MSG}" ]; then
        echo "Error message: ${ERROR_MSG}" >> $LOG_FILE
    fi

    echo "-----------------------" >> $LOG_FILE
}

# Get the current directory
current_dir=$(pwd)

# Define SRA processing function
process_sra() {
    # Set error trap for this function
    trap 'error_handler ${LINENO} $?' ERR

    local SRR=$1
    local SRP=$2

    if [ ! -f ${SRR}/${SRR}.sra ]; then
        esearch -db sra -query ${SRR} | efetch -format runinfo | cut -d ',' -f 1 > ${SRR}.sra
    fi
            
    echo "Downloading ${SRR}..."
    prefetch $SRR || (sleep 5; prefetch $SRR)

    if [ -e $(pwd)/${SRR}/${SRR}.sra ]; then
        echo "Converting ${SRR}.sra..."
        fasterq-dump -e ${threads} $(pwd)/${SRR}
        
        # Remove downloaded .sra file and folder
        rm $(pwd)/${SRR}/${SRR}.sra
        rm -r $(pwd)/${SRR}

    elif [ -e $(pwd)/${SRR}/${SRR}.sralite ]; then
        echo "Converting ${SRR}.sralite..."
        fasterq-dump -e ${threads} $(pwd)/${SRR}/${SRR}
        
        # Remove downloaded .sralite file and folder
        rm $(pwd)/${SRR}/${SRR}.sralite
        rm -r $(pwd)/${SRR}
        
    else
        echo "Neither ${SRR}.sra nor ${SRR}.sralite found for ${SRR}. Skipping to next SRR."
        return 1
    fi

    mkdir -p ../${SRP}_trimmed
    mkdir -p ../${SRP}_trimmed_QC

    # Check if paired-end reads
    if [ -f ${SRR}_1.fastq ] && [ -f ${SRR}_2.fastq ]; then
        echo "Trimming and quality controlling for paired-end reads of $SRR..."
        pigz ${SRR}_1.fastq
        pigz ${SRR}_2.fastq

        fastp \
        -i ${SRR}_1.fastq.gz -I ${SRR}_2.fastq.gz \
        -o ../${SRP}_trimmed/${SRR}_1_trimmed.fastq.gz -O ../${SRP}_trimmed/${SRR}_2_trimmed.fastq.gz \
        -h ../${SRP}_trimmed_QC/${SRR}_report.html \
        -j ../${SRP}_trimmed_QC/${SRR}_report.json \
        -w 16 # Up to 16 threads

        echo "Quantifying for paired-end reads of $SRR..."
        salmon quant \
        -i ${current_dir}/salmon_index \
        -l A \
        -1 ../${SRP}_trimmed/${SRR}_1_trimmed.fastq.gz \
        -2 ../${SRP}_trimmed/${SRR}_2_trimmed.fastq.gz \
        -p ${threads} \
        --gcBias \
        --validateMappings \
        -o ../${SRP}/${SRR}_trimmed.fastq_salmon_quant

    else
        echo "Trimming and quality controlling for single-end reads of $SRR..."
        pigz ${SRR}.fastq
        
        fastp \
        -i ${SRR}.fastq.gz \
        -o ../${SRP}_trimmed/${SRR}_trimmed.fastq.gz \
        -h ../${SRP}_trimmed_QC/${SRR}_report.html \
        -j ../${SRP}_trimmed_QC/${SRR}_report.json \
        -w 16 # Up to 16 threads

        echo "Quantifying for single-end reads of $SRR..."
        salmon quant \
        -i ${current_dir}/salmon_index \
        -l A \
        -r ../${SRP}_trimmed/${SRR}_trimmed.fastq.gz \
        -p ${threads} \
        --gcBias \
        --validateMappings \
        -o ../${SRP}/${SRR}_trimmed.fastq_salmon_quant
    fi

    # Reset trap to previous value
    trap - ERR
}

# Define project directory
dc="Meta_analysis"

# Ensure project directory exists
mkdir -p ${dc}

# Process each SRP
for SRP in ${SRPs[@]}; do
    # Create SRP-specific directory
    echo "Current SRP: ${SRP}"
    mkdir -p ${dc}/${SRP}

    # Change to project directory
    cd ${dc}/${SRP}

    # Get list of SRRs
    esearch -db sra -query ${SRP} | efetch -format runinfo | cut -d ',' -f 1 | grep -v "Run" > ${current_dir}/SRR_Acc_List.txt

    # Process each SRR
    while read -r SRR <&3; do
        process_sra "${SRR}" "${SRP}"
    done 3< "${current_dir}/SRR_Acc_List.txt"

    # Go back to parent directory
    cd ../..

done

