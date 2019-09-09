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





#load data
##################################################
data<-read.csv(file=args[1], sep=";", header=TRUE)
workdir=args[2]

#analysis on rappas side
##################################################
data_rappas<-data[data$software=="RAP",]
#do node distance mean per group of omega/k/readSize
data_rappas_bymean<-aggregate(node_dist ~ omega + k + readSize , data_rappas, mean)
#count how many measures per group of omega/k/readSize
sample_size<-aggregate(node_dist ~ omega + k + readSize , data_rappas, length)

brewer.div<-colorRampPalette(brewer.pal(11,"Spectral"),interpolate="spline")

#heatmap to verify which k/omega combinations are missing (often due to memory limitation)
p<-ggplot(sample_size, aes(factor(k),factor(omega),fill=node_dist)) + geom_tile() + facet_wrap(~readSize) + geom_text(aes(label=sprintf("%0.2f", round(node_dist, digits = 2))))
pdf(file=paste(workdir,"/experience_complitude.pdf",sep=""))
print(p)
dev.off()

#heatmap omega/k, per readsize and dbtype
p<-ggplot(data_rappas_bymean, aes(factor(k),factor(omega),fill=node_dist)) + geom_tile() + facet_wrap(~readSize) + geom_text(aes(label=sprintf("%0.2f", round(node_dist, digits = 2))))
pdf(file=paste(workdir,"/heatmap_komega.pdf",sep=""))
print(p)
dev.off()


#comparison best k/omega pair of rappas versus epa/pplacer
##################################################

#get k/omega intervals
min_k<-6
max_k<-max(data_rappas$k)
min_omega<-min(data_rappas$omega)
max_omega<-max(data_rappas$omega)
k_step<-2
omega_step<-0.25
#get read length interval
min_readSize<-min(data_rappas$readSize)
max_readSize<-max(data_rappas$readSize)


#change RAP labels to RAP_k6 , RAP_k8 ... RAP_k12 and demultiple dataset

#virtually build union/sunion factor for EPA/PPL
data_not_rappas<-data[data$software!="RAP",]


for ( j in seq(min_omega,max_omega,omega_step) ) {

	message(paste("- loop iteration: a=",j,sep=" "))
	#empty dataframe but but correct columns types
	comp_data<-data_rappas[FALSE,]


	for ( i in seq(min_k,max_k,k_step) ) {

		#retain placements done for a specific k/omega combination
		data_komega<-data_rappas[data_rappas$k==i & data_rappas$omega==j,]
		#change label from RAP to RAP_ki
		data_komega$software<-factor(paste("RAP_k",i,sep=""))

		message(paste("-- separating data for k=",i,sep=""))
		message(paste("-- number of points=",length(data_komega$software),sep=""))

		#merge it with EPA/PPL
		comp_data<-rbind(comp_data,data_komega)
	}

	#merge EPA / pplacer results with different rappas results
	comp_data<-rbind(comp_data,data_not_rappas)

	#number of reads placed in this experiment, per read length
	readLevels<-sort(unique(comp_data$readSize))
	points<-c()
	stringReadLevels<-""
	for ( l in seq(,length(readLevels)) )  {
		#number of points for each read length
		points[l]=length(comp_data[comp_data$software=="EPA" & comp_data$readSize==readLevels[l],]$software)
		#string version
		stringReadLevels<-paste(stringReadLevels,points[l],sep="|")
	}

	##########################
	###   1st GRAPH
	###   all placements are independant
	#output means per 
	all_means<-aggregate(node_dist~software+readSize,comp_data,mean)
	write.csv(all_means,file=paste(workdir,"/means_a",j,".csv",sep=""),row.names=FALSE)

	#before plotting, summary stats
	dd<-comp_data
	#      - error bars are base on summarySE which provides 
	#        standard deviation, standard error of the mean, and a (default 95%) confidence interval
	#        dataframe fields are:	supp dose  N   len       sd        se       ci
	#	 source: http://www.cookbook-r.com/Graphs/Plotting_means_and_error_bars_(ggplot2)/#Helper functions
	tgc <- summarySE(dd, measurevar="node_dist", groupvars=c("software","readSize"))
	#to scale Y, as facet_wrap function of ggplot has no option to set ylim
	ddplot<-dd[dd$node_dist<=12,]

	#modify a bit base theme
	theme_set(theme_grey(base_size=20))
	theme_update(axis.text.x  = element_text(angle=45, vjust=1,hjust=1))
	theme_update(strip.text.x = element_text(colour="blue",face="bold"))
	#build plot and theme
	plo<- ggplot(ddplot,aes(x=factor(software),y=node_dist),size=1) +
	facet_wrap(~ readSize,ncol=4) +
	labs(x ="Software", y = "Node distance\nto expected placement") +
	#violin on background
	geom_violin(scale = "count",omega=0.7,fill="white",color="#CCCCCC",adjust = 1.5 ) +
	#dotplot to simulate histogram beyounf violin
	geom_violin(scale = "count",omega=0.5,fill="black",color="transparent",adjust = 0.1,kernel="cosine",bw="bcv",trim=TRUE) +
	#dot a big square point, as backgroud of error bar
	#geom_point(data=tgc, color="white", omega=0.8, size=8, shape=15) +
	#line of mean
	stat_summary(data=dd,fun.data=mean_sdl, fun.args = list(mult=1), geom="line", color="red", aes(group=1), width=1.0, omega=0.8,size=0.75) +
	#do error bar
	#geom_errorbar(data=tgc, aes(ymin=node_dist-ci, ymax=node_dist+ci), width=0.12, colour="red") +
	#do point of mean itsel
	geom_point(data=tgc, color="red", shape=3,size=3)

	#need print to generate output)
	#carefull, resolution change will change geom_dotplot behaviour
	CairoSVG(file =paste(workdir,"/comparison_EPA_PPL_RAP_a",j,".svg", sep=""),width=20,height=5, )
	print(plo)
	dev.off()
	#dev.print(pdf, file=paste(workdir,"/comparison_EPA_PPL_RAP_a",j,".pdf", sep=""))
	#ggsave(file=paste(workdir,"/comparison_EPA_PPL_RAP_a",j,".pdf", sep=""), width = 4, height = 1)
	#pdf(file=paste(workdir,"/comparison_EPA_PPL_RAP_a",j,".pdf", sep=""),width=2048,height=450)
	#print(plo)
	#dev.off()
	message(paste("- wrote file: comparison_EPA_PPL_RAP_k",i,"a",j,".pdf",sep="_"))

	##########################
	###   2nd GRAPH
	###   mean per pruning experiment, violins + jittered points based on 100 values
	
	#aggregate to get 100 values per software/readSize
	meanPerPruning<-aggregate(node_dist~Ax+software+readSize,comp_data,mean)
	
	#aggregate again to means of means
	all_means_meanPerPruning<-aggregate(node_dist~software+readSize,meanPerPruning,mean)
	write.csv(all_means_meanPerPruning,file=paste(workdir,"/meansofmeansperpruning_a",j,".csv",sep=""),row.names=FALSE)

	#before plotting, summary stats
	ddPerPruning<-meanPerPruning
	#      - error bars are base on summarySE which provides 
	#        standard deviation, standard error of the mean, and a (default 95%) confidence interval
	#        dataframe fields are:	supp dose  N   len       sd        se       ci
	#	 source: http://www.cookbook-r.com/Graphs/Plotting_means_and_error_bars_(ggplot2)/#Helper functions
	tgcPerPruning <- summarySE(ddPerPruning, measurevar="node_dist", groupvars=c("software","readSize"))
	#to scale Y, as facet_wrap function of ggplot has no option to set ylim
	ddplotPerPruning<-ddPerPruning[ddPerPruning$node_dist<=12,]

	#modify a bit base theme
	theme_set(theme_grey(base_size=20))
	theme_update(axis.text.x  = element_text(angle=45, vjust=1,hjust=1))
	theme_update(strip.text.x = element_text(colour="blue",face="bold"))
	#build plot and theme
	plo<- ggplot(ddplotPerPruning,aes(x=factor(software),y=node_dist),size=1) +
	facet_wrap(~ readSize,ncol=4) +
	labs(x ="Software", y = "Node distance\nto expected placement") +
	#violin on background
	geom_violin(fill="white",color="#CCCCCC",adjust = 1.0, bw=1.0 ) +
	#dotplot to simulate histogram beyounf violin
	#geom_violin(scale = "count",omega=0.5,fill="black",color="transparent",adjust = 0.1,kernel="cosine",bw="bcv",trim=TRUE) +
	geom_jitter(height = 0, width = 0.18, size=0.1) +
	#dot a big square point, as backgroud of error bar
	#geom_point(data=tgcPerPruning, color="white", omega=0.8, size=8, shape=15) +
	#line of mean
	stat_summary(data=ddPerPruning,fun.data=mean_sdl, fun.args = list(mult=1), geom="line", color="red", aes(group=1), width=1.0, omega=0.8,size=0.75) +
	#do error bar
	#geom_errorbar(data=tgcPerPruning, aes(ymin=node_dist-ci, ymax=node_dist+ci), width=0.12, colour="red") +
	#do point of mean itsel
	#geom_point(data=tgcPerPruning, color="red", shape=3,size=3)
	#set Y scale
	coord_cartesian(ylim=c(0, 13)) + scale_y_continuous(breaks=seq(0,12,2))

	#need print to generate output)
	#carefull, resolution change will change geom_dotplot behaviour
	CairoSVG(file =paste(workdir,"/meanperpruningcomparison_EPA_PPL_RAP_a",j,".svg", sep=""),width=20,height=5, )
	print(plo)
	dev.off()
	#dev.print(pdf, file=paste(workdir,"/comparison_EPA_PPL_RAP_a",j,".pdf", sep=""))
	#ggsave(file=paste(workdir,"/comparison_EPA_PPL_RAP_a",j,".pdf", sep=""), width = 4, height = 1)
	#pdf(file=paste(workdir,"/comparison_EPA_PPL_RAP_a",j,".pdf", sep=""),width=2048,height=450)
	#print(plo)
	#dev.off()
	message(paste("- wrote file: meanperpruningcomparison_EPA_PPL_RAP_k",i,"a",j,".pdf",sep="_"))


	##########################
	###   3rd GRAPH
	###   mean per pruning experiment, boxplots based on 100 values
	
	#modify a bit base theme
	theme_set(theme_grey(base_size=20))
	theme_update(axis.text.x  = element_text(angle=45, vjust=1,hjust=1))
	theme_update(strip.text.x = element_text(colour="blue",face="bold"))
	#build plot and theme
	plo<- ggplot(ddplotPerPruning,aes(x=factor(software),y=node_dist),size=1) +
	facet_wrap(~ readSize,ncol=4) +
	labs(x ="Software", y = "Node distance\nto expected placement") +
	#violin on background
	geom_boxplot(adjust=1.5) +
	#line of mean
	stat_summary(data=ddPerPruning,fun.data=mean_sdl, fun.args = list(mult=1), geom="line", color="red", aes(group=1), width=1.0, omega=0.8,size=0.75) 
	#do error bar
	#geom_errorbar(data=tgcPerPruning, aes(ymin=node_dist-ci, ymax=node_dist+ci), width=0.12, colour="red") +
	#do point of mean itsel
	#geom_point(data=tgcPerPruning, color="red", shape=3,size=3)

	#need print to generate output)
	#carefull, resolution change will change geom_dotplot behaviour
	CairoSVG(file =paste(workdir,"/bp_meanperpruningcomparison_EPA_PPL_RAP_a",j,".svg", sep=""),width=20,height=5, )
	print(plo)
	dev.off()
	#dev.print(pdf, file=paste(workdir,"/comparison_EPA_PPL_RAP_a",j,".pdf", sep=""))
	#ggsave(file=paste(workdir,"/comparison_EPA_PPL_RAP_a",j,".pdf", sep=""), width = 4, height = 1)
	#pdf(file=paste(workdir,"/comparison_EPA_PPL_RAP_a",j,".pdf", sep=""),width=2048,height=450)
	#print(plo)
	#dev.off()
	message(paste("- wrote file: bp_meanperpruningcomparison_EPA_PPL_RAP_k",i,"a",j,".pdf",sep="_"))

}


quit()





