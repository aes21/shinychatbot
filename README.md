# shinychatbot
Localised R Shiny Interface for Ollama LLM Interaction.

An interactive web application built in R Shiny providing an interface for querying local Large Language Models (LLMs) via Ollama. This tool ensures complete data privacy by keeping all inference and processing local. 

## Key Features
- **Deploy local models:** Interface directly with any model hosted on your local Ollama instance.
- **Customise chat behaviour:** A.
- **Upload and interrogate complex datasets:** B.

### RAG model
Files uploaded to

### Knowledge base
The application

## Getting started
You must download a local installation of [Ollama](https://github.com/ollama/ollama). Verfiy your installation using `http://localhost:11434`. You must download models for them to be accessible from within the R Shiny application:

```bash
ollama pull <model_name>
```

### Clone the repository

```bash
git clone https://github.com/aes21/shinychatbot.git
cd shinychatbot
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
