# Setup --------------------
setwd("C:/Users/gleas/Google Drive/Coding/R/reference_extractor")
for (fname in dir("funcs")) { source(paste0("funcs/", fname)) }
load_libraries()
set_options()

# ______ --------------------------

url_string <- "https://pubsonline.informs.org/doi/ref/10.1287/isre.2016.0647"

r <- rsDriver(browser = "firefox") # https://www.youtube.com/watch?v=Vt6f8A35-1w

client <- r[["client"]]

# Get google sheet --------------------------------------------------------------------------

# gs_ls()

salge_research <- gs_title("Salge - Research")

# gs_ws_ls(salge_research)

snowballed <- gs_read(ss=salge_research, ws="Snowballed")

snowballed <- janitor::clean_names(snowballed)

primary_source_links <-
  snowballed %>%
  filter(justification == "Primary source") %>%
  pull(new_article_link)

# Get all references for a single INFORMs paper ----------------------------------------------

# Must pass in the references page for this to work
# That is, this: https://pubsonline.informs.org/doi/ref/10.1287/isre.2016.0647
# Not this: https://pubsonline.informs.org/doi/10.1287/isre.2016.0647
referent_data_informs <- get_refs_data_informs(client, ref_url_string)

# Get all references for a single ebscohost paper --------------------------------------------

# Login to ebscohost (partial)

client$navigate(primary_source_links[1])

# Select the WFU icon
myElement <-
  client$findElement(
    using = "css selector",
    value = ".IdPSelectTextDiv+ .IdPSelectPreferredIdPButton .IdPSelectTextDiv"
  )

# Click on WFU icon to redirect to WFU login
myElement$clickElement()
# Log in must be executed manually due to 2 factor auth

# Navigate to citations page of ebscohost after logged in
client$findElement(
  using="css selector",
  value ="#ctl00_ctl00_Column1_Column1_referencebuttoncontrol_referenceButtonRepeater_ctl01_ReferenceLinkCitation"
)$clickElement()

# From reference list ebscohost, get all citation elements by looping through them
referent_data_ebsco <- get_refs_data_ebsco(client, primary_source_links[1])

# Get all references for a single ScienceDirect paper ----------------------------------------

# Try to go to link
tryCatch(
  suppressMessages({
    client$navigate(url = primary_source_links[2])
  }),
  error = function(e) {

    if(stringr::str_detect(e$message, "Summary: NoSuchDriver")) {

      needs_cleaned <<- TRUE

    } else {

      stop(paste0("Unhandled error: ", e$message))

    }

  }
)

if(needs_cleaned) {

  rm(r, client)

  gc()

  r <- rsDriver(browser = "firefox") # https://www.youtube.com/watch?v=Vt6f8A35-1w

  client <- r[["client"]]

  tryCatch(
    client$navigate(url = primary_source_links[2]),
    error = function(e) {
      print("Client isn't working. Restarting browser didn't work.")
    }
  )

}

signed_in <<- FALSE
# Check if signed in
tryCatch(
  suppressMessages({
    client$findElement(using="css selector", value="#gh-signin-btn")
  }),
  error = function(e) {
    # Set signed_in in global environment
    signed_in <<- TRUE
  }
)

if(!signed_in) {
  Sys.sleep(2)

  client$findElement(using="css selector", value="#gh-signin-btn")$
    clickElement()

  client$findElement(using="css selector", value='a[title="Other institution login"]')$
    clickElement()

  client$findElement(using="css selector", value="#auto_inst_srch")$
    sendKeysToElement(list("Wake Forest University"))

  Sys.sleep(1)

  client$findElement(using="css selector", value="#auto_inst_srch")$
    sendKeysToElement(list("\uE015","\uE007"))

  Sys.sleep(4)

  client$findElement(using="css selector", value="#Email")$
    sendKeysToElement(list("gleabp18@wfu.edu","\uE007"))

  Sys.sleep(2)

  client$findElement(using="css selector", value="#Passwd")$
    sendKeysToElement(list("aut3!Nih3ng34","\uE007"))

  readline(prompt = "Press Enter Once 2 Factor Auth is Complete")

  signed_in <<- TRUE
}

if(signed_in) {
  # Go to references
  client$findElement(using="css selector", value='a[title="References"]')$
    clickElement()

  referent_data_scidir <-
    client$findElements(using="css selector", value="dd.reference")

  scidir_ref_data <-
    tibble(
      primary_paper_url = primary_source_links[2],
      ref_authors = map_chr(
        .x = referent_data_scidir,
        .f = function(x) {
          # The structure of a reference block changes depending on whether
          # it's a paper from an academic journal or a book of some sort
          ref_type <<- "paper"
          return_string <<- NA_character_

          tryCatch(
            suppressMessages({
              return_string <<-
                # Papers have class="contribution"
                x$findChildElement(using="css selector", value=".contribution")$
                getElementAttribute('innerHTML')[[1]]
            }),
            error = function(e) {
              ref_type <<- "other"
              return_string <<-
                  x$findChildElement(using="css selector", value="span")$
                    getElementAttribute('innerHTML')[[1]]
            }
          )

          if(ref_type=="paper") {
            return(
              str_sub(
                return_string,
                start = 1,
                end = -1 + str_locate(return_string, "\\<strong")[1]
              )
            )
          } else {
            return(return_string)
          }
        }
      ),
      ref_doc_type = character(0),
      ref_pub_year = integer(0),
      ref_article_title = character(0),
      ref_source = character(0)
    )
}
