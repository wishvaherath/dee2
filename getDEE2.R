#R interface to DEE2 data
#Copyright Mark Ziemann and Antony Kaspi 2016 to 2018 mark.ziemann@gmail.com

getDee2Metadata<-function(species,outfile=NULL, ...){
  orgs=c("athaliana","celegans","dmelanogaster","drerio","ecoli","hsapiens","mmusculus","rnorvegicus","scerevisiae")
  if (species %in% orgs == FALSE ) {
    message(paste("Provided species '",species,"' is not found in the list. Check spelling and try again" ,sep=""))
    message(paste("Valid choices are '",paste(orgs,collapse = "', '"),"'."))
  } else {  
    metadataURL=paste("http://dee2.io/metadata/",species,"_metadata.tsv.cut",sep="")
    if(is.null(outfile)){
      metadataname=tempfile()
    } else {
      metadataname=outfile
      if(!grepl(".tsv$",metadataname)){metadataname=paste0(metadataname,".tsv")}
    }
    download.file(metadataURL, destfile=metadataname, ...)
    mdat<-read.table(metadataname,header=T)
    if(is.null(outfile)){unlink(metadataname)}
    return(mdat)
  }
}

queryDee2<-function(species, SRRvec,metadata=NULL, ...) {
  if(is.null(metadata)){
    mdat<-getDee2Metadata(species, ...)
  } else {
    mdat<-metadata
  }
  present<-SRRvec[which(SRRvec %in% mdat$SRR_accession)]
  absent<-SRRvec[-which(SRRvec %in% mdat$SRR_accession)]
  dat <- list("present" = present, "absent" = absent)
  return(dat)
}

loadGeneCounts<-function(zipname){
  CM="GeneCountMatrix.tsv"
  TF=tempfile()
  unzip(zipname, files = CM, exdir = tempdir() )
  mxname<-paste0(tempdir(),"/",CM)
  file.rename(mxname,TF)
  dat <- read.table(TF,row.names=1,header=T)
  unlink(TF)
  return(dat)
}

loadTxCounts<-function(zipname){
  CM="TxCountMatrix.tsv"
  TF=tempfile()
  unzip(zipname, files = CM, exdir = tempdir() )
  mxname<-paste0(tempdir(),"/",CM)
  file.rename(mxname,TF)
  dat <- read.table(TF,row.names=1,header=T)
  unlink(TF)
  return(dat)
}

loadQcMx<-function(zipname){
  CM="QC_Matrix.tsv"
  TF=tempfile()
  unzip(zipname, files = CM, exdir = tempdir() )
  mxname<-paste0(tempdir(),"/",CM)
  file.rename(mxname,TF)
  dat <- read.table(TF,row.names=1,header=T,fill=T)
  unlink(TF)
  return(dat)
}

getDEE2<-function(species, SRRvec, outfile=NULL, metadata=NULL,
  baseURL="http://dee2.io/cgi-bin/request.sh?", ...){
  #dat1<-queryDee2(species, SRRvec)
  if(is.null(metadata)){
  dat1<-queryDee2(species, SRRvec)
    } else {
  dat1<-queryDee2(species, SRRvec,metadata=metadata)
  }
  absent<-dat1$absent
  present<-dat1$present
  if ( length(present) < 1 ) {
    message("Error. None of the specified SRR accessions are present.")
  } else {
#  message(paste0("Warning, datasets not found: '",paste(absent,collapse=","),"'"))
    SRRvec<-gsub(" ","",present)
    llist<-paste0("&x=",paste(SRRvec,collapse = "&x="))
    murl <- paste0(baseURL,"org=",species, llist)
    if(is.null(outfile)){
      zipname=tempfile()
    } else {
      zipname=outfile
      if(!grepl(".zip$",zipname)){zipname=paste0(zipname,".zip")}
    }
    download.file(murl, destfile=zipname, ...)

    GeneCounts<-loadGeneCounts(zipname)
    TxCounts<-loadTxCounts(zipname)
    QcMx<-loadQcMx(zipname)
    dat <- list("GeneCounts" = GeneCounts, "TxCounts" = TxCounts, "QcMx" = QcMx, "absent" = absent)
    if(is.null(outfile)){unlink(zipname)}
    if(length(absent)>0){
      message(paste0("Warning, datasets not found: '",paste(absent,collapse=","),"'"))
    }
    return(dat)
  }
}

#mytable<-getDEE("Ecoli",c("SRR922260","SRR922261"))
#data is returned as a list of three dataframes
