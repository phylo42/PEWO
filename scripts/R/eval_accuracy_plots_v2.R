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

# Association software/parameters
# Need to be manually defined prior to analysis
# There should not be new placement software too
# often, so this is manageable.
#################################################

soft_list<-list("epa", "epang_h1", "epang_h2", "epang_h3", "epang_h4", "pplacer", "rappas", "apples")

epa<-c("g")
epang_h1<-c("g")
epang_h2<-c("bigg")
epang_h3<-c()
epang_h4<-c()
pplacer<-c("ms","sb","mp")
rappas<-c("k","o","red")
apples<-c("m","c")

soft_params<-list(epa=epa,epang_h1=epang_h1,epang_h2=epang_h2,epang_h3=epang_h3,epang_h4=epang_h4,pplacer=pplacer,rappas=rappas,apples=apples)


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
	#select data for current software
	if (softname_short!="epang") {
		current_soft_data<-data[data$software==softname_short,]
	} else {
		heur<-substr(strsplit(softname, "_")[[1]][2],2,10)
		current_soft_data<-data[data$software==softname_short & data$h==as.numeric(heur),]
	}
	#remove columns with only NA, meaning this parameter was not linked to current soft
	current_soft_data<-current_soft_data[, colSums(is.na(current_soft_data)) != nrow(current_soft_data)]
	#build formulas dynamically fro parameters
	formula_mean<-"nd ~ pruning + r"
	formula_meanofmean<-"nd ~ r"
	if (length(soft_params[softname][[1]])>0) {  #is ==0 when no params
		for ( j in 1:length(soft_params[softname][[1]] ) ) {
			formula_mean<-paste(formula_mean, " + ",soft_params[softname][[1]][j], sep="")
			formula_meanofmean<-paste(formula_meanofmean, " + ",soft_params[softname][[1]][j], sep="")
		}
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
	#if 0 parameter, build heatmap on fake x/y
	if (length(params)==0) {
		alltables[[i]]["none"]<-"none"
		params<-c(params,"none")
	}

	#if 1 parameter, build heatmap on fake y
	if (length(params)==1) {
		alltables[[i]]["none"]<-"none"
		params<-c(params,"none")
	}
	#if more than 2 parameters, build a facet_wrap combination
	wrap_string<-"~r"
	wrapcount<-0
	if (length(params)>2) {
		for (j in 3:length(params)) {
			wrap_string<-paste(wrap_string,params[j],sep="+")
			wrapcount<-wrapcount+1
		}
	}
	#build aes string from 2 first params + nd as fill
	g<-ggplot( alltables[[i]], aes_string(x = sprintf("factor(%s)",params[1]) , y = sprintf("factor(%s)",params[2])  ) )
	g<-g + geom_tile(aes(fill = nd))
	g<-g + facet_wrap(as.formula(wrap_string), labeller=global_labeller)
	g<-g + geom_text(aes(label=sprintf("%0.2f", round(nd, digits = 2))))
	g<-g + scale_fill_distiller(limits=c(min_nd,max_nd),palette = "RdYlGn")
	g<-g + labs(title=paste("mean ND: ",softname), x=paste("parameter: '",params[1],"'"), y=paste("parameter: '",params[2],"'"))
	#1.25 per (parameter value + #param in facet_wrap) + 2 for legend on the right
	svg_width<-2+(1.25*length(unique(alltables[[i]][[params[1]]])))
	svg_height<-1+( 1.00* ( length(unique(alltables[[i]][[params[2]]])) + (2*wrapcount) ) )
	CairoSVG(file =paste(workdir,"/summary_plot_",softname,".svg", sep=""),width=svg_width,height=svg_height)
	print(g)
	dev.off()
}

#quit()
