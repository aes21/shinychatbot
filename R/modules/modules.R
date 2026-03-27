library(shiny)
library(shinyjs)

# load available models
models <- modelenv()

chatbotUI <- function(id) {
  ns <- NS(id)

  tagList(
    # include scripts
    shinyjs::useShinyjs(),
    singleton(tags$head(
      tags$div(id = "overlay"), tags$div(id = "divLoading")
    )),

    fluidRow(
      style = "text-align: center;",
      column(
        12,
        style = "display: inline-block;",
        actionButton(
          ns("toggle_chat"),
          label = NULL,
          icon = icon("plus"),
          class = "expand-buttons"
        ),
        uiOutput(ns("intro_message"))
      )
    ),

    shinyjs::hidden(div(
      id = ns("chatbox"),

      # chat settings indication
      uiOutput(ns("settings_indicator")),

      # chat scroll container
      div(id = ns("chat-container"), uiOutput(ns("chat_history"))),

      # input container
      div(
        id = ns("input-panel"),
        div(
          class = "input-wrapper",
          textAreaInput(
            ns("user_input"),
            label = NULL,
            placeholder = "Ask anything...",
            resize = "none"
          ),
          div(
            class = "button-row",
            actionButton(
              ns("send_btn"),
              label = NULL,
              icon = icon("arrow-up"),
              class = "chat-buttons"
            ),
            actionButton(
              ns("attach_btn"),
              label = NULL,
              icon = icon("paperclip"),
              class = "chat-buttons"
            ),
            actionButton(
              ns("context_btn"),
              label = NULL,
              icon = icon("sliders"),
              class = "chat-buttons"
            ),
          ),
          br(),
          selectInput(
            ns("model_select"),
            label = NULL,
            choices = models$tools,
            width = "50%"
          ),
        )
      )
    ))
  )
}

chatbotServer <- function(id, new_chat, delete_chat, user_data, ...) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    observeEvent(input$toggle_chat, {
      shinyjs::toggle(id = "chatbox")

      if (input$toggle_chat %% 2 == 0) {
        updateActionButton(session, "toggle_chat", icon = icon("plus"))
      } else {
        updateActionButton(session, "toggle_chat", icon = icon("minus"))
      }
    })

    output$intro_message <- renderUI({
      if (input$toggle_chat %% 2 == 0) {
        h4("Ask anything...")
      } else {
        NULL
      }
    })

    # open chat log
    chat_log <- reactiveVal(chatbotenv())

    # initialise chat settings
    chat_settings <- reactiveValues(bio_mode = FALSE)
    observeEvent(input$bio_mode, {
      chat_settings$bio_mode <- input$bio_mode
      log <- chat_log()
      prompt <- "Responses should always have a biological focus."

      if (isTRUE(chat_settings$bio_mode)) {
        log = append(log, list(list(
          role = "system", content = prompt
        )))
      } else {
        log <- Filter(function(msg) {
          !(msg$role == "system" &&
              grepl(prompt, msg$content, fixed = TRUE))
        }, log)
      }

      chat_log(log)
    }, ignoreNULL = FALSE)

    # chat interaction
    observeEvent(input$send_btn, {
      req(input$user_input)

      user_msg = input$user_input
      updateTextAreaInput(session, "user_input", value = "")

      # append user message
      log = chat_log()
      log = append(log, list(
        list(
          role = "user",
          content = user_msg,
          model = input$model_select
        )
      ))

      chat_log(log)

      shinyjs::delay(100, {
        session$sendCustomMessage("startChatLoad", list())

        log = chat_builder(log = log, model = input$model_select)

        chat_log(log)

        session$sendCustomMessage("stopChatLoad", list())
      })
    })

    output$settings_indicator <- renderUI({
      settings = c()

      if (isTRUE(chat_settings$bio_mode)) {
        settings = c(settings, "Biology Mode")
      }

      if (length(settings) == 0)
        return(NULL)

      div(
        class = "indicator-wrapper",
        div(class = "indicator-dot"),
        div(class = "indicator-description", paste(settings, collapse = " | "))
      )
    })

    output$chat_history <- renderUI({
      messages <- chat_log()
      if (length(messages) == 0)
        return(NULL)

      # filter system messages
      messages <- messages[sapply(messages, function(msg) msg$role != "system")]

      result <- lapply(seq_along(messages), function(i) {
        msg <- messages[[i]]

        # determine message order
        msg_order <- (i == length(messages) && msg$role == "assistant") ||
          (i == max(which(
            sapply(messages, function(m) m$role == "user")
          )) && msg$role == "user")

        # message container
        msg_div <- div(class = paste(
          "message",
          if (msg$role == "user") {
            "user-message"
          } else if (msg$role == "file") {
            "file-message"
          } else {
            "bot-message"
          },
          ifelse(msg_order, "animate", "")
        ),
        HTML(commonmark::markdown_html(msg$content)))

        # model indicator
        if (msg$role == "assistant" && !is.null(msg$model)) {
          return(div(
            class = paste("message-wrapper", ifelse(msg_order, "animate", "")),
            msg_div,
            div(class = "model-indicator", msg$model)
          ))
        }

        msg_div
      })
      session$sendCustomMessage(type = "scrollCallback", "baseline")

      return(result)
    })

    chats <- reactiveVal(list())

    observeEvent(user_data, {
      # load chat user data
      if (file.exists(user_data)) {
        chats(readRDS(user_data))
      } else {
        chats(list())
      }
    })

    observeEvent(new_chat(), {
      # load chat data
      loaded_chats = chats()
      sel_chat = selected_chat()

      if (!is.null(sel_chat) && sel_chat %in% names(loaded_chats)) {
        loaded_chats[[sel_chat]] = chat_log()
        selected_chat(NULL)
      } else {
        # create new item
        log = chat_log()
        log = append(log, list(
          list(
            role = "user",
            content = "Given this chat log, give a short title for this conversation."
          )
        ))
        name_request = chat_builder(log = log, model = input$model_select)
        name = name_request[[length(name_request)]]$content
        input_id = fix_inputID(name)
        loaded_chats[[input_id]] = chat_log()
      }

      # set
      chats(loaded_chats)

      # reset the chat log
      chat_log(chatbotenv())
    })

    # delete chat
    observeEvent(delete_chat(), {
      loaded_chats = chats()
      del_chat = selected_chat()

      # remove chat from list
      if (!is.null(del_chat) && del_chat %in% names(loaded_chats)) {
        loaded_chats[[del_chat]] = NULL
        chats(loaded_chats)

        selected_chat(NULL)
      }

      # reset the chat log
      chat_log(chatbotenv())
    })

    # track selected
    selected_chat <- reactiveVal(NULL)

    # update model in selected chat
    observeEvent(selected_chat(), {
      sel_chat = chats()[[selected_chat()]]

      if (!is.null(sel_chat) && !is.null(sel_chat[[length(sel_chat)]]$model)) {
        recent_model = sel_chat[[length(sel_chat)]]$model
        updateSelectInput(session, "model_select", selected = recent_model)
      }
    })

    # chat option buttons
    observeEvent(input$attach_btn, {
      showModal(modalDialog(
        title = NULL,
        size = "s",
        easyClose = TRUE,
        footer = NULL,

        h4("Chat Attachments"),

        div(class = "setting-item", div(
          class = "setting-content",
          div(
            class = "setting-text",
            div(class = "setting-title", "Upload a file"),
            div(
              class = "setting-description",
              "Attach a document (.csv, .pdf, .txt) into the current chat"
            )
          ),
          div(
            class = "file-upload-wrapper",
            actionButton(ns("file_upload"), label = "Attach"),
            div(style = "display: none;", fileInput(
              ns("dummy_file_upload"),
              NULL,
              accept = c(".csv", ".pdf", ".txt")
            )),
          )
        ))
      ))
    })

    # dummy file upload
    observeEvent(input$file_upload, {
      shinyjs::runjs(sprintf(
        "document.getElementById('%s').click();",
        ns("dummy_file_upload")
      ))
    })
    observeEvent(input$dummy_file_upload, {
      file_name = input$dummy_file_upload$name

      # append upload message
      log = chat_log()
      log = append(log, list(list(
        role = "file",
        content = paste("You uploaded:", file_name)
      )))

      # insert into the chat
      log = chat_document_parser(log = log,
                                 file_path = input$dummy_file_upload$datapath)

      chat_log(log)
    })

    # chat option buttons
    observeEvent(input$context_btn, {
      showModal(modalDialog(
        title = NULL,
        size = "s",
        easyClose = TRUE,
        footer = NULL,

        h4("Chat Settings"),

        div(
          class = "setting-item",
          div(
            class = "setting-content",
            div(
              class = "setting-text",
              div(class = "setting-title", "Biology Mode"),
              div(class = "setting-description", "Chats have a biological focus")
            ),
            checkboxInput(
              ns("bio_mode"),
              NULL,
              value = chat_settings$bio_mode,
              width = "auto"
            )
          )
        )
      ))
    })

    list(
      chats = chats,
      chat_log = chat_log,
      selected_chat = selected_chat,
      input = input
    )
  })
}