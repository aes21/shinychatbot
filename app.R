library(bslib)
library(commonmark)
library(httr)
library(markdown)
library(jsonlite)
library(shiny)
library(shinyBS)
library(shinydashboard)
library(shinyjs)
library(shinyWidgets)
library(stringr)

# functions
source("R/chat.R")
source("R/chunker.R")
source("R/embedder.R")
source("R/parser.R")
source("R/zzz.R")

# modules
source("R/modules/modules.R")

ui <- fluidPage(
  useShinyjs(),
  tags$head(
    # font
    tags$link(
      rel = "stylesheet",
      href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
    )
  ),
  br(),
  actionButton(
    "new_chat",
    label = "New Chat",
    icon = icon("up-right-from-square"),
    class = "nchat_button"
  ),
  br(),
  h6("Chats"),
  div(class = "chat_logbook",
    uiOutput("chat_logger")
  ),
  includeCSS("www/images/styles.css"),
  includeScript("www/images/scripts.js"),
  absolutePanel(
    wellPanel(chatbotUI("chat")),
    width = "65vw",
    top = "50%",
    left = "57%",
    style = "transform: translate(-50%, -50%);",
    draggable = FALSE,
    div(
      h6("Always check answers, never treat responses as factual.",
         style = "color: #999; text-align: center; font-size: 9px;")
    )
  ),
  includeHTML("www/images/footer.html")
)

server <- function(input, output, session) {
  chat_module <- chatbotServer(
    id = "chat",
    new_chat = reactive(input$new_chat),
    delete_chat = reactive(input$delete_chat),
    user_data = "www/data/chats.rds"
  )

  output$chat_logger <- renderUI({
    ns = NS("chat")

    # id selected chat
    selected = chat_module$selected_chat()

    # generate buttons
    lapply(rev(names(chat_module$chats())), function(label) {
      is_selected = !is.null(selected) && selected == label

      btn_class = if (is_selected) {
        "btn btn-default selected"
      } else {
        "btn btn-default"
      }

      chat_btn = actionButton(
        inputId = ns(label),
        label = label,
        class = btn_class
      )

      if (is_selected) {
        div(
          style = "display: flex; align-items: center; gap: 4px;",
          chat_btn,
          actionButton(
            inputId = "delete_chat",
            label = icon("trash"),
            class = "logbook-buttons"
          )
        )
      } else {
        chat_btn
      }
    })
  })

  observe({
    lapply(names(chat_module$chats()), function(label) {
      observeEvent(chat_module$input[[label]], {
        content = chat_module$chats()[[label]]
        chat_module$chat_log(content)
        chat_module$selected_chat(label)
      })
    })
  })

  # info pop-up
  observeEvent(input$info_circle, {
    info = paste(readLines("www/images/log.md"), collapse = "\n")
    info_text = markdown::markdownToHTML(text = info, fragment.only = TRUE)

    showModal(
      modalDialog(
        title = NULL,
        size = "l",
        easyClose = TRUE,
        footer = NULL,

        HTML(info_text)
      )
    )
    session$sendCustomMessage("modalBackdrop", list())
  })

  onStop(function() {
    saveRDS(isolate(chat_module$chats()), file = "www/data/chats.rds")
  })
}

shinyApp(ui, server)