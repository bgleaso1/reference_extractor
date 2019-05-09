get_refs_data_ebsco <- function(client, url_string) {

  ebsco_ref_data <-
    tibble(
      primary_paper_url = character(0),
      ref_authors = character(0),
      ref_doc_type = character(0),
      ref_pub_year = integer(0),
      ref_article_title = character(0),
      ref_source = character(0)
    )

  # From on citation list ebscohost, get all citation elements by looping through them -----------

  # Initialize list to hold pages
  referent_data_pages <- list()

  onLastPage = FALSE
  iteration = 1
  while(!onLastPage) {

    referent_data_page <-
      # Get reference elements on this page
      client$findElements(using = "css selector", value = "#resultListControl li")

    # referent_data_page[[1]]$
    #   findChildElement(using="css selector", value=".medium-font , .color-p4 a")$
    #   getElementAttribute('innerHTML')[[1]]

    this_page_ref_data <-
      tibble(
        primary_paper_url = url_string,
        ref_authors = map_chr(
          .x = referent_data_page,
          .f = function(x) {
            x$findChildElement(using="css selector", value=".standard-view-style:nth-child(2)")$
              getElementAttribute('innerHTML')[[1]] %>%
              str_sub(3,-1)
          }
        ),
        ref_doc_type = map_chr(
          .x = map_chr(
            .x = client$findElements(using="css selector", value="#resultListControl li"),
            .f = function(x) {
              x$getElementAttribute("outerHTML")[[1]]
            }
          ),
          .f = function(y) {
            y %>%
              read_html() %>%
              html_nodes(".standard-view-style") %>%
              html_text() -> vec
            str_extract(vec, "(?<=Document Type: )[:graph:]*") -> vec2
            return(vec2[!is.na(vec2)])
          }
        ),
        # TODO: Insert a case_when here to handle books and articles differently on ebscohost
        ref_pub_year = map_int(
          .x = referent_data_page,
          .f = function(x) {
            x$findChildElement(using="css selector", value=".standard-view-style:nth-child(4)")$
              getElementAttribute('innerHTML')[[1]] %>%
              stringr::str_sub(start=3, end=6) %>%
              as.integer()
          }
        ),
        ref_article_title = map_chr(
          .x = referent_data_page,
          .f = function(x) {
            x$findChildElement(using="css selector", value=".medium-font , .color-p4 a")$
              getElementAttribute('innerHTML')[[1]]
          }
        ),
        ref_source = map_chr(
          .x = referent_data_page,
          .f = function(x) {
            x$findChildElement(using="css selector", value=".standard-view-style:nth-child(3)")$
              getElementAttribute('innerHTML')[[1]] %>%
              str_trim(side="left") %>%
              str_sub(1,-2)
          }
        )
      )

    # Append to results from other pages
    ebsco_ref_data <- bind_rows(ebsco_ref_data, this_page_ref_data)

    # Try to find the next page link
    nextButton <-
      tryCatch(
        client$findElement(
          using = "css selector",
          value = "#ctl00_ctl00_MainContentArea_MainContentArea_bottomMultiPage_lnkNext"
        ),
        error = function(e) {
          NA
        }
      )

    if(!is.na(nextButton)) {
      nextButton$clickElement()
    } else {
      onLastPage = TRUE
    }

    iteration = iteration + 1

  }

  return(ebsco_ref_data)

}
