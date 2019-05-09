get_refs_data_informs <- function(client, url) {

  source_paper_url <- url

  # Get referent HTML for a single INFORMs paper -------------------------

  # Note: This section returns a character vector holding the HTML code
  #       for a single reference to another paper, which will be added
  #       to a tibble in the next step

  client$navigate(url = source_paper_url)

  references <- client$findElements(using = "css", value = ".references__item")

  refs <-
    references %>%
    map_chr(.f=function(x){
      x$getElementAttribute('innerHTML')[[1]]
    })

  refs_html <-
    map(.x=refs, .f=read_html)

  # Convert HTML to text and push to tibble ------------------------------

  this_paper_referents <-
    tibble(
      primary_paper_url = source_paper_url, # Primary paper is the paper that has already been verified as relevant
      # Author list (separated by commas)
      ref_authors = {
        map_chr(.x=refs_html, .f=function(x) {
          x %>% # List of XML objects in
            html_node(".references__authors") %>% # Select author list
            html_text() # Convert back to text
        })
      },
      # Publish year
      ref_pub_year = {
        map_int(.x=refs_html, .f=function(x) {
          x %>%
            html_node(".references__year") %>%
            html_text() %>%
            as.integer()
        })
      },
      # Title
      ref_article_title = {
        map_chr(.x=refs_html, .f=function(x) {
          x %>%
            html_node(".references__article-title") %>%
            html_text()
        })
      },
      # Outlet the referent was published in
      ref_source = {
        map_chr(.x=refs_html, .f=function(x) {
          x %>%
            html_node(".references__source") %>%
            html_text()
        })
      }
    )

  return(this_paper_referents)

}
