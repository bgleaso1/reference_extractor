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

# Get referent data for a single INFORMs paper ----------------------------------------------

# Must pass in the references page for this to work
# That is, this: https://pubsonline.informs.org/doi/ref/10.1287/isre.2016.0647
# Not this: https://pubsonline.informs.org/doi/10.1287/isre.2016.0647
referent_data_informs <- get_refs_data_informs(client, ref_url_string)

# Get referent data for all INFORMs papers --------------------------------------------------

# Login to ebscohost (partial) --------------------------------------------------------------

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

# From citation list ebscohost, get all citation elements by looping through them -----------
referent_data_ebsco <- get_refs_data_ebsco(client, primary_source_links[1])
