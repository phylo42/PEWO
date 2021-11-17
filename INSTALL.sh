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

if [ -d "$install_dir" ]; then 
  if [ -L "$install_dir" ]; then
    echo "PEWO installer: '$install_dir' is a symlink !"
    echo "PEWO installer: Cowardly refusing to delete it."
    exit 1
  else
    echo "PEWO installer: '$install_dir' already exists."
  fi
else
  echo "PEWO installer: Creating directory '$install_dir' ."
  mkdir $install_dir
  if [ $? -ne 0 ] ; then
    echo "PEWO installer: Cannot create directory. Write permissions ?"
  fi
fi

cd $install_dir
basedir=$(pwd)

#test if code was clone using recursive option
#check if ant build files are present
java_dep="$basedir/scripts/java/PEWO_java/build-cli.xml"
rap_dep="$basedir/scripts/java/PEWO_java/lib/RAPPAS/build-cli.xml"
if [ ! -f "$java_dep" ] ; then
        echo "Dependancy not found : $java_dep "
        echo "Did you clone PEWO repository using --recursive option ? (Damn, read the instructions!)"
        exit 1
fi
if [ ! -f "$rap_dep" ] ; then
        echo "Dependancy not found : $rap_dep "
        echo "Did you clone PEWO repository using --recursive option ? (Damn, read the instructions!)"
        exit 1
fi

#test if base commands are available
echo "PEWO installer: Testing if installation requirements are met..."
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
	echo "PEWO installer: You will find environment definitions in $install_dir/envs/environment.yaml"
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
                echo "PEWO installer: Please veryfing that Java JDK and Apache Ant were correctly installed in the PEWO environment."
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
        echo "PEWO installer: PEWO Java tools were not properly compiled."
        echo "PEWO installer: Please, copy/paste installation log and send it to PEWO developers."
	exit 1
else
        echo "PEWO installer: Java tools can be executed."
fi

## rapid test that the snakemake workflow can be launched
echo "PEWO installer: Testing PEWO workflow via a dry run using demo 1 ..."
demo_dir=$basedir/examples/1_fast_test_of_accuracy_procedure
snakemake -np --snakefile $basedir/eval_accuracy.smk --config workdir=$demo_dir/run --configfile $demo_dir/config.yaml
if  [ $? -ne 0 ] ; then
        echo "PEWO installer: The snakemake dry run was not successful."
	echo "PEWO installer: Please, copy/paste installation log and send it to PEWO developers."
else
        echo "PEWO installer: PEWO dry run successful."
	echo "PEWO installer: Have fun with PEWO !"
fi

#finish by deactivating environement
conda deactivate
echo "PEWO installer: Bye!"
