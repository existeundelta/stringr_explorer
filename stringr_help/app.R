library(shiny)
library(shinythemes)
library(stringr)
library(glue)
library(tidyverse)
library(shinyjs)
library(shinyBS)

## read data
dat <- readRDS("dat.rds")

## UI ----------------------------------
ui <- fluidPage(theme = shinytheme("flatly"),
                useShinyjs(),
                
                # Application title
                titlePanel("Stringr Explorer"),
                
                # Sidebar with a slider input for number of bins 
                sidebarLayout(
                  sidebarPanel(
                    
                    ## 1st level select input
                    selectInput("want", "I want to",
                                choices = unique(dat$str_fn_title)),
                    
                    ## 2nd level select input 
                    uiOutput("select_level2")
                  ),
                  ## Main panel -----------------------------------------------------
                  mainPanel(
                    fluidRow(column(width = 12,
                                    conditionalPanel("output.cond",
                                                     ## function name
                                                     tags$h3(textOutput("fn_name")),
                                                     ## function usage
                                                     tags$h4("Usage"),
                                                     verbatimTextOutput("usage"),
                                                     ## function example
                                                     tags$h4("Example"),
                                                     verbatimTextOutput("expr"),
                                                     ## function example output
                                                     tags$h4("Output"),
                                                     verbatimTextOutput("expr_res"),
                                                     
                                                     ## bootstrap collapse to include documentation (default: closed)
                                                     bsCollapse(id = "doc_collapse",
                                                                # open = "R_Documentation",
                                                                bsCollapsePanel("R_Documentation",
                                                                                htmlOutput("doc"),
                                                                                style = "info")))
                    ))
                  )
                )
)

## Server -------------------------------------
server <- function(input, output, session) {
  
  ## panel condition -----------------
  output$cond <- reactive({
    req(expression_txt())
    length(expression_txt())
  })
  
  outputOptions(output, "cond", suspendWhenHidden = FALSE) 
  
  ## get example_title to show in select_level2 selectInput -----------
  fn_level2 <- reactive({
    req(input$want)
    dat %>% 
      filter(str_fn_title == input$want) %>% 
      pull(example_title)
  })
  
  ## selectInput including level2 choices ------------------------
  output$select_level2 <- renderUI({
    req(fn_level2())
    selectInput("ex_title", "", choices = fn_level2())
  })
  
  ## get the row corresponding to the selected values
  fn_selected <- reactive({
    req(input$want, input$ex_title)
    dat %>%
      filter(str_fn_title == input$want,
             example_title == input$ex_title)
  })
  
  ## print funcion name
  output$fn_name<- renderText({
    fn_selected()[["str_fn_names"]]
  })
  
  ## get the expression corresponding to the selected function --------------------
  expression_txt <- reactive({
    req(fn_selected())
    
    fn_selected()[["example"]] %>% 
      unique()
  })
  
  ## print selected expression 
  output$expr <- renderText({
    req(expression_txt())
    
    expression_txt() %>%  
      glue()
  })
  
  ## evaluate selected expression and print the result
  output$expr_res <- renderPrint({
    req(expression_txt())
    parse(text = expression_txt()) %>% eval
  })
  
  ## print function usage
  output$usage <- renderPrint({
    req(fn_selected())
    
    fn_selected()[["str_fn_usage"]] %>% 
      unique() %>% 
      unlist() %>% 
      glue()
  })
  
  ##print doc for selected function
  output$doc <- renderPrint({
    req(nrow(fn_selected())>0)
    tools:::Rd2HTML(fn_selected()$str_fn_help[[1]])
  })
  
  # observeEvent(input$want, ({
  #   updateCollapse(session, "doc_collapse", close = "R_Documentation")
  # }))
}

# Run the application 
shinyApp(ui = ui, server = server)

