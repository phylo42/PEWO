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

csvdir=args[1]
files = list.files(path=csvdir,pattern="*_benchmark.tsv")

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


df=data.frame(matrix(ncol = 10+length(params), nrow = 0))
names=c("operation","repeat","sec","hms","max_rss","max_vms","max_uss","max_pss","io_in","io_out",params)
colnames(df)=names

#iterate again to fill dataframe
for ( i in 1:length(files)) {
    print(paste0("Opening: ",files[i]))
    split=strsplit(files[i], "_")
    op=split[[1]][length(split[[1]])-1]
    #params list
    current_params=c()
    current_vals=c()
    if (length(split[[1]])>3) {
        counter=1
        for (j in 2:(length(split[[1]])-2) ) {
            print(split[[1]][j])
            pname=str_extract(split[[1]][j],regex("[a-z]+"))
            pval=str_extract(split[[1]][j],regex("[A-Z0-9\\.]+"))
            current_params[counter]=pname
            current_vals[counter]=pval
            counter=counter+1
        }
    }
    #open it
    data=read.csv(file=paste(csvdir,files[i],sep="/"),sep="\t",header=TRUE)
    data["repeat"]=1:dim(data)[1]
    data["operation"]=op
    for (j in 1:dim(data)[1]) {
        line=c()
        #build 1st half of line, eg benchmark measurements
        col=1
        for (k in 1:dim(data)[2]) {
            line[col]=data[rep_counter,col]
        }
        #build 2nd half of line, eg algo params
        for (k in 1:dim(df)[2]) {
            if (colnames(df)[k] in current_params)
            line[col]=data[rep_counter,col]
        }

    }



}