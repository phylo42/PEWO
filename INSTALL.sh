#!/bin/sh

# PARAMETERS

#installation directory
install_dir="./PEWO_workflow"


# REQUIREMENTS

# Please make sure 'git', 'conda' commands are installed on your system.
# Installers are available at https://docs.conda.io/en/latest/miniconda.html 
#
# Below are unix commands: 
#
# $ sudo apt-get install git 
# $ wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
# $ chmod u+x ./Miniconda3-latest-Linux-x86_64.sh
# $ sudo ./Miniconda3-latest-Linux-x86_64.sh
#
# These are very common software, available for most operating systems, 
# just browse the web to find how to install them on yours.

# INSTALLATION

#test if base commands are available
echo "PEWO installer: Testing is installation requirements are met..."
for i in "git conda"
do
	if ! foobar_loc="$(type -p $i)" || [[ -z $foobar_loc ]]; then
		echo "PEWO installer: Command '$i' not found."
		echo "PEWO installer: This is a requirement to PEWO installation. See documentation."
		exit 1
	else
		echo "PEWO installer: Command $i found in $(which $i)"
	fi
done


## clone workflow into installation directory
echo "PEWO installer: Downloading PEWO_workflow ..."
git clone https://github.com/blinard-BIOINFO/PEWO_workflow.git $install_dir
cd $install_dir

## install conda environment
echo "PEWO installer: Creating environment... (this can take some time)"
conda env create --file envs/environment.yaml
echo "PEWO installer: Testing environment..."
if ! $(conda activate PEWO)
do
        echo "PEWO installer: PEWO Environment can not be activated, please check you conda installation."
	echo "PEWO installer: You will find the environement definition in $install_dir/envs/environment.yaml"
else
	echo "PEWO installer: PEWO environment loaded."
done

## build java dependencies
## this uses java JDK installed in the conda environement
echo "PEWO installer: Building dependencies..."
echo "PEWO installer: Testing java JDK installation..."
for i in "javac ant java"
do
        if ! foobar_loc="$(type -p $i)" || [[ -z $foobar_loc ]]; then
                echo "PEWO installer: Command '$i' not found in PEWO environment."
                echo "PEWO installer: Please veryfing that Java JDK and Apache Ant were correctly installed in the environment."
                exit 1
        else
                echo "PEWO installer: Command $i found in $(which $i)"
        fi
done
echo "PEWO installer: Building java tools..."
cd scripts/java/PEWO_java
ant -f build-cli.xml
echo "PEWO installer: Testing java tools..."
if ! $(java -jar scripts/java/PEWO_java/dist/PEWO_java.jar)
do
        echo "PEWO installer: PEWO Java tools appear to not have properly compiled."
        echo "PEWO installer: Report errors encountered during installation to developers."
else
        echo "PEWO installer: Java tools OK."
done

## rapid test that the snakemake workflow can be launched
echo "PEWO installer: Testing PEWO workflow via a dry run using demos..."
demo_dir=$install_dir/demos/16SrRNA_resource_test
cd $install_dir
if ! $(snakemake -np --snakefile $install_dir/eval_resources.smk --config workdir=$demo_dir/run query_user=$demo_dir/EMP_92_studies_100000.fas --configfile $demo_dir/config.yaml)
do
        echo "PEWO installer: The snakemake dry run could not be launched."
        echo "PEWO installer: Report errors encountered during installation to developers."
else
        echo "PEWO installer: PEWO dry run successful."
	echo "PEWO installer: Have fun with PEWO and do not hesitate to contact us for expanding it!"
done

#finish by deactivating environement
conda deactivate PEWO

