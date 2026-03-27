#' Text chunking.
#'
#' @param text Text vector to chunk.
#' @param chunk_size Characters per chunk.
#' @param overlap Character overlap between chunks.
#' @return List of text chunks.
chunk_text <- function(text, chunk_size = 1000, overlap = 200) {
  # setup
  chunks <- list()
  start <- chunk_id <- 1
  text_length <- nchar(text)

  # loop chunk creation
  while (start <= text_length) {
    end = min(start + chunk_size - 1, text_length)
    chunk = substr(text, start, end)

    # create chunk
    chunks[[chunk_id]] = list(
      id = chunk_id,
      text = chunk,
      start = start,
      end = end
    )

    # setup loop
    chunk_id = chunk_id + 1
    start = start + chunk_size - overlap
  }

  chunks
}

#' Creates a knowledge chunk database from a list of .txt files.
#'
#' @param file_paths Character vector of document file paths.
#' @param ... Parameters sent from 'chunk_text()'.
#' @return Data frame of file path, chunks and embeddings.
chunk_database <- function(file_paths, ...) {
  # set chunks list
  all_chunks <- list()

  # iterate file paths to create chunking data frame
  for (file_path in file_paths) {
    text <- paste(readLines(file_path, warn = FALSE), collapse = "\n")
    chunks <- chunk_text(text, ...)

    # add to data frame
    for (i in seq_along(chunks)) {
      chunks[[i]]$file <- file_path
      all_chunks[[length(all_chunks) + 1]] <- chunks[[i]]
    }
  }

  # embed
  chunk_texts <- sapply(all_chunks, function(x) x$text)
  embeddings <- embed_text(chunk_texts)

  # create data frame
  chunk_db <- data.frame(
    chunk_id = sapply(all_chunks, function(x) x$id),
    file = sapply(all_chunks, function(x) x$file),
    text = chunk_texts,
    stringsAsFactors = FALSE
  )

  # store embeddings as matrix
  chunk_db$embedding <- split(embeddings, row(embeddings))

  chunk_db
}

#' Pull top chunk similarities to a query.
#'
#' @param query User query.
#' @param chunk_db Database of chunks to measure against query.
#' @param top_k Number of relevant chunks to return.
#' @return Data frame of top scoring chunks.
chunk_pull <- function(query, chunk_db, top_k = 5) {
  # embed query
  query_embedding <- embed_text(query)[1, ]

  # calculate similarity
  similarities <- sapply(chunk_db$embedding, function(chunk_embedding) {
    embed_similarity(as.numeric(query_embedding),
                     as.numeric(chunk_embedding))
  })

  # top_k scoring
  top_n <- seq_len(min(top_k, length(similarities)))
  top_score <- order(similarities, decreasing = TRUE)[top_n]

  # return top scoring chunks
  top_chunks <- chunk_db[top_score, ]
  top_chunks$similarity <- similarities[top_score]

  top_chunks
}