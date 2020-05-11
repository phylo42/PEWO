#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

# test if there is at least one argument
if (length(args)<1) {
    stop("The directory containing benchmark results must be supplies as 1st argument.\n", call.=FALSE)
}

library(RColorBrewer)
library(grid)
library(ggplot2)
library(Cairo)
library(data.table)
library(stringr)

workdir=args[1]

#definition of software paramters

epa<-c("g")
epang_h1<-c("g")
epang_h2<-c("bigg")
epang_h3<-NULL
epang_h4<-NULL
pplacer<-c("ms","sb","mp")
rappasdbbuild<-c("k","o","red","ar")
rappasplacement<-c("k","o","red","ar")
apples<-c("meth","crit")
hmmbuild<-NULL
ansrec<-c("red","ar")
appspam<-c("assignmentmode","filteringthreshold","d")


soft_params<-list(
                    "epa-placement"=epa,
                    "epang-h1-placement"=epang_h1,
                    "epang-h2-placement"=epang_h2,
                    "epang-h3-placement"=epang_h3,
                    "epang-h4-placement"=epang_h4,
                    "pplacer-placement"=pplacer,
                    "rappas-dbbuild"=rappasdbbuild,
                    "rappas-placement"=rappasplacement,
                    "apples-placement"=apples,
                    "hmm-align"=hmmbuild,
                    "ansrec"=ansrec,
                    "appspam"=appspam
                )



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

    print(split)
    print(paste0("OP:", op))

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

#convert numeric columns from string to numeric
df["s"]<-as.numeric(df$s)
df["max_rss"]<-as.numeric(df$max_rss)
df["max_vms"]<-as.numeric(df$max_vms)
df["max_uss"]<-as.numeric(df$max_uss)
df["max_pss"]<-as.numeric(df$max_pss)
df["io_in"]<-as.numeric(df$io_in)
df["io_out"]<-as.numeric(df$io_out)
df["mean_load"]<-as.numeric(df$mean_load)

write.table(df,file=paste0(workdir,"/resources.tsv"),row.names=FALSE, na="",col.names=TRUE, sep="\t",quote=TRUE)

#define list of operations that were actually tested and remove them from soft_list and soft_param accordingly
op_analyzed<-unique(df$operation)
if ("epang" %in% op_analyzed) {
    op_analyzed<-op_analyzed[-match("epang",op_analyzed)]
    heur<-unique(df$h)
    heur<-heur[!is.na(heur)]
    for (h in heur) {
        op_analyzed<-c(op_analyzed,paste0("epang_h",h))
    }
}

#do a mean over repeats.
#do do so build one aggregate formula per operation

results_per_op<-list()

#results <- data.frame(fake="", stringsAsFactors=FALSE)
#results <- results[-1,]


#for each $ressource parameter
ressource<-names(df)[c(1,3:9)]
i<-1
for (opname in op_analyzed) {
    j<-1
    for (ress in ressource) {

        formula_mean<-paste0(ress," ~ operation")
        if (length(soft_params[opname][[1]])>0) {  #is ==0 when no params
            for ( p in 1:length(soft_params[opname][[1]] ) ) {
                formula_mean<-paste(formula_mean, " + ",soft_params[opname][[1]][p], sep="")
            }
        }
        #aggregate as mean per pruning
        data<-NULL
        data<-df[df$operation==opname,]
        data_mean<-aggregate(as.formula(formula_mean), data, mean)
        data_sd<-aggregate(as.formula(formula_mean), data, sd)  # not used for now, but could add error bars to barplots

        #put per software results in a list
        if (j==1) {

            #create label from parameter combination as last column
            labels<-c()
            colnames<-names(data_mean)
            for (line in 1:dim(data_mean)[1]) {
                label<-paste0(data_mean[line,1],"_")
                for ( col in 2:(length(colnames)-1)) {
                    label<-paste0(label,colnames[col],data_mean[line,col],"_")
                }
                labels[line]<-label
            }
            data_mean["labels"]<-labels
            #print(data_mean)
            #add very first dataframes in list
            results_per_op[[i]]<-data_mean


        } else { #only add mean of current ressource
            results_per_op[[i]][ress]<-data_mean[ress]
        }

        j<-j+1
    }#end of ressource loop


    i<-i+1
}#end of op_analyzed loop
names(results_per_op)<-op_analyzed

###################################################
###################################################
###################################################

## PLOTS SECTION

#here, manual selection of which stats are output as plots
stats_to_plot<-c("s","max_pss")
human_readable_name<-c("Seconds","PSS Memory (Mo)")


###########################################
## PLOTS 1 : summary plot per operation


for (op in 1:length(results_per_op)) {
    svg_width<-2+(0.5*dim(results_per_op[[op]])[1]) #0.5 per column + margins
    svg_height<-2+(nchar(max(results_per_op[[op]]$labels))*0.1)
    for (i in 1:length(stats_to_plot)) {
        CairoSVG(file =paste(workdir,"/summary_plot_RES_",op_analyzed[op],"_",stats_to_plot[i],".svg", sep=""),width=svg_width,height=svg_height)
        #g<-ggplot(data=results_per_op[[op]], aes(x=reorder(labels,formula(stats_to_plot[i])),y=formula(stats_to_plot[i])) ) +
        g<-ggplot(data=results_per_op[[op]], aes_string(x = sprintf("reorder(labels,%s)",stats_to_plot[i]) , y = sprintf("%s",stats_to_plot[i])) ) +
          geom_bar(stat="identity") +
          theme(axis.text.x = element_text(angle = -90,hjust=0,vjust=0.5)) +
          labs(x="Parameters", y=human_readable_name[i])
        print(g)
        dev.off()
    }
}

###########################################
## PLOTS 2 : summary plot of all operations

#merge dataframes and use only "operation","label","$ressource" columns
merged<-NULL
for (op in results_per_op) {
    if (is.null(merged)) {
        merged<-op[,c("operation","labels",stats_to_plot)]
    } else {
        merged<-rbind(merged,op[,c("operation","labels",stats_to_plot)])
    }
}
svg_width<-2+(0.5*dim(merged)[1]) #0.5 per column + margins
svg_height<-2+(nchar(max(merged$labels))*0.1)
for (i in 1:length(stats_to_plot)) {
    CairoSVG(file =paste(workdir,"/summary_plot_RES_all_",stats_to_plot[i],".svg", sep=""),width=svg_width,height=svg_height)
    #g<-ggplot(data=results_per_op[[op]], aes(x=reorder(labels,formula(stats_to_plot[i])),y=formula(stats_to_plot[i])) ) +
    g<-ggplot(data=merged, aes_string(x = sprintf("reorder(labels,%s)",stats_to_plot[i]) , y = sprintf("%s",stats_to_plot[i])) ) +
      geom_bar(stat="identity") +
      theme(axis.text.x = element_text(angle = -90,hjust=0,vjust=0.5)) +
      labs(x="Parameters", y=human_readable_name[i])
    print(g)
    dev.off()
}

###########################################
## time for full analysis
#  e.g (align + placement)*sample for alignment-based approaches
#       ansrec + dbbuild + placement*sample for alignment-free approches

#this section NEEDS improvements, it is not dynamic as previous plots

#associate operations to analyses
analyses<-list()
analyses["epa"]<-c("hmmer-align", "epa-placement")
analyses["epang_h1"]<-c("hmmer-align", "epang-h1-placement")
analyses["epang_h2"]<-c("hmmer-align", "epang-h2-placement")
analyses["epang_h3"]<-c("hmmer-align", "epang-h3-placement")
analyses["epang_h4"]<-c("hmmer-align", "epang-h4-placement")
analyses["pplacer"]<-c("hmmer-align", "pplacer-placement")
analyses["apples"]<-c("hmmer-align", "apples-placement")
analyses["rappas"]<-c("ansrec", "rappas-dbbuild","rappas-placement")

results<-list()

#rappas times in seconds: AR + dbbuild + placement
ansrec_and_dbbuild<-merge(results_per_op["ansrec"][[1]],results_per_op["rappas-dbbuild"][[1]],by=c("red","ar"))
all_op<-merge(ansrec_and_dbbuild,results_per_op["rappas-placement"][[1]],by=c("red","ar","o","k"))

#time for 1 analysis: AR + dbbuild + placement
all_op["sample_x1"]<-all_op["s.x"]+all_op["s.y"]+all_op["s"]

#time for 1000 analyses : AR + dbbuild + 100 placements
all_op["sample_x1000"]<-all_op["s.x"]+all_op["s.y"]+all_op["s"]*1000
all_op["operation"]<-"rappas"

#results= simplier table
results[[1]]<-all_op[,c("operation","labels","k","o","red","ar","sample_x1","sample_x1000")]
op_analyzed<-c("rappas")
#create label from parameter combination as last column
results[[1]]["labels_short"]<-rep("",dim(results[[1]])[1])
for (line in 1:dim(results[[1]])[1]) {
    label<-""
    elts<-strsplit(results[[1]][line,"labels"],"_")[[1]]
    for ( idx in 2:length(elts)) {
        label<-paste0(label,elts[idx],"_")
    }
    results[[1]][line,"labels_short"]<-label
}

#alignment-based times in seconds: align + placement
i<-2
for ( op in names(results_per_op)) {
    if ( op=="ansrec" || op=="rappas-dbbuild" || op=="rappas-placement" || op=="hmmer-align") {
        next
    }
    results_per_op[op][[1]]["sample_x1"]<-results_per_op[op][[1]]["s"]
    for (line in 1:dim(results_per_op[op][[1]])[1]) {
        results_per_op[op][[1]]["sample_x1"][line,]<-results_per_op[op][[1]]["s"][line,]+results_per_op[op][[1]]["s"][1,]
    }
    results_per_op[op][[1]]["sample_x1000"]<-results_per_op[op][[1]]["s"]
    for (line in 1:dim(results_per_op[op][[1]])[1]) {
        results_per_op[op][[1]]["sample_x1000"][line,]<-results_per_op[op][[1]]["s"][line,]*1000+results_per_op["hmmer-align"][[1]]["s"][1,]*1000
    }
    #results= simplier table
    op_analyzed<-c(op_analyzed,op)
    results[[i]]<-results_per_op[op][[1]][,c("operation","labels",soft_params[op][[1]],"sample_x1","sample_x1000")]
    #create label from parameter combination as last column
    results[[i]]["labels_short"]<-rep("",dim(results[[i]])[1])
    for (line in 1:dim(results[[i]])[1]) {
        label<-""
        elts<-strsplit(results[[i]][line,"labels"],"_")[[1]]
        for ( idx in 2:length(elts)) {
            label<-paste0(label,elts[idx],"_")
        }
        results[[i]][line,"labels_short"]<-label
    }

    i<-i+1
}
names(results)<-op_analyzed

###########################################
## PLOTS 1 : summary plot per operation


for (op in 1:length(results)) {
    svg_width<-2+(0.2*dim(results[[op]])[1]) #0.5 per column + margins
    svg_height<-2+(nchar(max(results[[op]]$labels))*0.1)
    CairoSVG(file =paste0(workdir,"/summary_plot_1sample_",op_analyzed[op],".svg"),width=svg_width,height=svg_height)
    #g<-ggplot(data=results_per_op[[op]], aes(x=reorder(labels,formula(stats_to_plot[i])),y=formula(stats_to_plot[i])) ) +
    g<-ggplot( data=results[[op]], aes(x = reorder(labels_short,sample_x1) , y = sample_x1) ) +
      geom_bar(stat="identity",width=0.5) +
      theme(axis.text.x = element_text(angle = -90,hjust=0,vjust=0.5)) +
      labs(x="Parameters", y="Seconds for 1 sample")
    print(g)
    dev.off()
    CairoSVG(file =paste0(workdir,"/summary_plot_1000samples_",op_analyzed[op],".svg"),width=svg_width,height=svg_height)
    #g<-ggplot(data=results_per_op[[op]], aes(x=reorder(labels,formula(stats_to_plot[i])),y=formula(stats_to_plot[i])) ) +
    g<-ggplot( data=results[[op]], aes(x = reorder(labels_short,sample_x1000) , y = sample_x1000) ) +
      geom_bar(stat="identity",width=0.5) +
      theme(axis.text.x = element_text(angle = -90, hjust=0,vjust=0.5)) +
      labs(x="Parameters", y="Seconds for 1000 sample")
    print(g)
    dev.off()
}

###########################################
## PLOTS 2 : summary plot of all operations

#merge dataframes and use only "operation","label","$ressource" columns
merged<-NULL
for (op in results) {
    if (is.null(merged)) {
        merged<-op[,c("operation","labels","labels_short","sample_x1","sample_x1000")]
    } else {
        merged<-rbind(merged,op[,c("operation","labels","labels_short","sample_x1","sample_x1000")])
    }
}

svg_width<-2+(0.2*dim(merged)[1]) #0.5 per column + margins
svg_height<-2+(nchar(max(merged$labels))*0.1)
CairoSVG(file =paste0(workdir,"/summary_plot_1sample_ALL.svg"),width=svg_width,height=svg_height)
#g<-ggplot(data=results_per_op[[op]], aes(x=reorder(labels,formula(stats_to_plot[i])),y=formula(stats_to_plot[i])) ) +
g<-ggplot(data=merged, aes(x = reorder(labels,sample_x1), y = sample_x1 ) ) +
  geom_bar(stat="identity",width=0.5) +
  theme(axis.text.x = element_text(angle = -90, hjust=0,vjust=0.5)) +
  labs(x="Parameters", y="Seconds for 1 sample")
print(g)
dev.off()
CairoSVG(file =paste0(workdir,"/summary_plot_1000sample_ALL.svg"),width=svg_width,height=svg_height)
#g<-ggplot(data=results_per_op[[op]], aes(x=reorder(labels,formula(stats_to_plot[i])),y=formula(stats_to_plot[i])) ) +
g<-ggplot(data=merged, aes(x = reorder(labels,sample_x1000), y = sample_x1000 )) +
  geom_bar(stat="identity",width=0.5) +
  theme(axis.text.x = element_text(angle = -90, hjust=0,vjust=0.5)) +
  labs(x="Parameters", y="Seconds for 1000 sample (log10)") +
  scale_y_continuous(trans='log10')
print(g)
dev.off()
