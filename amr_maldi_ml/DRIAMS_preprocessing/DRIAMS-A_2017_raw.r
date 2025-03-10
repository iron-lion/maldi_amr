# Read-in MALDI-TOF spectra in Brukerflex format 
# and write files to easily accessible text files.

# C. Weis Feb 2020

library("MALDIquant")
library("MALDIquantForeign")
library(stringr)

options(warn=0)

#########################################
# define paths
#########################################

SINK_FILE = paste('./log/DRIAMS-A_2017_',Sys.Date(),'.log', sep='')

sink(SINK_FILE, append=FALSE, split=FALSE)

FID_DIR = '/links/groups/borgwardt/Data/ms_diagnostics/USB/spectra_folder_for_IDRES/2017/2017_m1/'
OUT_DIR = '/links/groups/borgwardt/Data/DRIAMS/DRIAMS-A/raw/2017/'


list_files = list.files(path=FID_DIR,pattern = "fid$", recursive = TRUE)
num_files = length(list_files)

num_processed = 0
num_noid = 0

print(num_files)


#########################################
# go through files and process
#########################################

for (j in 1:length(list_files)){

    filename=paste(FID_DIR,list_files[j],sep="")
    cat(c("\n", as.character(j), filename), sep="\n")

    # get fileid
    spl = unlist(strsplit(list_files[j], "[/]"))
    idx = grepl('^[0-9]_[A-Z]([0-9]|[0-9][0-9])$',spl)
    fileid = spl[which(idx==TRUE)-1]
    print(fileid)

    if (nchar(fileid)!=36){
        print('Length fileid != 36')
        num_noid = num_noid+1
        next
    }

    # Import fid files
    myspec = importBrukerFlex(filename, removeEmptySpectra=TRUE)

    # Skip if spectra empty
    if (length(myspec) == 0){
        print('Spectra is empty')
        num_noid = num_noid+1
        next    
    }

    rawMatrix <- data.frame(mass(myspec[[1]]),intensity(myspec[[1]]))

    out_filename = paste(OUT_DIR,fileid,'_MALDI1.txt',sep="")
    print(out_filename)

    # write file
    file_con <- file(out_filename, open="wt")
    writeLines(paste("# ",filename), file_con)
    writeLines(paste("# ",fileid), file_con)
    write.table(rawMatrix,file_con,sep=" ",row.names=FALSE)
    num_processed=num_processed+1
}


#########################################
# define paths
#########################################

FID_DIR = '/links/groups/borgwardt/Data/ms_diagnostics/USB/spectra_folder_for_IDRES/2017/2017_m2/'

list_files = list.files(path=FID_DIR, pattern="fid$", recursive=TRUE)
num_files = length(list_files)

print(num_files)


#########################################
# go through files and process
#########################################

for (j in 1:length(list_files)){

    filename=paste(FID_DIR,list_files[j],sep="")
    cat(c("\n", as.character(j), filename), sep="\n")

    # get fileid
    spl = unlist(strsplit(list_files[j], "[/]"))
    idx = grepl('^[0-9]_[A-Z]([0-9]|[0-9][0-9])$',spl)
    fileid = spl[which(idx==TRUE)-1]
    print(fileid)
    
    if (nchar(fileid)!=36){
        print('Length fileid != 36')
        num_noid = num_noid+1
        next
    }

    # Import fid files
    myspec = importBrukerFlex(filename, removeEmptySpectra=TRUE)

    # Skip if spectra empty
    if (length(myspec) == 0){
        print('Spectra is empty')
        num_noid = num_noid+1
        next    
    }

    rawMatrix <- data.frame(mass(myspec[[1]]),intensity(myspec[[1]]))

    out_filename = paste(OUT_DIR,fileid,'_MALDI2.txt',sep="")
    print(out_filename)

    # write file
    file_con <- file(out_filename, open="wt")
    writeLines(paste("# ",filename), file_con)
    writeLines(paste("# ",fileid), file_con)
    write.table(rawMatrix,file_con,sep=" ",row.names=FALSE)
    num_processed = num_processed+1
}

print("number of files processed:")
print(num_processed)
print("number of no ID:")
print(num_noid)
print("Program finished!")

sink()
