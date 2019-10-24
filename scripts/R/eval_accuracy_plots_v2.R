#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

# test if there is at least one argument
if (length(args)<2) {
  stop("The file results.csv must be supplied as 1st argument and the workdir as 2nd argument (input file).n", call.=FALSE)
}

library(RColorBrewer)
library(grid)
library(ggplot2)
library(Cairo)


#functions
##################################################

#function summarySE
#from http://www.cookbook-r.com/Graphs/Plotting_means_and_error_bars_(ggplot2)/#Helper functions

## Gives count, mean, standard deviation, standard error of the mean, and confidence interval (default 95%).
##   data: a data frame.
##   measurevar: the name of a column that contains the variable to be summariezed
##   groupvars: a vector containing names of columns that contain grouping variables
##   na.rm: a boolean that indicates whether to ignore NA's
##   conf.interval: the percent range of the confidence interval (default is 95%)
summarySE <- function(data=NULL, measurevar, groupvars=NULL, na.rm=FALSE,
                      conf.interval=.95, .drop=TRUE) {
    library(plyr)

    # New version of length which can handle NA's: if na.rm==T, don't count them
    length2 <- function (x, na.rm=FALSE) {
        if (na.rm) sum(!is.na(x))
        else       length(x)
    }

    # This does the summary. For each group's data frame, return a vector with
    # N, mean, and sd
    datac <- ddply(data, groupvars, .drop=.drop,
      .fun = function(xx, col) {
        c(N    = length2(xx[[col]], na.rm=na.rm),
          mean = mean   (xx[[col]], na.rm=na.rm),
          sd   = sd     (xx[[col]], na.rm=na.rm)
        )
      },
      measurevar
    )

    # Rename the "mean" column
    datac <- rename(datac, c("mean" = measurevar))

    datac$se <- datac$sd / sqrt(datac$N)  # Calculate standard error of the mean

    # Confidence interval multiplier for standard error
    # Calculate t-statistic for confidence interval:
    # e.g., if conf.interval is .95, use .975 (above/below), and use df=N-1
    ciMult <- qt(conf.interval/2 + .5, datac$N-1)
    datac$ci <- datac$se * ciMult

    return(datac)
}


# Association software/parameters
# Need to be manually defined prior to analysis
# There should not be new placement software too
# often, so this is manageable.
#################################################

soft_list<-list("epa", "epang_heuristic1", "epang_heuristic2", "epang_heuristic3", "epang_heuristic4", "ppl", "rappas", "apples")

epa<-c("g")
epang_heuristic1<-c("h","g")
epang_heuristic2<-c("h","bigg")
epang_heuristic3<-c("h")
epang_heuristic4<-c("h")
ppl<-c("ms","sb","mp")
rappas<-c("k","o","red")
apples<-c("m","c")

soft_params<-list(epa=epa,epang_heuristic1=epang_heuristic1,epang_heuristic2=epang_heuristic2,epang_heuristic3=epang_heuristic3,epang_heuristic4=epang_heuristic4,ppl=ppl,rappas=rappas,apples=apples)


#load data
##################################################
data<-read.csv(file=args[1], sep=";", header=TRUE)
workdir=args[2]


#ND heatmaps per parameters
alltables<-list()
allplots<-list()

for ( i in 1:length(soft_list) ) {
	softname<-soft_list[[i]]
	#epang is treated separatly for each heuristic
	softname_short<-strsplit(softname, "_")[[1]][1]

	print(paste("ND heatmap for ",softname,sep=""))
	#remove columns with only NA, meaning this parameter was not linked to current soft
	current_soft_data<-data[data$software==softname_short,]
	current_soft_data<-current_soft_data[, colSums(is.na(current_soft_data)) != nrow(current_soft_data)]
	#build formulas dynamically fro parameters
	formula_mean<-"nd ~ pruning + r"
	formula_meanofmean<-"nd ~ r"
	for ( j in 1:length(soft_params[softname][[1]] ) ) {
		formula_mean<-paste(formula_mean, " + ",soft_params[softname][[1]][j], sep="")
		formula_meanofmean<-paste(formula_meanofmean, " + ",soft_params[softname][[1]][j], sep="")
	}
	#aggregate as mean per pruning
	data_mean<-aggregate(as.formula(formula_mean), current_soft_data, mean)
	#aggregate as mean of means
	data_meanofmean<-NULL;
	data_meanofmean<-aggregate(as.formula(formula_meanofmean), data_mean, mean)
	#order from best to wort parameters combination
	data_meanofmean<-data_meanofmean[order(data_meanofmean$nd),]
	data_meanofmean["software"]<-softname
	#register results
	alltables[[i]]<-data_meanofmean
	#ouputs results table per software
	print(paste("CSV table for ",softname,sep=""))
	write.table(data_meanofmean,file=paste(workdir,"/summary_table_",softname,".csv",sep=""),quote=TRUE,sep=";",dec=".",row.names=FALSE,col.names=TRUE)

}

#search for ND min/max
min_nd<-Inf
max_nd<-0
for ( i in 1:length(soft_list) ) {
	mi<-min(alltables[[i]]$nd)
	ma<-max(alltables[[i]]$nd)
	if (mi<min_nd) {
		min_nd<-mi
	}
	if (ma>max_nd) {
		max_nd<-ma
	}
}

#build all plots

global_labeller <- labeller(
  .default = label_both
)

for ( i in 1:length(soft_list) ) {
	softname<-soft_list[[i]]
	softname_short<-strsplit(softname, "_")[[1]][1]
	params<-soft_params[softname][[1]]
	#if 1 parameter, build heatmap on fake y
	if (length(params)==1) {
		alltables[[i]]["none"]<-"none"
		params<-c(params,"none")
	}
	#if more than 2 parameters, build a facet_wrap combination
	wrap_string<-"~r"
	if (length(params)>2) {
		for (j in 3:length(params)) {
			wrap_string<-paste(wrap_string,params[j],sep="+")
		}
	}
	#build aes string from 2 first params + nd as fill
	g<-ggplot( alltables[[i]], aes_string(x = sprintf("factor(%s)",params[1]) , y = sprintf("factor(%s)",params[2])  ) )
	g<-g + geom_tile(aes(fill = nd))
	g<-g + facet_wrap(as.formula(wrap_string), labeller=global_labeller)
	g<-g + geom_text(aes(label=sprintf("%0.2f", round(nd, digits = 2))))
	g<-g + scale_fill_distiller(limits=c(min_nd,max_nd),palette = "RdYlGn")
	g<-g + labs(title=paste("mean node distance for ",softname), x=paste("parameter: '",params[1],"'"), y=paste("parameter: '",params[2],"'"))
	#1.25 per parameter value + 2 for legend on the right
	svg_width<-2+(1.25*length(unique(alltables[[i]][[params[1]]])))
	svg_height<-1+(1.25*length(unique(alltables[[i]][[params[2]]])))
	CairoSVG(file =paste(workdir,"/summary_plot_",softname,".svg", sep=""),width=svg_width,height=svg_height)
	print(g)
	dev.off()
}

quit()
