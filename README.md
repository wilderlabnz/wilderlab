------------------------------------------------------------------------

# Wilderlab R package

The `wilderlab` R package contains functions for importing and exporting
eDNA data

## connect.wilderlab API Instructions

### 1. Installation

To download the package from GitHub, ensure that `devtools` is
installed:

    if(!("devtools" %in% list.files(.libPaths()))) install.packages("devtools")

Then run:

    devtools::install_github("wilderlabnz/wilderlab") 
    library(wilderlab)

### 2. Load access keys

When singing up to the Wilderlab API, your unique log in information
will be securely sent to you. This will include three access keys: an
API access key id, `key`; a secret access key, `secret`; and a
X-API-Key, `xapikey`.  
Copy and paste this unique information into the appropriate slots in the
following code to load them into your R session.

    key <- "*****************"
    secret <- "***************************************"
    xapikey <- "***************************************"

### 3. `get_wilderdata` function

#### Description

Wrapper functions for creating URLs and authorisation headers to
download job, sample, taxa, and record information from the
connect.wilderlab API.

#### Usage

    get_wilderdata(tb, key, secret, xapikey, JobID = NULL)

#### Arguments

<table>
<colgroup>
<col style="width: 18%" />
<col style="width: 81%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">Argument</th>
<th style="text-align: left;">Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;"><code>tb</code></td>
<td style="text-align: left;">a character string specifying the table required. Accepted values are <code>jobs</code>, <code>samples</code>, <code>taxa</code>, and <code>records</code>.</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>key</code></td>
<td style="text-align: left;">a string specifying the API access key for the client account. Please contact <a href="mailto:info@wilderlab.co.nz" class="email">info@wilderlab.co.nz</a> if you would like access keys generated for your account.</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>secret</code></td>
<td style="text-align: left;">a string specifying the API secret access key for the client account. Please contact <a href="mailto:info@wilderlab.co.nz" class="email">info@wilderlab.co.nz</a> if you would like access keys generated for your account.</td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>xapikey</code></td>
<td style="text-align: left;">a string specifying the X-API-Key value for the client account. Please contact <a href="mailto:info@wilderlab.co.nz" class="email">info@wilderlab.co.nz</a> if you would like access keys generated for your account.</td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>JobID</code></td>
<td style="text-align: left;">a 6 digit integer specifying a Wilderlab job number. Required only for accessing the records table.</td>
</tr>
</tbody>
</table>

#### Details

The Wilderlab API is designed for clients to access up-to-date eDNA data
for their internal data storage platforms and geospatial applications.
Clients can access their job, sample, taxon and eDNA records data at any
time by querying the API with a valid URL and authorization header. The
`get_wilderdata` function is a wrapper that enables these URLs and
headers to be compiled with minimal effort.

### 4. Get data tables

Pulling information from the `job`, `samples`, and `taxa` tables is very
straightforward. All the information associated with a unique API access
key is accessed as a whole:

    jobs <- get_wilderdata("jobs", key = key, secret = secret, xapikey = xapikey)
    samples <- get_wilderdata("samples", key = key, secret = secret, xapikey = xapikey)
    taxa <- get_wilderdata("taxa", key = key, secret = secret, xapikey = xapikey)

Pulling from the `records` table is done on a specified JobID thus
multiple calls must be made to get a full records table. After accessing
the `jobs` table, the relevant JobIDs can be iterated over, the
corresponding records pulled through the API, and finally the gathered
records combined into a complete records table. The following code chunk
is an example of how this can be done.

    records <- vector(mode = "list", length = nrow(jobs))
    for(i in seq_along(records)){
      records[[i]] <- get_wilderdata("records", JobID = jobs$JobID[i],
                                     key = key, secret = secret, xapikey = xapikey)
    }
    records <- do.call("rbind", records)

### 5. Fill lineage information

The final step in completing the records table is to add lineage
information and sample metadata. This is an optional step but can
improve interpretation of the results.

    tdb <- taxa[, 1:4]
    colnames(tdb) <- c("taxID", "parent_taxID", "rank", "name")
    lineages = insect::get_lineage(records$TaxID, tdb)
    records$phylum <- sapply(lineages, "[", "phylum")
    records$class <- sapply(lineages, "[", "class")
    records$order <- sapply(lineages, "[", "order")
    records$family <- sapply(lineages, "[", "family")
    records$genus <- sapply(lineages, "[", "genus")
    records$species <- sapply(lineages, "[", "species")
    records$Latitude <- samples$Latitude[match(records$UID,samples$UID)]
    records$Longitude <- samples$Longitude[match(records$UID,samples$UID)]
    records$ClientSampleID <- samples$ClientSampleID[match(records$UID,samples$UID)]

## Example output

For the purposes of this manual, we will use example access keys as
follows. This information will allow us to produce an example of what to
expect from connecting to the Wilderlab API. Feel free to try out the
API with these access keys first to ensure it is working as expected.

    key <- "AKIATVYXGCYLWADFJVEX"
    secret <- "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"
    xapikey <- "7CCm580l5vgeKbalwIEy565uFhbEudTauAq80B38"

### Jobs

Getting information from the `jobs` table:

    jobs <- get_wilderdata("jobs", key = key, secret = secret, xapikey = xapikey)
    jobs
    #>    JobID SubmissionDate     ContactName    ContactEmail PurchaseOrder
    #> 1 601833     2021-07-04 Shaun Wilkinson api@example.com            NA
    #> 2 601834     2021-07-04 Shaun Wilkinson api@example.com            NA
    #>                            JobReference JobNotes NumberOfSamples TestsRequired
    #> 1 Passive sampler validation experiment       NA               3            AP
    #> 2 Passive sampler validation experiment       NA               3            AP
    #>   MakeDataPublic PassCode JobStatus InvoiceNo
    #> 1              1  W1E0638  Complete  INTERNAL
    #> 2              1  W1E0638  Complete  INTERNAL

### Samples

Getting information from the `samples` table:

    samples <- get_wilderdata("samples", key = key, secret = secret, xapikey = xapikey)
    samples
    #>    SID  JobID    UID CollectionDate     CollectedBy   ClientSampleID  Latitude
    #> 1 8145 601833 507875     2021-07-03 Shaun Wilkinson Ruakokoputuna C3 -41.31267
    #> 2 8143 601833 507877     2021-07-03 Shaun Wilkinson Ruakokoputuna C1 -41.31267
    #> 3 8144 601833 510042     2021-07-03 Shaun Wilkinson Ruakokoputuna C2 -41.31267
    #> 4 8146 601834 510897     2021-07-03 Shaun Wilkinson Ruakokoputuna P1 -41.31267
    #> 5 8147 601834 510898     2021-07-03 Shaun Wilkinson Ruakokoputuna P2 -41.31267
    #> 6 8148 601834 510899     2021-07-03 Shaun Wilkinson Ruakokoputuna P3 -41.31267
    #>   Longitude VolumeFilteredML DeploymentDuration EnvironmentType   ClientNotes
    #> 1  175.4499             1000                 NA    River/Stream Control rep 3
    #> 2  175.4499             1000                 NA    River/Stream Control rep 1
    #> 3  175.4499             1000                 NA    River/Stream Control rep 2
    #> 4  175.4499               NA                 24    River/Stream Passive rep 1
    #> 5  175.4499               NA                 24    River/Stream Passive rep 2
    #> 6  175.4499               NA                 24    River/Stream Passive rep 3
    #>        AccountName MakeDataPublic
    #> 1 Wilderlab NZ Ltd              1
    #> 2 Wilderlab NZ Ltd              1
    #> 3 Wilderlab NZ Ltd              1
    #> 4 Wilderlab NZ Ltd              1
    #> 5 Wilderlab NZ Ltd              1
    #> 6 Wilderlab NZ Ltd              1
    #>                                                                                       Report
    #> 1 https://s3.ap-southeast-2.amazonaws.com/wilderlab.openwaters/reports/9d2cb6bd7340b48f.html
    #> 2 https://s3.ap-southeast-2.amazonaws.com/wilderlab.openwaters/reports/f702594d02f3430f.html
    #> 3 https://s3.ap-southeast-2.amazonaws.com/wilderlab.openwaters/reports/fedf2bcc7a34d5d1.html
    #> 4 https://s3.ap-southeast-2.amazonaws.com/wilderlab.openwaters/reports/39d1ee3138936298.html
    #> 5 https://s3.ap-southeast-2.amazonaws.com/wilderlab.openwaters/reports/cfcf07466e1942ed.html
    #> 6 https://s3.ap-southeast-2.amazonaws.com/wilderlab.openwaters/reports/0fce22b32ba71dbb.html

### Taxa

Getting information from the `taxa` table:

    taxa <- get_wilderdata("taxa", key = key, secret = secret, xapikey = xapikey)
    head(taxa, 10)
    #>    TaxID ParentTaxID         Rank             Name                CommonName
    #> 1      1           0      no rank             root                          
    #> 2      2      131567 superkingdom         Bacteria                Eubacteria
    #> 3     10     1706371        genus       Cellvibrio                          
    #> 4     18      213421        genus       Pelobacter                          
    #> 5     20       76892        genus Phenylobacterium                          
    #> 6     22      267890        genus       Shewanella                          
    #> 7     29       28221        order     Myxococcales Fruiting gliding bacteria
    #> 8     31       80811       family    Myxococcaceae                          
    #> 9     39       80811       family    Archangiaceae                          
    #> 10    40          39        genus      Stigmatella                          
    #>    MaoriName
    #> 1           
    #> 2           
    #> 3           
    #> 4           
    #> 5           
    #> 6           
    #> 7           
    #> 8           
    #> 9           
    #> 10

### Records

Getting information from the `records` table:

    records <- vector(mode = "list", length = nrow(jobs))
    for(i in seq_along(records)){
      records[[i]] <- get_wilderdata("records", JobID = jobs$JobID[i],
                                     key = key, secret = secret, xapikey = xapikey)
    }
    records <- do.call("rbind", records)

    head(records, 10)
    #>        HID    UID  TaxID    Rank           Name                  CommonName
    #> 1  3963310 507875 578128  family  Holostichidae                    Ciliates
    #> 2  3963311 507875 584654   genus Anteholosticha                            
    #> 3  3963318 507875  50949   genus       Navicula                            
    #> 4  3963327 507875   5948   genus    Stylonychia                            
    #> 5  3963332 507875  70185   genus    Spongospora                            
    #> 6  3963343 507877 584654   genus Anteholosticha                            
    #> 7  3963344 507877  68038   genus    Chaetonotus                 Gastrotrich
    #> 8  3963346 507877  41372  family  Chaetonotidae                            
    #> 9  3963347 507877 109671 species Physella acuta Left handed sinistral snail
    #> 10 3963357 507877  50949   genus       Navicula                            
    #>       Group Count
    #> 1  Ciliates    74
    #> 2  Ciliates    69
    #> 3   Diatoms    16
    #> 4  Ciliates    10
    #> 5     Other     7
    #> 6  Ciliates    63
    #> 7     Other    56
    #> 8     Other    60
    #> 9  Molluscs   531
    #> 10  Diatoms     7

Adding lineage information and sample metadata information into the
records table:

    tdb <- taxa[, 1:4]
    colnames(tdb) <- c("taxID", "parent_taxID", "rank", "name")
    lineages = insect::get_lineage(records$TaxID, tdb)
    records$phylum <- sapply(lineages, "[", "phylum")
    records$class <- sapply(lineages, "[", "class")
    records$order <- sapply(lineages, "[", "order")
    records$family <- sapply(lineages, "[", "family")
    records$genus <- sapply(lineages, "[", "genus")
    records$species <- sapply(lineages, "[", "species")
    records$Latitude <- samples$Latitude[match(records$UID, samples$UID)]
    records$Longitude <- samples$Longitude[match(records$UID, samples$UID)]
    records$ClientSampleID <- samples$ClientSampleID[match(records$UID, samples$UID)]

    head(records, 10)
    #>        HID    UID  TaxID    Rank           Name                  CommonName
    #> 1  3963310 507875 578128  family  Holostichidae                    Ciliates
    #> 2  3963311 507875 584654   genus Anteholosticha                            
    #> 3  3963318 507875  50949   genus       Navicula                            
    #> 4  3963327 507875   5948   genus    Stylonychia                            
    #> 5  3963332 507875  70185   genus    Spongospora                            
    #> 6  3963343 507877 584654   genus Anteholosticha                            
    #> 7  3963344 507877  68038   genus    Chaetonotus                 Gastrotrich
    #> 8  3963346 507877  41372  family  Chaetonotidae                            
    #> 9  3963347 507877 109671 species Physella acuta Left handed sinistral snail
    #> 10 3963357 507877  50949   genus       Navicula                            
    #>       Group Count          phylum             class            order
    #> 1  Ciliates    74      Ciliophora      Spirotrichea       Urostylida
    #> 2  Ciliates    69      Ciliophora      Spirotrichea       Urostylida
    #> 3   Diatoms    16 Bacillariophyta Bacillariophyceae      Naviculales
    #> 4  Ciliates    10      Ciliophora      Spirotrichea  Sporadotrichida
    #> 5     Other     7        Endomyxa        Phytomyxea Plasmodiophorida
    #> 6  Ciliates    63      Ciliophora      Spirotrichea       Urostylida
    #> 7     Other    56    Gastrotricha              <NA>     Chaetonotida
    #> 8     Other    60    Gastrotricha              <NA>     Chaetonotida
    #> 9  Molluscs   531        Mollusca        Gastropoda             <NA>
    #> 10  Diatoms     7 Bacillariophyta Bacillariophyceae      Naviculales
    #>               family          genus        species  Latitude Longitude
    #> 1      Holostichidae           <NA>           <NA> -41.31267  175.4499
    #> 2      Holostichidae Anteholosticha           <NA> -41.31267  175.4499
    #> 3       Naviculaceae       Navicula           <NA> -41.31267  175.4499
    #> 4       Oxytrichidae    Stylonychia           <NA> -41.31267  175.4499
    #> 5  Plasmodiophoridae    Spongospora           <NA> -41.31267  175.4499
    #> 6      Holostichidae Anteholosticha           <NA> -41.31267  175.4499
    #> 7      Chaetonotidae    Chaetonotus           <NA> -41.31267  175.4499
    #> 8      Chaetonotidae           <NA>           <NA> -41.31267  175.4499
    #> 9           Physidae       Physella Physella acuta -41.31267  175.4499
    #> 10      Naviculaceae       Navicula           <NA> -41.31267  175.4499
    #>      ClientSampleID
    #> 1  Ruakokoputuna C3
    #> 2  Ruakokoputuna C3
    #> 3  Ruakokoputuna C3
    #> 4  Ruakokoputuna C3
    #> 5  Ruakokoputuna C3
    #> 6  Ruakokoputuna C1
    #> 7  Ruakokoputuna C1
    #> 8  Ruakokoputuna C1
    #> 9  Ruakokoputuna C1
    #> 10 Ruakokoputuna C1

## Issues

If you experience a problem using this software please feel free to
raise it as an issue on
[GitHub](https://github.com/wilderlabnz/wilderlab/issues/).
