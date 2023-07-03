# Meta-analysis of RNA-seq

This shell script is an advanced version designed for the batch processing of SRA (Sequence Read Archive) data. The script is responsible for downloading SRA data, converting SRA files to FASTQ format, trimming and quality control, and quantification using Salmon. The operating environment is described in "env.sh".

## Defining the List of SRPs

```shell
# Define list of SRPs
sed -i 's/\r$//' list.csv # for Windows!! Remove CR!!
SRPs=()
while IFS= read -r line; do
    SRPs+=("$line")
done < list.csv
```

This section reads a list of SRPs (SRA Projects) from the `list.csv` file, with Windows line endings removed, and creates an array of SRPs.

## Setting the Number of Threads

```shell
# Number of CPU threads to use for fasterq-dump and salmon
threads=24
```

This line sets the number of CPU threads to be used by the `fasterq-dump` and `salmon` commands to accelerate the processing.

## Defining the Error Handler

```shell
# Define error handler
error_handler() {
    ...
}
```

An enhanced custom error handler is defined to log an error message with a timestamp, line number, status, and a custom error message into a log file named `error-log.txt`.

## Getting the Current Directory

```shell
# Get the current directory
current_dir=$(pwd)
```

This piece of code retrieves the current directory.

## Defining the SRA Processing Function

```shell
# Define SRA processing function
process_sra() {
    ...
}
```

This part defines a function for processing SRA files. This function is responsible for downloading SRA files, converting them to FASTQ format, trimming, quality control, and quantifying them. It also differentiates between paired-end and single-end reads.

## Creating Project Directory

```shell
# Define project directory
dc="Meta_analysis"

# Ensure project directory exists
mkdir -p ${dc}
```

This section defines the directory for the project and ensures it exists.

## Processing Each SRP

```shell
# Process each SRP
for SRP in ${SRPs[@]}; do
    ...
done
```

This section iterates through each SRP and performs various actions. It creates a directory for each SRP, retrieves the list of SRRs (SRA Runs), and processes each SRR.

## Retrieving the List of SRRs

```shell
# Get list of SRRs
esearch -db sra -query ${SRP} | efetch -format runinfo | cut -d ',' -f 1 | grep -v "Run" > ${current_dir}/SRR_Acc_List.txt
```

This part retrieves a list of SRRs associated with the SRP. It utilizes `esearch` and `efetch` commands to extract information from the NCBI database and saves it to a file named `SRR_Acc_List.txt`.

## Processing Each SRR

```shell
# Process each SRR
while read -r SRR <&3; do
    process_sra "${SRR}" "${SRP}"
done 3< "${current_dir}/SRR_Acc_List.txt"
```

This section reads the previously retrieved list of SRRs and processes each SRR through a loop using the `process_sra` function defined earlier.

## Returning to the Original Directory

```shell
# Go back to parent directory
cd ../..
```

After the processing for each SRP is completed, the script returns to the original directory.

# Summary

This enhanced script is designed for the automated batch processing of SRA data. It features improved error handling and additional processing steps. The script reads a list of SRPs, retrieves associated SRRs, and processes them by downloading, converting to FASTQ, trimming, quality controlling, and quantifying. The script handles both single-end and paired-end reads and logs errors to an error log file. I would like to thank sansyo([github.com/sansyo](https://github.com/sansyo)) for teaching us the basics of programming and how to use GCP.
