# Source      | Sex | Age | R/E
# Decennial                  x
# LAC - 8                    x
# ESRI (Matt)                x
# Vintage        x     x     x
# DOF RW         x     x     x
# DOF            x     x     x
# ESRI: By Sex, By Race, by age, sex by age, sex by latino, age by latino, sex by age by latino
# ACS1/5: By Sex, By Race, by age, sex by age, sex by r/e, age by r/e, sex by age by r/e



library(shiny)
library(shinythemes)
library(shinyWidgets)
library(plotly)
library(ggh4x)
library(shinyjs)
library(readxl)
library(readr)
library(dplyr)
library(stringr)
library(ggplot2)
library(fs)
library(scales)
library(RColorBrewer)
library(tidyr)

# Plotting Standards -------------------------------------------------------------

# Color-blind friendly (9 colors) palette 
paletteCB <- c("#0072B2", # darker blue, 
               "#4A4A4A", # darker gray,
               "#D55E00", # darker orange
               "#117733", # green
               "#56B4E9", # lightblue
               "#4BE62F", # light green
               "#E69F00", # lighter orange
               "#CC79A7",  # pink
               "#b22222") # firebrick

# ggplot standards ---------------------

myTitleSize <- 20
myLegendSize <- 20


myTextSize <- 18
myAxisTextSize <- myTextSize2 <- 16
myAxisSize  <- myAxisTitleSize <- myTextSize3 <- 20

myWrapNumber <- 70
myTitleColor <- "darkblue"

myCex1           <- 2  # 1.5  #line labels
myCex2           <- 1.2  #currently used only in education trend
myLineLabelSpace <- 0.3

#myLineLabelSize <- 26 - deleted, not used

myLineLabelCex <- 2



myLineSize  <- 2
myPointSize <- 5 # line markers
myPointShape <- 18

myTheme <- theme_bw() +
  theme(plot.title   = element_text(size = myTitleSize, color=myTitleColor, face = 'bold'),
        strip.text.y = element_text(size = myTextSize2, face="bold", angle = 0),
        strip.text.x = element_text(size = myTextSize2, face="bold", angle = 0),
        axis.title   = element_text(size = myAxisTitleSize, face="bold"), # was myTextSize2, changed to myAxisSize
        axis.text.y  = element_text(size = myAxisTextSize),
        axis.text.x  = element_text(size = myAxisTextSize), 
        legend.text = element_text(size = myLegendSize), 
        legend.title = element_text(size = myLegendSize)
        #axis.text.x  = element_text(size = 10,          face="bold", angle = 40, hjust = 1),
  )

theme_set(myTheme)


# -- Plotly Standards ------------------

font_title <- list(size = myTitleSize,
                   color = myTitleColor
)

font_axisTitle <- list(size = myAxisTitleSize)

font_axisText <- list(size = myAxisTextSize + 20)

font_legend <- list(size = myLegendSize)


# Preparing "all_sources" population data -------------------------------------------------------------------

YEARS <- 2010:2021

myRaceNameShort <-  c("AI/AN", "Asian", "Black", "Latino", "Multi-Race", "NH/PI", "Other", "White", "Total")

population_df <- readRDS("all_sources.RDS")
# Unique values of sources column: Decennial, lac6, lac8, ESRI from Alameda, acs1. acs5, Census Vintage, 
# DOF Historical, DOF P3 (Vintage 2020), DOF P3 (Vintage 2023), DOF (Reweighted Vintage 2020), ESRI 2021

population_df <- population_df %>% 
  mutate(source = case_when(
    source == "lac6" ~ "LAC - 6", 
    source == "lac8" ~ "LAC - 8",
    source == "acs1" ~ "ACS1",
    source == "acs5" ~ "ACS5",
    TRUE ~ source
  )) %>%
  filter(source != "LAC - 6") 

myCounties <- sort(unique(population_df$county))

# There are 12 sources; paletteCB only contains 9 colors
typeColors_df <- data.frame(source = unique(population_df$source), sourceColor = c(paletteCB[c(4, 2, 1, 3, 5, 6, 7, 8, 9)], "red", "black", "yellow"))

sourceType_colors <- setNames(as.character(typeColors_df$sourceColor), as.character(typeColors_df$source))

population_df <- population_df %>%
  left_join(typeColors_df, by = "source") %>%
  mutate(raceNameShort = factor(raceNameShort, levels =  myRaceNameShort))


# Inputs
myAge5 <- population_df %>% 
  filter(ageType == "age5") %>% 
  distinct(ageGroup) %>% 
  pull(ageGroup)

myAge10 <- population_df %>% 
  filter(ageType == "age10", ageGroup != "Total") %>% 
  distinct(ageGroup) %>% 
  pull(ageGroup)

myAges <- unique(c(myAge5, myAge10))


# Life Expectancy Comparison: DOF (CCB) versus ESRI (Matt Beyers) - Alemeda County -----------------------------

esri_le <- readxl::read_excel("alamedaPop.xlsx", sheet = "le") %>%
  pivot_longer(-year, names_to = "raceCode", values_to = "ex") %>%
  mutate(type = "esri")

geoMap  <- as.data.frame(read_excel("County Codes to County Names Linkage.xlsx")) %>%
  select(FIPSCounty,county=countyName)

dof_le <- readRDS("e0ciCounty.RDS") %>%
  mutate(FIPSCounty=substr(GEOID,3,5))  %>%
  left_join(geoMap,by="FIPSCounty") %>%
  filter(county == "Alameda", year %in% 2005:2020, sex == "Total", 
         raceCode %in% c("Total", "Asian", "Black", "Hisp", "White"), nyrs == 1) %>%
  select(year, raceCode, ex) %>%
  mutate(type = "DOF P3 (Vintage 2020)")

le_long <- bind_rows(esri_le, dof_le)

le_wide <- le_long %>%
  pivot_wider(names_from = type, values_from = ex)


# DEATH DATASET
# datCounty <- readRDS(paste0(popPath, 'compare_datCounty.RDS')) %>%
#   filter(!raceNameShort %in% c("AI/AN", "NH/PI", "Other"), 
#          type != "lac6") %>%
#   mutate(type = ifelse(type == 'esri - matt', 'esri - Alameda', type))
# 
# 
# datCounty <- datCounty %>%
#   left_join(typeColors_df, by = "type") %>%
#   mutate(raceNameShort = factor(raceNameShort, levels =  myRaceNameShort))



# - FUNCTIONS -------------------------------------------------------

make_plot <- function(myCounty, myStrata, myDemos) {
  
  if (myStrata == "Sex") {
    mySex <- myDemos
    myRace <- "Total"
    myAge <- "Total"
    myAgeType <- "age5"
    myStrata1 <- "sex"
  } else if (myStrata == "Race/Ethnicity") {
    myRace <- myDemos
    mySex <- "Total"
    myAge <- "Total"
    myAgeType <- "age5"
    myStrata1 <- "raceNameShort"
  } else if (myStrata == "Age5") {
    mySex <- "Total"
    myRace <- "Total"
    myAgeType <- "age5"
    myStrata1 <- "ageGroup"
    myAge <- myDemos
  } else {
    mySex <- "Total"
    myRace <- "Total"
    myAgeType <- "age10"
    myStrata1 <- "ageGroup"
    myAge <- myDemos
  }
  
  tDat <- population_df %>%
    filter(county == myCounty, 
           raceNameShort %in% myRace, 
           sex %in% mySex, 
           ageGroup %in% myAge, 
           ageType == myAgeType, 
           !is.na(population), 
           year %in% YEARS) %>% 
    # filter(ageGroup != "Total") %>% 
    mutate(strata = !!as.symbol(myStrata1))
  
  if (myStrata == "Age5") tDat <- mutate(tDat, strata = factor(strata, levels = myAge5))
  if (myStrata == "Age10") tDat <- mutate(tDat, strata = factor(strata, levels = myAge10))
  
  # if ("acs1" %in% unique(tDat$source)) tDat <- tDat %>% filter(type != "acs5")
  
  ggplot(tDat, aes(x = year, y = population, color = source)) +
    geom_line(size = 1.5) +
    geom_point(size = ifelse(tDat$source == 'Decennial', 3, 0)) +
    #geom_point(shape = 21, fill = "white") +
    facet_wrap(facets = vars(strata), scales = "free") +
    scale_x_continuous(breaks = YEARS, label = YEARS, limits = c(min(YEARS), max(YEARS))) +
    scale_y_continuous(labels = scales::comma) +
    scale_color_manual(values = sourceType_colors, drop = TRUE, limits = force) +
    labs(x = "Year", y = "Population") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 12), 
          axis.text.y = element_text(size = 12),
          legend.text = element_text(size = 12),
          legend.title = element_text(size = 12),
          strip.text.y.right = element_text(angle = 0, size = 12), 
          strip.text.x = element_text(size = 12))
  
}


make_interPlot <- function(myCounty, myRace, mySex, myAge) {
  
  font_title <- list(size = myTitleSize,
                     color = myTitleColor
  )
  
  font_axisTitle <- list(size = myAxisTitleSize)
  
  font_axisText <- list(size = myAxisTextSize + 20)
  
  font_legend <- list(size = myLegendSize)
  
  myTitle <- paste0(mySex, " Sex, ", myAge, " Age Group, ", myRace, " R/E group Population in ", myCounty)
  
  tDat <- population_df %>%
    filter(county == myCounty, 
           raceNameShort == myRace, 
           sex == mySex, 
           ageGroup == myAge, 
           !is.na(population), 
           year %in% YEARS) %>% 
    distinct(county, year, raceNameShort, sex, ageGroup, source, .keep_all = TRUE)
  
  plot_ly(tDat, x = ~year, y = ~population, color = ~source, colors = sourceType_colors, type = 'scatter', mode = 'lines+markers') %>%
    layout(title = list(text = myTitle, font = font_title, x = 0.05), 
           xaxis = list(title = list(text = 'Year', font = font_axisTitle),
                        ticktext = YEARS, 
                        tickvals = YEARS), 
           yaxis = list(title = list(text = "Population", font = font_axisTitle)), 
           legend = list(font = font_legend), 
           margin = list(t = 50, r = 50, l = 50, b = 50, pad = 2))
  
}

compareLE <- function(raceCodes) {
  
  raceCode1 <- as.symbol(raceCodes[1])
  raceCode2 <- as.symbol(raceCodes[2])
  
  w_b <- le_long %>%
    filter(raceCode %in% raceCodes)
  
  p1 <- ggplot(w_b, aes(x = year, y = ex, color = type, linetype = raceCode)) +
    geom_line() +
    geom_point(fill = "white", shape = 21) 
  
  
  w_b_diff_re <- w_b %>%
    pivot_wider(names_from = raceCode, values_from = ex) %>%
    mutate(diff = {{ raceCode1 }} - {{ raceCode2 }})
  
  p2 <- ggplot(w_b_diff_re, aes(x = year, y = diff, color = type)) +
    geom_line() +
    geom_point(fill = "white", shape = 21) +
    labs(y = paste(raceCodes, collapse = " - ")) 
  
  return(list(trend = p1, diff = p2))
  
}


# DEATH PLOTS
# make_death_plot <- function(myCounty) {
#   
#   tDat <- datCounty %>%
#     filter(county == myCounty)
#   
#   if ("acs1" %in% unique(tDat$type)) tDat <- tDat %>% filter(type != "acs5")
#   
#   ggplot(tDat, aes(x = year, y = cDeathRate, color = type)) +
#     geom_line(size = 1.5) +
#     geom_point(size = ifelse(tDat$type == 'decennial', 3, 0)) +
#     #geom_point(shape = 21, fill = "white") +
#     facet_grid(rows = vars(raceNameShort), scales = "free") +
#     scale_x_continuous(breaks = 2010:2021, label = 2010:2021, limits = c(2010, 2021)) +
#     scale_color_manual(values = sourceType_colors, limits = force)
#   
# }
# 
# 
# make_death_interPlot <- function(myCounty, myRace) {
#   
#   font_title <- list(size = myTitleSize,
#                      color = myTitleColor
#   )
#   
#   font_axisTitle <- list(size = myAxisTitleSize)
#   
#   font_axisText <- list(size = myAxisTextSize + 20)
#   
#   font_legend <- list(size = myLegendSize)
#   
#   myTitle <- paste0(myRace, " Crude Death Rate in ", myCounty)
#   
#   tDat <- datCounty %>%
#     filter(raceNameShort == myRace, county == myCounty)
#   
#   if ("acs1" %in% unique(tDat$type)) tDat <- tDat %>% filter(type != "acs5")
#   
#   plot_ly(tDat, x = ~year, y = ~cDeathRate, color = ~type, colors = sourceType_colors, type = 'scatter', mode = 'lines+markers') %>%
#     layout(title = list(text = myTitle, font = font_title, x = 0.05), 
#            xaxis = list(title = list(text = 'Year', font = font_axisTitle),
#                         ticktext = 2010:2021, 
#                         tickvals = 2010:2021), 
#            yaxis = list(title = list(text = "Crude Death Rate", font = font_axisTitle)), 
#            legend = list(font = font_legend), 
#            margin = list(t = 50, r = 50, l = 50, b = 50, pad = 2))
#   
# }


ui <- fluidPage(theme = shinytheme("sandstone"), 
                
                
                navbarPage("Population Sources Assessment", 
                           tabPanel("Population Demographics", 
                                    
                                    inputPanel(
                                      selectInput('selectCounty', label = "Select County:",
                                                  choices = myCounties, selected = "CALIFORNIA"),
                                      selectInput('selectVariable', label = "Select Variable:", 
                                                  choices = c("Sex", "Age5", "Age10", "Race/Ethnicity")),
                                      selectizeInput("selectDemos", "Select Demographic Groups:", 
                                                  choices = c("Female", "Male", "Total"), 
                                                  selected = c("Female", "Male", "Total"),
                                                  multiple = TRUE)
                                    ),
                                    
                                    div(plotOutput(outputId = "demo_plot", height = 700, width = "75%"), align = 'center'),
                                    
                                    inputPanel(
                                      selectInput('selectRace', label = "Select Race/Ethnicity:",
                                                  choices = myRaceNameShort, selected = "Latino"), 
                                      selectInput('selectGender', label = "Select Race/Ethnicity:",
                                                  choices = c("Female", "Male", "Total"), selected = "Female"),
                                      selectInput('selectAge', label = "Select Age Group:",
                                                  choices = myAges, selected = "0 - 4")
                                    ),
                                    
                                    plotlyOutput(outputId = "plot_interactive", height = 800)
                           ), 
                           
                           tabPanel("Life Expectancy - Alameda County", 
                                    
                                    inputPanel(
                                      selectInput('compare1', label = "R/E 1:",
                                                  choices = unique(le_long$raceCode), selected = "White"),
                                      selectInput('compare2', label = "R/E 2:",
                                                  choices = unique(le_long$raceCode), selected = "Black")
                                    ),
                                    
                                    plotOutput(outputId = "le_alameda_plot1", height = 400), 
                                    plotOutput(outputId = "le_alameda_plot2", height = 400)
                           )
                ) 
)

server <- function(input, output) {
  
  currentVariable <- reactiveVal()
  observe({
    currentVariable(input$selectVariable)
    print(currentVariable())
  })
 
  # Race/Ethnicity Trend Plot - Static
  
  observeEvent(currentVariable(), {
    
    if (currentVariable() == "Sex") {
      updateSelectizeInput(inputId = "selectDemos", 
                        choices = c("Female", "Male", "Total"),
                        selected = c("Female", "Male", "Total")
                        )
      
    }
    
    if (currentVariable() == "Age5") {
      updateSelectizeInput(inputId = "selectDemos", 
                        choices = myAge5,
                        selected = myAge5
      )
    }
    
    if (currentVariable() == "Age10") {
      updateSelectizeInput(inputId = "selectDemos", 
                        choices = myAge10, 
                        selected = myAge10
      )
    }
    
    if (currentVariable() == "Race/Ethnicity") {
      updateSelectizeInput(inputId = "selectDemos", 
                        choices = myRaceNameShort, 
                        selected = myRaceNameShort
      )
    }
    
  })
  
  myStep <- reactive(make_plot(myCounty = input$selectCounty, 
                               myStrata = input$selectVariable, 
                               myDemos = input$selectDemos))
  
  output$demo_plot <- renderPlot(myStep())
  
  # Race/Ethnicity Trend Plot - Interactive
  
  my_hcStep <- reactive(make_interPlot(myCounty = input$selectCounty, 
                                       mySex = input$selectGender, 
                                       myAge = input$selectAge,
                                       myRace = input$selectRace))
  
  output$plot_interactive <- renderPlotly(my_hcStep())
  
  # Life Expectancy Alameda Plot
  
  my_leStep <- reactive(compareLE(c(input$compare1, input$compare2)))
  
  output$le_alameda_plot1 <- renderPlot(my_leStep()$trend)
  output$le_alameda_plot2 <- renderPlot(my_leStep()$diff)
   
}

shinyApp(ui = ui, server = server)