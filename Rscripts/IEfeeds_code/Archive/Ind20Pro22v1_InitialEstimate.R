###############################################
#                                             #
#   This is the IE data feed for processing   #
#     raw data of the iron and steel PIOT     #
#     it covers 20 processes and 22 products  #
#                                             #
###############################################
# IE feed for 20 industries/processes and 22 products base classifications
# hanspeter.wieland@wu.ac.at (c)
# 02.19.2020 

# In case the code is executed not on the server (and the GUI) for debugging, 
# the user can choose the desired region aggregator by setting the following variable
# either to 5,35 or 49. If test_regagg is not defined it will be set automatically to 
# 5 regions later on in the code.
# test_regagg <- "049"

################################################################################
# 1. Set up environment for building the initial estimate

IEdatafeed_name <- "Ind20Pro22v1" 
print(paste0("Start of ",IEdatafeed_name," InitialEstimate."))

# Set library path when running on suphys server
if(Sys.info()[1] == "Linux"){
  .libPaths("/suphys/hwie3321/R/x86_64-redhat-linux-gnu-library/3.5")
  # Define location for root directory
  root_folder <- "/import/emily1/isa/IELab/Roots/PIOLab/"}else{
  root_folder <- "C:/Users/hwieland/Github workspace/PIOLab/"}

# Initializing R script (load R packages and set paths to folders etc.)
source(paste0(root_folder,"Rscripts/Subroutines/InitializationR.R"))

# Read base regions, products and codes from mat-file if available
source(paste0(path$root,"Rscripts/Subroutines/Read_BaseClassification.R"))

# Read region aggregation from classification to set the right path for the IE data
if(max(base$region$Code) < 10) {regagg <- paste0("00",max(base$region$Code))} else
{regagg <- paste0("0",max(base$region$Code))}

# Set additional paths that are specific to the present run
path[["IE_Subroutines"]] <- paste0(path$root,"Rscripts/IEfeeds_code/IE_subroutines")
path[["IE_Processed"]] <- paste0(path$root,"ProcessedData/",IEdatafeed_name,"/",regagg)
path[["Agg_Processed"]] <- paste0(path$root,"ProcessedData/",IEdatafeed_name)

remove(regagg)

# Check whether output folder for processed data for the present initial estimate exists, if not then create it
if(!dir.exists(path$Agg_Processed)) dir.create(path$Agg_Processed)

# Check whether output folder for processed data for the specific aggregation exists, if yes, delete it
if(dir.exists(path$IE_Processed)) unlink(path$IE_Processed,recursive = TRUE) 
dir.create(path$IE_Processed)

# Check if ALANG files of old initial estimate exist and delete
source(paste0(path$Subroutines,"/DeleteALANGfilesOfOldIEfeeds.R"))

################################################################################
# 2. Commencing data feeds

# Loading production values for semi- and finished steel + information on yields
source(paste0(path$IE_Subroutines,"/IEFeed_PIOLab_WSA.R"))
IEFeed_PIOLab_WSA(year,path)
source(paste0(path$IE_Subroutines,"/IEFeed_PIOLab_SteelIndustryYields.R"))
IEFeed_PIOLab_SteelIndustryYields(path)

# Loading the trade data
source(paste0(path$IE_Subroutines,"/IEFeed_PIOLab_BACI.R"))
IEFeed_PIOLab_BACI(year,path)

# The extraction and ore grade feed
source(paste0(path$IE_Subroutines,"/IEFeed_PIOLab_IRP.R"))
IEFeed_PIOLab_IRP(year,path)
source(paste0(path$IE_Subroutines,"/IEFeed_PIOLab_Grades.R"))
IEFeed_PIOLab_Grades(path)

# Loading end-of-life steel scrap
source(paste0(path$IE_Subroutines,"/IEFeed_PIOLab_EOL.R"))
IEFeed_PIOLab_EOL(year,path)

# Loading energy data
source(paste0(path$IE_Subroutines,"/IEFeed_PIOLab_IEA.R"))
IEFeed_PIOLab_IEA(year,path)

# Loading and aggregating EXIOBASE Waste-MFA IO version
source(paste0(path$IE_Subroutines,"/IEFeed_PIOLab_EXIOWasteMFAIO.R"))
IEFeed_PIOLab_EXIOWasteMFAIO(year,path)

# Loading fabrication yields taken from Cullen et al 2012
source(paste0(path$IE_Subroutines,"/IEFeed_PIOLab_Cullen.R"))
IEFeed_PIOLab_Cullen(path)

################################################################################
# 3. Commencing data processing

# Aligning WSA and IEA data and filling gaps in WSA accounts. 
# Moreover, remove BACI trade flows of iron ores for regions where IRP reports no extraction
source(paste0(path$IE_Subroutines,"/IEDataProcessing_PIOLab_AligningData.R"))
IEDataProcessing_PIOLab_AligningData(year,path)

# Compile extension for the MFA-Waste IO Model and estimate fabrication scrap
source(paste0(path$IE_Subroutines,"/IEDataProcessing_PIOLab_WasteMFAIOExtension.R"))
IEDataProcessing_PIOLab_WasteMFAIOExtension(year,path)

# Run Waste-IO Model calculation
source(paste0(path$IE_Subroutines,"/IEDataProcessing_PIOLab_WasteMFAIOModelRun.R"))
IEDataProcessing_PIOLab_WasteMFAIOModelRun(year,path)

# Compile domestic SUTs
source(paste0(path$IE_Subroutines,"/IEDataProcessing_PIOLab_BuildingDomesticTables.R"))
IEDataProcessing_PIOLab_BuildingDomesticTables(year,path)

# Compiling trade blocks
source(paste0(path$IE_Subroutines,"/IEDataProcessing_PIOLab_BuildingTradeBlocks.R"))
IEDataProcessing_PIOLab_BuildingTradeBlocks(year,path)

################################################################################
# 4. Create S8 files (see AISHA manual annex for further information) for easy data import to AISHA 
   
source(paste0(path$IE_Subroutines,"/IEDataProcessing_PIOLab_BuildS8fromSupplyUseTables.R"))
IEDataProcessing_PIOLab_BuildS8fromSupplyUseTables(year,path)

################################################################################
# 5. Write ALANG commands
print("Start writing ALANG commands.")

# Set up wrapper for adding rows to ALANG
NewALANG <- function(name,SE,ALANG)
{
  file <- paste0("S8 ",path$mother,"Data/IE/",gsub("-","",Sys.Date()),
                 "_PIOLab_AllCountriesS8File_",name,year,".csv")
  
  ALANG <- add_row(ALANG,'1' = name,Coef1 = file, S.E. = SE,
                   Value = "I",Incl = "Y",Parts = "1",'Row parent' = "",'Row child' = "",
                   'Row grandchild' = "",'Column parent' = "",'Column child' = "",
                   'Column grandchild' = "",Years = "",Margin = "",'Pre-map' = "",'Post-map' = "",
                   'Pre-Map' = "",'Post-Map' = "")
  
  return(ALANG)
}

n_reg <- nrow(base$region)
# Create empty file with header
source(paste0(path$Subroutines,"/makeALANGheadline.R"))

# Write ALANG commands
ALANG <- NewALANG("Supply","E MX1;MN10;",ALANG)
ALANG <- NewALANG("Use","E MX1;MN10;CN1;",ALANG)
ALANG <- NewALANG("FinalDemand","E MX1;MN10;",ALANG)
ALANG <- NewALANG("Extraction","E MX1;MN10;",ALANG)
ALANG <- NewALANG("EolScrap","E MX1;MN10;",ALANG)
ALANG <- NewALANG("OtherInput","E MX1;MN10;",ALANG)
ALANG <- NewALANG("Waste","E MX1;MN10;",ALANG)
ALANG <- NewALANG("Zero","E CN1;",ALANG)

ALANG$`#` <- as.character(1:nrow(ALANG))

# Write data frame with ALANG commands as tab-delimited txt-file to root and working directory (mother)
# Note HP: This is probably not the normal procedure, meaning no IE ALANG's in the root
filename <-  paste0(path$root,"ALANGfiles/",gsub("-","",Sys.Date()),
                    "_PIOLab_SUT_000_InitialEstimate-",year,"_000_S8filesForAllRegionsAndFlows.txt")

write.table(ALANG,file = filename,row.names = FALSE, quote = F,sep = "\t")
# Check if the mother directory really exists
if(file.exists(path$mother))
{ 
  filename <-  paste0(path$mother,gsub("-","",Sys.Date()),
                      "_PIOLab_SUT_000_InitialEstimate-",year,"_000_S8filesForAllRegionsAndFlows.txt")
  
  write.table(ALANG,file = filename,row.names = FALSE, quote = F,sep = "\t") 
}
  
print(paste0("End of ",IEdatafeed_name," InitialEstimate."))
