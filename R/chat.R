#' Builds the chat log.
#'
#' @param log Message log.
#' @param model Model type.
#' @return Updated message log list.
chat_builder <- function(log, model) {
  # response
  body <- list(model = model, messages = log, stream = FALSE)
  response <- httr::POST(
    paste0(getOption("ollama.url"), "/chat"),
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "json",
    httr::content_type_json()
  )
  result <- httr::content(response, "parsed", encoding = "UTF-8")
  bot_msg <- result$message$content

  if (bot_msg == "NULL") {
    bot_msg = "I am sorry, I cannot answer that question."
  }

  log <- append(log, list(list(
    role = "assistant",
    content = bot_msg,
    model = model
  )))

  log
}

#' Protects button labelling by reformatting inputIDs.
#'
#' @param x Character string.
#' @return Character string compatible with 'actionButton()' inputID.
fix_inputID <- function(x) {
  gsub("[[:punct:]]", "", x)
}
