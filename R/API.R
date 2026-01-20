#' Access eDNA data from the Wilderlab API.
#'
#' Wrapper functions for creating URLs and authorization headers to download job, sample, taxa and record information
#' from the connect.wilderlab API.
#'
#' @param tb a character string specifying the table required. Accepted values are 'jobs', 'samples', 'taxa' and 'records'
#' @param key a string specifying the API access key for the client account. Not required for taxa table.
#'   Please contact info at wilderlab.co if you would like access keys generated for your account.
#' @param secret a string specifying the API secret access key for the client account. Not required for taxa table.
#'   Please contact info at wilderlab.co if you would like access keys generated for your account.
#' @param xapi a string specifying the X-API-Key value for the client account. Not required for taxa table.
#'   Please contact info at wilderlab.co if you would like access keys generated for your account.
#' @param JobID a 6 digit integer specifying a Wilderlab job number. Required for accessing the records table.
#' @details The Wilderlab API is designed for clients to access up-to-date eDNA data for their internal data storage
#'   platforms and geospatial applications. Clients can access their job, sample, taxon and eDNA records data at any time
#'   by querying the API with a valid URL and authorization header. The get_wilderdata function is a wrapper that enables
#'   these URLs and headers to be compiled with minimal effort.
#' @author Shaun Wilkinson and Susan Welsh
#' @seealso Full tutorial available at \link{wilderlab.co/api-instructions}
#' @examples
#' \donttest{
#'     key <- "AKIATVYXGCYLWADFJVEX"
#'     secret <- "SiDvZFUFXlCXK/jeBtHrfRPWMmb8veW6q5+ULuyx"
#'     xapikey <- "7CCm580l5vgeKbalwIEy565uFhbEudTauAq80B38"
#'     jobs <- get_wilderdata("jobs", key = key, secret = secret, xapikey = xapikey)
#'     samples <- get_wilderdata("samples", key = key, secret = secret, xapikey = xapikey)
#'     taxa <- get_wilderdata("taxa", key = key, secret = secret, xapikey = xapikey)
#'     records <- vector(mode = "list", length = nrow(jobs))
#'     for(i in seq_along(records)){
#'       records[[i]] <- get_wilderdata("records", JobID = jobs$JobID[i], key = key, secret = secret, xapikey = xapikey)
#'     }
#'     records <- do.call("rbind", records)
#'  }
################################################################################
get_wilderdata <- function(tb, key = NULL, secret = NULL, xapikey = NULL, JobID = NULL){
  if(tb == "records" & is.null(JobID)) stop("Please specify a valid JobID to access eDNA records")
  if(tb != "records" & !is.null(JobID)) stop("JobID is only necessary for accessing records table")
  ## require authentication details for all tables except taxa
  if(!identical(tb, "taxa")){
    if(missing(key) || is.null(key) ||
       missing(secret) || is.null(secret) ||
       missing(xapikey) || is.null(xapikey)){
      stop("Please specify valid 'key', 'secret', and 'xapikey' for tables other than 'taxa'")
    }
  }
  ## taxa table
  if(identical(tb, 'taxa')){
    tmpf <- tempfile()
    test <- download.file("https://s3.ap-southeast-2.amazonaws.com/wilderlab.examples/taxa.rds",
                          destfile = tmpf, mode = "wb")
    res <- readRDS(tmpf)
    file.remove(tmpf)
    return(res)
  }
  ## tutorial example
  if(key == "AKIATVYXGCYLWADFJVEX" &
     secret == "SiDvZFUFXlCXK/jeBtHrfRPWMmb8veW6q5+ULuyx" &
     xapikey == "7CCm580l5vgeKbalwIEy565uFhbEudTauAq80B38"){
    if(tb == "jobs"){
      tmpf <- tempfile()
      test <- download.file("https://s3.ap-southeast-2.amazonaws.com/wilderlab.examples/jobs.rds", destfile = tmpf, mode = "wb")
      res <- readRDS(tmpf)
      return(res)
    }else if (tb == "samples"){
      tmpf <- tempfile()
      test <- download.file("https://s3.ap-southeast-2.amazonaws.com/wilderlab.examples/samples.rds", destfile = tmpf, mode = "wb")
      res <- readRDS(tmpf)
      return(res)
    }else if(tb == "records"){
      tmpf <- tempfile()
      if(JobID == 601833){
        test <- download.file("https://s3.ap-southeast-2.amazonaws.com/wilderlab.examples/records601833.rds", destfile = tmpf, mode = "wb")
        res <- readRDS(tmpf)
        return(res)
      }else if(JobID == 601834){
        test <- download.file("https://s3.ap-southeast-2.amazonaws.com/wilderlab.examples/records601834.rds", destfile = tmpf, mode = "wb")
        res <- readRDS(tmpf)
        return(res)
      }else{
        return(NULL)
      }
    }
  }
  addon <- paste0("&JobID=", JobID)
  URL <- paste0("https://connect.wilderlab.co.nz/edna/?query=", tb, if(!is.null(JobID)) addon else NULL)
  d_timestamp <- format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC")
  qargs <- list(query = tb)
  if(!is.null(JobID)) qargs <- c(qargs, list(JobID = JobID))
  test <- aws.signature::signature_v4_auth(datetime = d_timestamp,
                                           service = "execute-api",
                                           verb = "GET",
                                           request_body = "",
                                           region = "ap-southeast-2",
                                           key = key,
                                           secret = secret,
                                           verbose = FALSE,
                                           action = "/edna/",
                                           query_args = qargs,
                                           canonical_headers = list(host = "connect.wilderlab.co.nz",`X-Amz-Date` = d_timestamp)
  )
  headers <- list()
  headers[["x-amz-date"]] <- d_timestamp
  headers[["Authorization"]] <- test[["SignatureHeader"]]
  headers[["X-API-Key"]] <- xapikey
  H <- do.call(httr::add_headers, headers)
  r <- suppressMessages(httr::GET(URL, H))
  dat <- rjson::fromJSON(json_str = httr::content(r, "text", encoding = "UTF-8"))
  dat <- dat$message
  tmpf <- tempfile()
  cat(dat, file = tmpf)
  res <- read.csv(tmpf)
  return(res)
}
################################################################################


