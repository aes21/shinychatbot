#'
#'
options(
  ollama.url = getOption("ollama.url", default = "http://localhost:11434/api"),
  shiny.maxRequestSize = 30 * 1024^2
)

#'
#'
.pdf_to_text <- function(file_path) {
  f <- basename(file_path)

  # output bath
  out_path <- file.path(tempdir(), sub("\\.pdf$", "", f))
  out_path <- paste0(out_path, ".txt")

  # run command
  system2(
    command = "pdftotext",
    args = c(shQuote(file_path), shQuote(out_path)),
    stdout = TRUE,
    stderr = TRUE
  )

  out_path
}

#' Set up the chat environment.
#'
#' @return Chat environment list.
chatbotenv <- function() {
  list(
    list(
      role = "system",
      content = readLines("inst/system-prompt.txt", warn = FALSE) |>
        paste(collapse = "\n")
    ),
    list(
      role = "assistant",
      content = "Hello, I am your Shiny Assistant, how can I help?",
      model = NULL
    )
  )
}

#' Model list.
#'
#' @return Vector of available models.
modelenv <- function() {
  models <- jsonlite::fromJSON(httr::content(
    httr::GET(
      paste0(getOption("ollama.url"), "/tags"),
      body = jsonlite::toJSON(body, auto_unbox = TRUE),
      encode = "json",
      httr::content_type_json()
    ),
    "text",
    encoding = "UTF-8"
  ))$models$name

  embed_models <- c()
  for (m in models) {
    body <- list(model = m)
    capabilities <- jsonlite::fromJSON(httr::content(
      httr::POST(
        paste0(getOption("ollama.url"), "/show"),
        body = jsonlite::toJSON(body, auto_unbox = TRUE),
        encode = "json",
        httr::content_type_json()
      ),
      "text",
      encoding = "UTF-8"
    ))$capabilities

    if ("embedding" %in% capabilities) {
      embed_models <- append(embed_models, m)
    } else {
      next
    }
  }

  model <- list()
  model[["embedding"]] <- embed_models
  model[["tools"]] <- sort(models[!models %in% embed_models])

  model
}