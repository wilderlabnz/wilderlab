#' Get full lineage information for taxa.
#'
#'
#' @param taxids A numeric vector of taxids to pull taxonomic information for.
#' @param ranks A character vector of taxonomic ranks to return.
#' @param tdb Optional. A taxonomy table in `insect` package format
#' @details This function takes a vector of taxids and uses the insect package to pull the full lineage information for each taxid.
#' @returns A dataframe with one row for every taxid and one column for each rank.
#' @author Shaun Wilkinson and Susan Welsh
#' @examples
#' \donttest {
#'   eDNA <- read_eDNA()
#'   agg <- eDNA$aggregated
#'   lineages <- get_lineages(agg$TaxID)
#'   named <- merge(agg, lineages, by = "TaxID", sort = FALSE)
#'   head(named)
#'  }
#'
################################################################################
get_lineages <- function(taxids, ranks = c("Domain", "Kingdom", "Phylum", "Class", "Order", "Superfamily", "Family", "Subfamily", "Genus"), tdb = NULL){
  # confirm aggregatedData is a taxid column
  if(!is.numeric(taxids)) stop("taxids must be a numeric vector")

  if(is.null(tdb)){
    # download latest taxonomy table and convert to insect package format
    taxa <- wilderlab::get_wilderdata("taxa")
    tdb <- taxa[1:4]
    colnames(tdb) <- c("taxID", "parent_taxID", "rank", "name")
  }

  # check if all taxon IDs in the aggregatedData are in the taxonomy table
  if(!all(taxids %in% tdb$taxID)) {
    warning("taxids missing from taxonomy table. Contact Wilderlab for a refreshed version of your eDNA results")
  }

  # get lineages of taxids
  lineages <- insect::get_lineage(taxids, tdb)

  # check required ranks are in lineages
  unique_ranks <- unique(unlist(lapply(lineages, names)))
  if(!any(tolower(ranks) %in% unique_ranks)) {
    missing_ranks <- ranks[!tolower(ranks) %in% unique_ranks]
    warning("Ranks ", paste0(missing_ranks, collapse = ", "), " not in lineage information")
  }

  # make dataframe with taxids and each required rank
  out <- data.frame(TaxID = taxids)
  for(rank in ranks){
    out[rank] <- sapply(lineages, "[", tolower(rank))
  }

  return(out)
}
