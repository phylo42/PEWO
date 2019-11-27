#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

# test if there is at least one argument
if (length(args)<1) {
    stop("The directory containing benchmark results must be supplies as 1st argument.n", call.=FALSE)
}

library(RColorBrewer)
library(grid)
library(ggplot2)
library(Cairo)
library(data.table)
library(stringr)

workdir=args[1]

#in ressources mode, PEWO records ressources consumption in a single "pruning" labelled "0",
#which is in fact the full tree, not a pruning.
files = list.files(path=paste0(workdir,"/benchmarks"),pattern="^0_.*_benchmark.tsv")

# extract parameter combination and software, file per file
# aggregate everything in a dataframe

#iterate on files to build params list
params=c()
counter=1
for ( i in 1:length(files)) {
    print(paste0("Opening: ",files[i]))
    split=strsplit(files[i], "_")
    #scan for parameters
    if (length(split[[1]])>3) {
        for (j in 2:(length(split[[1]])-2) ) {
            print(split[[1]][j])
            pname=str_extract(split[[1]][j],regex("[a-z]+"))
            print(pname)
            params[counter]=pname
            counter=counter+1
        }
    }
}
params=unique(params)


df=data.frame(matrix(ncol = 11+length(params), nrow = 0))

param_names=c("s","h.m.s","max_rss","max_vms","max_uss","max_pss","io_in","io_out","mean_load","repeat","operation",params)
colnames(df)=param_names

#iterate again to fill dataframe
for ( i in 1:length(files)) {
    print(paste0("Parsing: ",files[i]))
    split=strsplit(files[i], "_")
    op=split[[1]][length(split[[1]])-1]
    #extract params list from filename
    current_params=c()
    current_vals=c()
    if (length(split[[1]])>3) {
        counter=1
        for (j in 2:(length(split[[1]])-2) ) {
            pname=str_extract(split[[1]][j],regex("[a-z]+"))
            pval=str_extract(split[[1]][j],regex("[A-Z0-9\\.]+"))
            current_params[counter]=pname
            current_vals[counter]=pval
            counter=counter+1
        }
    }
    #open it and extract values
    #not that currently hour:min:sec column is not parsed correcty
    #but this is not a problem as seconds are recorded in colum 's'
    data=read.table(
        file=paste(workdir,"/benchmarks/",files[i],sep="/"),sep="\t",header=TRUE,dec=".",
        colClasses = "character", comment.char = ""
    )
    data["repeat"]=1:dim(data)[1]
    data["operation"]=op
    for (j in 1:dim(data)[1]) {
        #build a line, eg benchmark measurements
        line=rep(NA,length(param_names))
        #first 11 values are set, whatever the program
        for (k in 1:11) {
            line[k]=data[j,k]
        }
        #following values are set if parameter is related to the program
        #NA otherwise
        for (k in 12:length(param_names)) {
            for (l in 1:length(current_params)) {
                if (param_names[k]==current_params[l]) {
                    line[k]=current_vals[l]
                    break
                }
            }
        }
        df[nrow(df) + 1,]= line
    }
}
write.table(file="benchmark.csv",df,row.names=FALSE,dec=".",na="",sep=",")