#' Read in Wilderlab results spreadsheets.
#'
#' Convenience function for reading Wilderlab eDNA results spreadsheets from local Excel (.xlsx) files,
#' including splitting the metadata sheet into job and sample metadata.
#'
#' @param filepath A character string specifying path to the Wilderlab results file. Only .xlsx files are allowed. If
#'    blank, an interactive dialog box will be presented to the user.
#' @details This function is designed for easily importing Wilderlab results spreadsheets into an R environment.
#' @returns A named list of tibbles of each sheet in the xlsx file. Note the metadata sheet is separated into job and samples metadata.
#' @author Shaun Wilkinson and Susan Welsh
################################################################################
read_eDNA <- function(filepath = file.choose()){
  # Require extension to be xlsx
  ext <- tools::file_ext(filepath)
  if(!identical(ext, "xlsx")) stop("Please select a xlsx file")

  sheets <- excel_sheets(filepath)
  out <- list()

  # split metadata sheet into jobs and samples
  if("metadata" %in% sheets){

    metadata <- read_xlsx(filepath, sheet = "metadata", skip = 1)
    uidRow <- which(metadata[, 1] == "UID")
    jobmetadata <- metadata[1:(uidRow-1),1:2]
    jobmetadata <- jobmetadata %>%
      filter(!is.na(...1)) %>%
      mutate(...1 = sub(":$", "", ...1)) %>%
      pivot_wider(
        names_from = ...1,
        values_from = ...2
      )

    samplemetadata <- metadata[(uidRow+1):nrow(metadata),]
    colnames(samplemetadata) <- metadata[uidRow,]

    metadata <- list(jobs = jobmetadata,
                     samples = samplemetadata)
    out <- append(out, metadata)
  }

  # read other sheets
  sheets <- sheets[sheets != "metadata"]
  out <- append(out, sapply(sheets, function(sheet) read_xlsx(filepath, sheet = sheet), USE.NAMES = TRUE))

  # return named list
  return(out)
}
