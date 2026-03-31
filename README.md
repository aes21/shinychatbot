# shinychatbot
Localised R Shiny Interface for Ollama LLM Interaction

## Core Architecture
The 

### RAG model
 - Files can be attached to the chat log by

## Getting started
You must download a local installation of [Ollama](https://github.com/ollama/ollama). Verfiy your installation using `http://localhost:11434`. You must download models for them to be accessible from within the R Shiny application:

```bash
ollama pull <model_name?
```

### Clone the repository
```bash
git clone https://github.com/aes21/shinychatbot.git
```

### Run the application
Install R environment dependencies.

```bash
Rscript -e "renv::restore()"
```

Within a new R session, initiate the application:

```r
shiny::runApp("~/shinychatbot")
```
