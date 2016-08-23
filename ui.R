library(shiny)
library(RPostgreSQL)
library(leaflet)


#source("hjelp.R", local = TRUE)
library(RPostgreSQL)
#dbDisconnect(con)
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "ikap", host = "10.68.0.77",
                 port = 5432, user = "postgres", password = "ogc4tk")
postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")

sporkom <- "select distinct(region) from statistikk.hele01222 order by 1"
kom <- dbGetQuery(con, sporkom)
sporkvart <- "select distinct(kvartal) from statistikk.hele01222 order by 1"
kvart <- dbGetQuery(con, sporkvart)
sporvari <- "select distinct(statistikkvariabel) from statistikk.hele01222 order by 1 desc"
vari <- dbGetQuery(con, sporvari)

dbDisconnect(con)

shinyUI(fluidPage(

  # Application title
  titlePanel("Befolkningstal"),

  # Sidebar
  sidebarLayout(
    sidebarPanel(
      selectInput("komm",
                  "Kommune:",
                  choices = kom,
                  selected = "16 Sør-Trøndelag",
                  multiple = TRUE
                  ),
      selectInput("variabel", 
                  "velg variabel",
                   choices = vari,
                   selected = "Folkevekst",
                   multiple = FALSE),
      sliderInput("daterange", "Fra-Til",
                     min = 1997, max = 2020,
                    value = c(2010, 2016)
                     )
    ),

    # Main UI
    mainPanel(
      tabsetPanel(
        tabPanel("Grafikk", plotOutput("plot")),  #, height = 1800),
        tabPanel("Tabell", tableOutput("table")),
        tabPanel("Samendrag", verbatimTextOutput("summary")),
        tabPanel("Kart", leafletOutput("kart"), 
                 absolutePanel(top = 50, right = 10,
                              
                               selectInput("kvarta", "Kvartal",
                                           kvart
                               ),
                               checkboxInput("legend", "Tegforklaring", TRUE)
                 ))
      )
    )
  )
))

