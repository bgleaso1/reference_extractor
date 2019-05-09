# Setup --------------------
setwd("C:/Users/gleas/Google Drive/Coding/R/reference_extractor")
for (fname in dir("funcs")) { source(paste0("funcs/", fname)) }
load_libraries()
set_options()

# ______ --------------------------

url_string <- "https://pubsonline.informs.org/doi/ref/10.1287/isre.2016.0647"

r <- rsDriver(browser = "firefox") # https://www.youtube.com/watch?v=Vt6f8A35-1w

client <- r[["client"]]

# Get referent data for a single INFORMs paper -------------------------

referent_data <- get_refs_data_informs(client, url_string)
