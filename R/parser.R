#' Upload and add a file to the chat log.
#'
#' @param log Message log.
#' @param file_path Document file path.
#' @return Message log with parsed document text sent to system.
chat_document_parser <- function(log, file_path) {
  file_path <- path.expand(file_path)
  file_path <- normalizePath(file_path, mustWork = TRUE)
  ext <- tools::file_ext(file_path)

  # retrieve content as text
  content <- tryCatch({
    switch(
      ext,
      "txt" = readLines(file_path, warn = FALSE) |> paste(collapse = "\n"),
      "csv" = readLines(file_path, warn = FALSE) |> paste(collapse = "\n"),
      "pdf" = {
        out_path = .pdf_to_text(file_path)
        readLines(out_path, warn = FALSE) |> paste(collapse = "\n")
      },
      stop("Unsupported file type")
    )
  }, error = function(e) {
    paste("Error reading file:", e$message)
  })

  # generate message
  system_message <- paste0(
    "The user has uploaded a file, here are its contents:\n\n",
    "--- DOCUMENT START ---\n",
    content,
    "\n--- DOCUMENT END ---\n\n",
    "Use must use this document as context for answering the user's questions."
  )

  # append to log
  log <- append(log, list(list(
    role = "system",
    content = system_message
  )))

  log
}

#' Add relevant knowledge files to the chat log.
#'
#' @param log Message log.
#' @param chunk_db Database of chunks to measure against query.
#' @param top_k Number of relevant chunks to return.
#' @return Message log with relevant knowledge base sent to the system.
chat_chunk_parser <- function(log, chunk_db, top_k = 5) {
  # most recent user message
  u_msg <- Filter(function(msg) msg$role == "user", log)
  if (length(u_msg) == 0) {
    return(log)
  }

  # query
  query <- tail(u_msg, 1)[[1]]$content

  # pull chunk information
  rel_chunks <- chunk_pull(query, chunk_db, top_k)

  # build content
  content <- paste(rel_chunks$text, collapse = " ")

  # generate message
  system_message <- paste0(
    "The is additional context based to use during your responses:\n\n",
    "--- CONTEXT START ---\n",
    content,
    "\n--- CONTEXT END ---\n\n",
    "Do not directly quote this information, use it to inform responses."
  )

  # append to log
  log <- append(log, list(list(
    role = "system",
    content = system_message
  )))

  log
}