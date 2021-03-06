
# --- Installation ---

install.packages("remotes")
library(remotes)

# Uncomment to Verify JAVA_HOME is set to jdk path
# Sys.getenv("JAVA_HOME")


remotes::install_github(repo = "National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition"
               ,ref = "master"
               ,subdir = "Exporters/RExporter"
               ,INSTALL_opts = "--no-multiarch"
)

# Uncomment to test for missing packages
# setdiff(c("rJava", "DatabaseConnector","SqlRender","zip","N3cOhdsi"), rownames(installed.packages()))

# load package
library(N3cOhdsi)


# --- Local configuration ---

# -- run config
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "sql server",  # options: oracle, postgressql, redshift, sql server, pdw, netezza, bigquery, sqlite
                                                          server = "", # name of the server
                                                          user="", # username to access server
                                                          password = "" #password for that user
                                                          )
cdmDatabaseSchema <- "" # schema for your CDM instance -- e.g. TMC_OMOP.dbo
resultsDatabaseSchema <- "" # schema with write privileges -- e.g. OHDSI.dbo
# tempDatabaseSchema <- "" # For Google BigQuery users only

outputFolder <-  paste0(getwd(), "/output/")  # directory where output will be stored. default provided
phenotypeSqlPath <- "" # full path of phenotype sql file (.../Phenotype_Data_Acquisition/PhenotypeScripts/your_file.sql)
extractSqlPath <- ""  # full path of extract sql file (.../Phenotype_Data_Acquisition/ExtractScripts/your_file.sql)

# FOR NLP SITES ONLY:
nlpSqlPath <- "" # full path of nlp extract sql file (.../Phenotype_Data_Acquisition/NLPExtracts/N3C_extract_nlp_mssql.sql)

# -- manifest config
siteAbbrev <- "TuftsMC" #-- unique site identifier
siteName   <- ""
contactName <- ""
contactEmail <- ""
cdmName <- "OMOP" #-- source data model. options: "OMOP", "ACT", "PCORNet", "TriNetX"
cdmVersion <- "5.3.1"
dataLatencyNumDays <- "2"  #-- this integer will be used to calculate UPDATE_DATE dynamically
daysBetweenSubmissions <- "3"  #-- this integer will be used to calculate NEXT_SUBMISSION_DATE dynamically
shiftDateYN <- "X" #-- Replace with either 'Y' or 'N' to indicate if your data is date shifted
maxNumShiftDays <- "NA" #-- Maximum number of days shifted. 'NA' if NA, 'Unknown' if shifted but days unknown






# --- Execution ---


# Generate cohort
N3cOhdsi::createCohort(connectionDetails = connectionDetails,
                        sqlFilePath = phenotypeSqlPath,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        resultsDatabaseSchema = resultsDatabaseSchema
                      # ,tempDatabaseSchema = tempDatabaseSchema
                        )

# Extract data to pipe delimited files
N3cOhdsi::runExtraction(connectionDetails = connectionDetails,
                        sqlFilePath = extractSqlPath,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        resultsDatabaseSchema = resultsDatabaseSchema,
                        outputFolder = outputFolder,
                        siteAbbrev = siteAbbrev,
                        siteName = siteName,
                        contactName = contactName,
                        contactEmail = contactEmail,
                        cdmName = cdmName,
                        cdmVersion = cdmVersion,
                        dataLatencyNumDays = dataLatencyNumDays,
                        daysBetweenSubmissions = daysBetweenSubmissions,
                        shiftDateYN = shiftDateYN,
                        maxNumShiftDays = maxNumShiftDays
                        )

# FOR NLP SITES ONLY
# Assumes OHNLP has already been run, extracts NLP data to pipe delimited files
# references path var 'nlpSqlPath'
N3cOhdsi::runExtraction(connectionDetails = connectionDetails,
                        sqlFilePath = nlpSqlPath,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        resultsDatabaseSchema = resultsDatabaseSchema,
                        outputFolder = outputFolder
)



# Compress output
zip::zipr(zipfile = paste0(siteAbbrev, "_", cdmName, "_", format(Sys.Date(),"%Y%m%d"),".zip"),
          files = list.files(outputFolder, full.names = TRUE))
