#' Embeds text.
#'
#' @param text List of text messages to embed.
#' @return Embedded string.
embed_text <- function(text) {
  # response
  body <- list(model = "nomic-embed-text:latest", input = text, stream = FALSE)
  response <- httr::POST(
    paste0(getOption("ollama.url"), "/embed"),
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "json",
    httr::content_type_json()
  )
  result <- httr::content(response, "parsed", encoding = "UTF-8")

  do.call(rbind, result$embeddings)
}

#' Compute cosine similarity.
#'
#' @param a Numeric vector.
#' @param b Numeric vector.
#' @return Similarity angle score.
embed_similarity <- function(a, b) {
  sum(a * b) / (sqrt(sum(a ^ 2)) * sqrt(sum(b ^ 2)))
}
