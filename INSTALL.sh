#!/bin/bash

# PARAMETERS

#installation directory
install_dir="."


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

cd $install_dir
basedir=$(pwd)

#test if base commands are available
echo "PEWO installer: Testing is installation requirements are met..."
for i in git conda
do
	if ! [ -x "$(command -v $i)" ]; then
		echo "PEWO installer: Command '$i' not found."
		echo "PEWO installer: This is a requirement to PEWO installation. See documentation."
		exit 1
	else
		echo "PEWO installer: Command $i found in $(which $i)"
	fi
done


## clone workflow into installation directory
#echo "PEWO installer: Downloading PEWO_workflow ..."
#git clone https://github.com/blinard-BIOINFO/PEWO_workflow.git $install_dir
#cd $install_dir

## install conda environment, if not environment called "PEWO" exists
conda env list | grep "^PEWO " &> /dev/null
if [ $? -ne 0 ] ; then
	echo "PEWO installer: Creating environment... (this can take some time)"
	conda env create --file envs/environment.yaml
	if [ $? -ne 0 ] ; then
		echo echo "PEWO installer: Cannot create environment. Write permissions ?"
		exit 1
	fi
else
	echo "PEWO installer: A conda environment named PEWO already exists, skiping creation."
fi


echo "PEWO installer: Testing environment..."
eval "$(conda shell.bash hook)"
conda activate PEWO
if [ $? -ne 0 ]  ; then
        echo "PEWO installer: PEWO environment cannot be activated, please check your conda installation."
	echo "PEWO installer: You will find environement definitions in $install_dir/envs/environment.yaml"
	exit 1
else
	echo "PEWO installer: PEWO environment loaded."
fi

## build java dependencies
## this uses java JDK installed in the conda environement
echo "PEWO installer: Building dependencies..."
echo "PEWO installer: Testing java JDK installation..."
for i in javac ant java
do
	if ! [ -x "$(command -v $i)" ]; then
		echo "PEWO installer: Command '$i' not found in PEWO environment."
                echo "PEWO installer: Please veryfing that Java JDK and Apache Ant were correctly installed in the environment."
                exit 1
        else
                echo "PEWO installer: Command $i found in $(which $i)"
        fi
done

echo "PEWO installer: Building java tools..."
cd $basedir/scripts/java/PEWO_java
ant -f build-cli.xml
cd $basedir
echo "PEWO installer: Testing java tools..."
java -jar $basedir/scripts/java/PEWO_java/dist/PEWO.jar &> /dev/null 
if [ $? -ne 0 ] ; then
        echo "PEWO installer: PEWO Java tools appear to not have properly compiled."
        echo "PEWO installer: Report errors encountered during installation to developers."
	exit 1
else
        echo "PEWO installer: Java tools execution OK."
fi

## rapid test that the snakemake workflow can be launched
echo "PEWO installer: Testing PEWO workflow via a dry run using demos..."
demo_dir=$basedir/demos/16SrRNA_resource_test
snakemake -np --snakefile $basedir/eval_resources.smk --config workdir=$demo_dir/run query_user=$demo_dir/EMP_92_studies_100000.fas --configfile $demo_dir/config.yaml
if  [ $? -ne 0 ] ; then
        echo "PEWO installer: The snakemake dry run could not be launched."
        echo "PEWO installer: Report errors encountered during installation to developers."
else
        echo "PEWO installer: PEWO dry run successful."
	echo "PEWO installer: Have fun with PEWO !  And do not hesitate to contact us to for future extensions !"
fi

#finish by deactivating environement
conda deactivate
echo "bye!"
