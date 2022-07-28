# Authors: 
#
# Melton Team - Jacob Voyles, 
#               Sydney Yeagers, 
#               Dana Kenney, 
#               William Holbert, 
#               Tatumn Laughery
#
#

#### Load Libraries and Data and Info #### 

library(shiny)
library(leaflet)
library(dygraphs)
library(xts)
library(dplyr)
library(shinydashboard)
library(ggplot2)
source("functions.R")

datacenter_data_full <- read.csv("/cloud/project/Data/datacenter_data.csv")
datacenter_data <- subset(datacenter_data_full, Country == 'United States')
climate_area <- read.csv("/cloud/project/Data/ClimateChangeArea.csv")
climate_us <- subset(climate_area, Area == 'North America')
states <- unique(datacenter_data$State)
regions <- unique(datacenter_data$Region)

##### LIST OF INPUTS #####
  # dc_per_year --------- This is for number of new datacenters per year for calculation
  # new_per_year -------- Number of new datacenters per year
  # avg_size ------------ Average size of the datacenters made each year
  # avg_pue ------------- Average PUE score of new datacenters
##### LIST OF OUTPUTS #####
  # buybackBox ---------- Outputs a dollar amount of buybacks
  # map ----------------- Leaflet map that shows datacenters and popup statistics
  #


#### App UI ####
ui <- fluidPage(
  navbarPage("Microsoft United States Datacenter Consumption", id = "nav",
    ###### Interactive Map Tab ######
    tabPanel("Interactive map",
      div(class = "outer",
          tags$head(
            includeCSS("MapFiles/styles.css"),
            includeScript("MapFiles/gomap.js")
          ),
          
          leafletOutput("map"),
          
          ###### Side Panel Inputs #######
          absolutePanel(id = "controls", 
            class = "panel panel-default", 
            fixed = FALSE,
            draggable = TRUE, 
            top = 60, 
            left = "auto", 
            right = 20, 
            bottom = "auto",
            width = 330, 
            height = "auto",
              
            # infoBoxOutput("buybackBox"),
            h2("Explorer"),
            sliderInput("new_per_year", label = "Number of Years to Project",
                        min = 0, max = 100, value = 10, step = 1),
            sliderInput("dc_per_year", label = "# of New Datacenters per year:",
                      min = 0, max = 100, value = 20, step = 10),
            sliderInput("average_size", label = "Average Size",
                        min = 0, max = 100000, value = 39000, step = 1000),
            sliderInput("average_pue", label = "Average PUE",
                        min = 0.0, max = 10.0, value = 1.34, step = 0.01),
        ),
        plotOutput("trendline"),
        plotOutput("buyback_trendline")
      )
    ),
    
    ##### Data Explorer Tab #####
    tabPanel("Data Explorer",
        fluidRow(
          column(3,
            selectInput("state", "State",datacenter_data$State)
          ),
          column(3,
            selectInput("cities", "Cities", datacenter_data$City)
          ),
          column(3,
            selectInput("region", "Region", datacenter_data$Region)    
          )
        ),
        hr(),
        #DT:dataTableOutput("datacenter_data")
    )
  )
)

## Server Functions ######## 

server <- function(input, output){ 
  
  #### Custom Icons ####
  
  microsoft_icon <- makeIcon(
    iconUrl = "microsoft_icon.png",
    iconWidth = 38, iconHeight = 95,
    iconAnchorX = 22, iconAnchorY = 94,
  )
  database_icon <- makeIcon(
    iconUrl = "data_icon.png",
    iconWidth = 38, iconHeight = 95,
    iconAnchorX = 22, iconAnchorY = 94,
  )
  
  #### Leaflet Map ####
  
  output$map <- renderLeaflet({
    leaflet(data = datacenter_data) %>%
      addTiles() %>%
      addMarkers(lng = ~Longitude, 
                 lat = ~Latitude,
                 icon = ifelse(datacenter_data$Data.Center.Operator=="Microsoft",
                               microsoft_icon, database_icon),
                 popup = paste("Name: ", datacenter_data$Name, "<br>", 
                               "City: ", datacenter_data$City, "<br>", 
                               "Country: ", datacenter_data$Country))
  })
  
  #### Carbon Trendline ####
  
  output$trendline <- renderPlot({
    ggplot(climate_us, 
           aes('Year (C7.2-7.5)', 'Scope 1 Emissions (metric tons CO2e)' )) + geom_line()
  })
  
  #### Carbon Buyback Info Box ####
  
  output$buybackBox <- renderInfoBox({
    infoBox(
      "Carbon Buyback", "80%", icon = icon("dollar", lib = "glyphicon"), color = "blue", fill = TRUE
    )
  })
  
}

####### Run ####### 
shinyApp(ui = ui, server = server)