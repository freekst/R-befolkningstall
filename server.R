library(shiny)
library(RPostgreSQL)
library(ggplot2)
library(leaflet)
library(dplyr)
library(maptools)
library(RColorBrewer)
# source("hjelp.R", local = TRUE)

library(RPostgreSQL)

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "ikap", host = "10.68.0.77",
                 port = 5432, user = "postgres", password = "ogc4tk")
postgresqlpqExec(con, "SET client_encoding = 'windows-1252'")


sporkom <- "select region, kvartal, substring(kvartal,1, 4) as ar, statistikkvariabel, value as antal from statistikk.hele01222"
hele <- dbGetQuery(con, sporkom)
dbDisconnect(con)
norMap <- readShapePoly(fn = "norge2013")
helekommnr <- mutate(hele, kommnr = substr(region, 1, 4))
helekommnr <- filter(helekommnr, grepl("[0-9][0-9][0-9][0-9]", kommnr))
#mutate(hele, år = substr(kvartal, 1, 4))
#pal = "red"
pal <- colorNumeric(
  palette = "Blues",
  domain = helekommnr$antal
)


shinyServer(function(input, output) {
  selectedData <- reactive({
        filter(hele, region %in% input$komm & statistikkvariabel %in% input$variabel & ar >= input$daterange[1] & ar <= input$daterange[2] )
    })
  
  kartData <- reactive({
    p <- filter(helekommnr, statistikkvariabel == input$variabel & kvartal == input$kvarta)
    p <- mutate(p, farge=pal(antal))
    p <- merge(norMap, p, all.x = TRUE, by = "kommnr")
  })

  colorpal <- reactive({
    colorNumeric("YlOrRd", kartData$antal)
  })
    
  output$plot <- renderPlot({

   p <- ggplot(selectedData(), aes(x = kvartal, y = antal, group = region, color = region)) + geom_line()
   #p <- p + theme_bw()
   p <- p + theme(axis.text.x = element_text(angle = -90, hjust = 1))
   #height= "100%"            library
   p
   

  })
  
  output$table <- renderTable(selectedData())
  output$summary <- renderPrint({
    #print(pal)
   #print(input$komm[1])
    # print(selectedData())
    #print(max(selectedData()$kvartal))
    #print(input$daterange)
   #summary(selectedData())
   summary(kartData())
  })
  #output$summary <- renderPrint(input$komm)

    output$kart <- renderLeaflet({
     # pal <- colorQuantile("YlGn", kartData$value, n = 5)
    leaflet() %>% setView(10, 63.4, 7) %>%
      addWMSTiles("http://openwms.statkart.no/skwms1/wms.topo2.graatone?",
                                 layers = "topo2_graatone_WMS",
                                 attribution = "Data © Kartverket-SSB") %>%
        addPolygons(data = kartData(), color = ~paste(farge), weight = 4, popup = ~paste("<h5>", region,  "</h5>",statistikkvariabel, antal), fillColor = ~paste(farge), fillOpacity = 0.8)

  })
     # observe({
     #   pal <- colorpal()
    #   
    #   leafletProxy("map", data = kartData()) %>%
    #     clearShapes() %>%
    #     addCircles(radius = ~10^mag/10, weight = 1, color = "#777777",
    #                fillColor = ~pal(mag), fillOpacity = 0.7, popup = ~paste(mag)
    #     )
    #})
  
})
