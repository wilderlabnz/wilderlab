<style type="text/css">
pre {
  overflow-x: auto;
}
pre code {
  word-wrap: normal;
  white-space: pre;
}

h4{
  color: #016793;
}
</style>

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
<tr>
<th style="text-align: left;">Argument</th>
<th style="text-align: left;">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: left;"><code>tb</code></td>
<td style="text-align: left;">a character string specifying the table
required. Accepted values are <code>jobs</code>, <code>samples</code>,
<code>taxa</code>, and <code>records</code>. API access keys are not
required when set to <code>taxa</code>.</td>
</tr>
<tr>
<td style="text-align: left;"><code>key</code></td>
<td style="text-align: left;">a string specifying the API access key for
the client account. Please contact <a href="mailto:info@wilderlab.co.nz"
class="email">info@wilderlab.co.nz</a> if you would like access keys
generated for your account.</td>
</tr>
<tr>
<td style="text-align: left;"><code>secret</code></td>
<td style="text-align: left;">a string specifying the API secret access
key for the client account. Please contact <a
href="mailto:info@wilderlab.co.nz"
class="email">info@wilderlab.co.nz</a> if you would like access keys
generated for your account.</td>
</tr>
<tr>
<td style="text-align: left;"><code>xapikey</code></td>
<td style="text-align: left;">a string specifying the X-API-Key value
for the client account. Please contact <a
href="mailto:info@wilderlab.co.nz"
class="email">info@wilderlab.co.nz</a> if you would like access keys
generated for your account.</td>
</tr>
<tr>
<td style="text-align: left;"><code>JobID</code></td>
<td style="text-align: left;">a 6 digit integer specifying a Wilderlab
job number. Required only for accessing the records table.</td>
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
    taxa <- get_wilderdata("taxa")

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
    #> 1 601833     2021-07-04 Shaun Wilkinson api@example.com              
    #> 2 601834     2021-07-04 Shaun Wilkinson api@example.com              
    #>                            JobReference JobNotes NumberOfSamples
    #> 1 Passive sampler validation experiment                        3
    #> 2 Passive sampler validation experiment                        3
    #>            AssayPanel MakeDataPublic PassCode JobStatus
    #> 1 Comprehensive panel              1  W1E0638  Complete
    #> 2 Comprehensive panel              1  W1E0638  Complete
    #>                                                                                                        ResultsLink
    #> 1 https://s3.ap-southeast-2.amazonaws.com/wilderlab.results/c03d243992534adcf4ffecd39c43d6e8/WLM601833_250626.xlsx
    #> 2 https://s3.ap-southeast-2.amazonaws.com/wilderlab.results/a26f9576e52ce92c689070da34865104/WLM601834_250626.xlsx
    #>   InvoiceNo
    #> 1  INTERNAL
    #> 2  INTERNAL

### Samples

Getting information from the `samples` table:

    samples <- get_wilderdata("samples", key = key, secret = secret, xapikey = xapikey)
    samples
    #>    SID  JobID    UID CollectionDate     CollectedBy   ClientSampleID   Latitude
    #> 1 8145 601833 507875     2021-07-03 Shaun Wilkinson Ruakokoputuna C3 -41.312665
    #> 2 8143 601833 507877     2021-07-03 Shaun Wilkinson Ruakokoputuna C1 -41.312665
    #> 3 8144 601833 510042     2021-07-03 Shaun Wilkinson Ruakokoputuna C2 -41.312665
    #> 4 8146 601834 510897     2021-07-03 Shaun Wilkinson Ruakokoputuna P1 -41.312665
    #> 5 8147 601834 510898     2021-07-03 Shaun Wilkinson Ruakokoputuna P2 -41.312665
    #> 6 8148 601834 510899     2021-07-03 Shaun Wilkinson Ruakokoputuna P3 -41.312665
    #>    Longitude VolumeFilteredML DeploymentDuration EnvironmentType   TICI
    #> 1 175.449873             1000                       River/Stream 105.80
    #> 2 175.449873             1000                       River/Stream   0.00
    #> 3 175.449873             1000                       River/Stream 100.08
    #> 4 175.449873                                  24    River/Stream 100.97
    #> 5 175.449873                                  24    River/Stream 100.88
    #> 6 175.449873                                  24    River/Stream  99.81
    #>   TICINoSeqs TICIQuantile        TICIVersion   ClientNotes      AccountName
    #> 1        109         0.57        Riverine V1 Control rep 3 Wilderlab NZ Ltd
    #> 2          0         0.00 NC - Low seq count Control rep 1 Wilderlab NZ Ltd
    #> 3        159         0.51        Riverine V1 Control rep 2 Wilderlab NZ Ltd
    #> 4        391         0.52        Riverine V1 Passive rep 1 Wilderlab NZ Ltd
    #> 5        381         0.52        Riverine V1 Passive rep 2 Wilderlab NZ Ltd
    #> 6        320         0.50        Riverine V1 Passive rep 3 Wilderlab NZ Ltd
    #>   MakeDataPublic
    #> 1              1
    #> 2              1
    #> 3              1
    #> 4              1
    #> 5              1
    #> 6              1
    #>                                                                                       Report
    #> 1 https://s3.ap-southeast-2.amazonaws.com/wilderlab.openwaters/reports/c62322f1b3162646.html
    #> 2 https://s3.ap-southeast-2.amazonaws.com/wilderlab.openwaters/reports/c62322f1b3162646.html
    #> 3 https://s3.ap-southeast-2.amazonaws.com/wilderlab.openwaters/reports/c62322f1b3162646.html
    #> 4 https://s3.ap-southeast-2.amazonaws.com/wilderlab.openwaters/reports/0b6f40128711495a.html
    #> 5 https://s3.ap-southeast-2.amazonaws.com/wilderlab.openwaters/reports/0b6f40128711495a.html
    #> 6 https://s3.ap-southeast-2.amazonaws.com/wilderlab.openwaters/reports/0b6f40128711495a.html

### Taxa

Getting information from the `taxa` table:

    taxa <- get_wilderdata("taxa")
    head(taxa, 10)
    #>      TaxID ParentTaxID    Rank                        Name CommonName
    #> 1  2880534     2880533 no rank unclassified Promesocentrus           
    #> 2  2796488       94829   genus                Odontoscirus           
    #> 3  2881051       61492 species       Nanoscypha aequispora           
    #> 4  1375239      685409 species          Monopis argillacea           
    #> 5   581807      581380   genus                 Clepsicosma           
    #> 6  2010929     1505960   genus                 Limnogromia           
    #> 7   706082     1583079   genus                     Ophisma           
    #> 8   911187      558183   genus                  Diploperla           
    #> 9   652877        6779   genus                   Cyclodius      crabs
    #> 10    9443      314146   order                    Primates           
    #>          Group
    #> 1      Insects
    #> 2     Rotifers
    #> 3        Fungi
    #> 4      Insects
    #> 5      Insects
    #> 6        Other
    #> 7      Insects
    #> 8      Insects
    #> 9  Crustaceans
    #> 10     Mammals

### Records

Getting information from the `records` table:

    records <- vector(mode = "list", length = nrow(jobs))
    for(i in seq_along(records)){
      records[[i]] <- get_wilderdata("records", JobID = jobs$JobID[i],
                                     key = key, secret = secret, xapikey = xapikey)
    }
    records <- do.call("rbind", records)

    head(records, 10)
    #>        HID    UID TaxID   Rank               Name CommonName    Group Count
    #> 1  2557713 507875    10  genus         Cellvibrio            Bacteria    37
    #> 2  2679827 510042    10  genus         Cellvibrio            Bacteria    43
    #> 3  2557718 507875   237  genus     Flavobacterium            Bacteria    62
    #> 4  2679837 510042   237  genus     Flavobacterium            Bacteria    21
    #> 5  2557710 507875   444 family     Legionellaceae            Bacteria    42
    #> 6  2557724 507875   543 family Enterobacteriaceae            Bacteria    20
    #> 7  2557748 507877   543 family Enterobacteriaceae            Bacteria     7
    #> 8  2679838 510042   543 family Enterobacteriaceae            Bacteria    20
    #> 9  2679848 510042   642  genus          Aeromonas            Bacteria     6
    #> 10 2679844 510042   978  genus          Cytophaga            Bacteria     9

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
    #>        HID    UID TaxID   Rank               Name CommonName    Group Count
    #> 1  2557713 507875    10  genus         Cellvibrio            Bacteria    37
    #> 2  2679827 510042    10  genus         Cellvibrio            Bacteria    43
    #> 3  2557718 507875   237  genus     Flavobacterium            Bacteria    62
    #> 4  2679837 510042   237  genus     Flavobacterium            Bacteria    21
    #> 5  2557710 507875   444 family     Legionellaceae            Bacteria    42
    #> 6  2557724 507875   543 family Enterobacteriaceae            Bacteria    20
    #> 7  2557748 507877   543 family Enterobacteriaceae            Bacteria     7
    #> 8  2679838 510042   543 family Enterobacteriaceae            Bacteria    20
    #> 9  2679848 510042   642  genus          Aeromonas            Bacteria     6
    #> 10 2679844 510042   978  genus          Cytophaga            Bacteria     9
    #>            phylum               class            order             family
    #> 1  Pseudomonadota Gammaproteobacteria  Cellvibrionales   Cellvibrionaceae
    #> 2  Pseudomonadota Gammaproteobacteria  Cellvibrionales   Cellvibrionaceae
    #> 3    Bacteroidota      Flavobacteriia Flavobacteriales  Flavobacteriaceae
    #> 4    Bacteroidota      Flavobacteriia Flavobacteriales  Flavobacteriaceae
    #> 5  Pseudomonadota Gammaproteobacteria    Legionellales     Legionellaceae
    #> 6  Pseudomonadota Gammaproteobacteria Enterobacterales Enterobacteriaceae
    #> 7  Pseudomonadota Gammaproteobacteria Enterobacterales Enterobacteriaceae
    #> 8  Pseudomonadota Gammaproteobacteria Enterobacterales Enterobacteriaceae
    #> 9  Pseudomonadota Gammaproteobacteria    Aeromonadales     Aeromonadaceae
    #> 10   Bacteroidota          Cytophagia     Cytophagales      Cytophagaceae
    #>             genus species   Latitude  Longitude   ClientSampleID
    #> 1      Cellvibrio    <NA> -41.312665 175.449873 Ruakokoputuna C3
    #> 2      Cellvibrio    <NA> -41.312665 175.449873 Ruakokoputuna C2
    #> 3  Flavobacterium    <NA> -41.312665 175.449873 Ruakokoputuna C3
    #> 4  Flavobacterium    <NA> -41.312665 175.449873 Ruakokoputuna C2
    #> 5            <NA>    <NA> -41.312665 175.449873 Ruakokoputuna C3
    #> 6            <NA>    <NA> -41.312665 175.449873 Ruakokoputuna C3
    #> 7            <NA>    <NA> -41.312665 175.449873 Ruakokoputuna C1
    #> 8            <NA>    <NA> -41.312665 175.449873 Ruakokoputuna C2
    #> 9       Aeromonas    <NA> -41.312665 175.449873 Ruakokoputuna C2
    #> 10      Cytophaga    <NA> -41.312665 175.449873 Ruakokoputuna C2

## Other useful functions

### `read_eDNA`

This function is designed to easily import a Wilderlab results
spreadsheet into an R environment. It returns a named list of tibbles:
jobs, samples, aggregated, full, and TICI (if relevant).

    # to use an interactive file explorer to select file for import
    read_eDNA()
    # to provide the file path as a parameter
    read_eDNA("path/to/file.xlsx")

### `get_lineages`

This functions uses the
[`insect`](https://github.com/shaunpwilkinson/insect) package to pull
the full lineage information for each supplied taxon ID, returning a
data frame with one column for each required rank. A warning will be
printed if any taxon ids aren’t in the taxonomy table. If this happens,
ask [Wilderlab](mailto:info@wilderlab.co) for a refreshed version of
your eDNA results, since taxonomy is always changing in NCBI.

    eDNA <- read_eDNA()
    aggregated_data <- eDNA$aggregated
    lineages <- get_lineages(aggregated_data$TaxID)
    # to merge with aggregated date
    aggregated_data <- merge(aggregated_data, lineages, by = "TaxID", sort = FALSE)

## Issues

If you experience a problem using this software please feel free to
raise it as an issue on
[GitHub](https://github.com/wilderlabnz/wilderlab/issues/).
