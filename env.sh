# conda install
curl -O https://repo.anaconda.com/archive/Anaconda3-2023.03-1-Linux-x86_64.sh
rm -rf ~/anaconda3  # (Clear anaconda previous version)
bash Anaconda3-2023.03-1-Linux-x86_64.sh

# install efetch esearch
conda install -c bioconda entrez-direct

# install fastp
conda install -c bioconda fastp

# install salmon
conda config --add channels conda-forge
conda config --add channels bioconda
conda install -c bioconda salmon=1.10.1

# install sra-tools 
conda install -c bioconda sra-tools=3.0.5

# install pigz
conda install pigz
