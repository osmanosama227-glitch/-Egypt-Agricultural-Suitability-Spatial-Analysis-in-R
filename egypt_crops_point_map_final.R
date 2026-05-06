# ============================================================
# MEANINGFUL VISUALIZATION: COLOR BY REGION & SIZE BY DATA
# ============================================================

# 1. Load libraries
library(leaflet)
library(htmlwidgets)
library(mapview)
library(htmltools)
library(RColorBrewer)

# 2. Enhanced Data with "Region" for Color Coding
egypt_agri_data <- data.frame(
  gov = c("Cairo", "Giza", "Alexandria", "Dakahlia", "Sharkia", "Beheira", 
          "Gharbia", "Monufia", "Qalyubia", "Kafr El Sheikh", "Damietta", 
          "Minya", "Assiut", "Sohag", "Qena", "Luxor", "Aswan", "Fayoum", 
          "Beni Suef", "New Valley", "Matrouh", "North Sinai", "South Sinai", "Ismailia"),
  region = c("Urban", "Middle", "Coast", "Delta", "Delta", "Delta", 
             "Delta", "Delta", "Delta", "Delta", "Coast", 
             "Upper", "Upper", "Upper", "Upper", "Upper", "Upper", "Middle", 
             "Middle", "Desert", "Coast", "Desert", "Desert", "Suez Canal"),
  lat = c(30.0444, 30.0131, 31.2001, 31.0425, 30.7327, 31.0364, 30.8675, 30.5972, 
          30.3292, 31.1107, 31.4175, 28.0871, 27.1783, 26.5591, 26.1551, 25.6872, 
          24.0889, 29.3084, 29.0744, 25.4390, 31.3543, 31.1249, 28.5063, 30.5965),
  lng = c(31.2357, 31.2089, 29.9187, 31.3558, 31.7136, 30.4612, 31.0253, 30.9876, 
          31.2168, 30.9388, 31.8144, 30.7618, 31.1859, 31.6957, 32.7160, 32.6396, 
          32.8998, 30.8428, 31.0979, 30.5586, 27.2373, 33.8006, 34.0031, 32.2715),
  crops = c("Vegetables, Maize, Fruits", "Wheat, Maize, Vegetables", "Wheat, Tomatoes, Potatoes", 
            "Rice, Wheat, Sugar Beet", "Wheat, Rice, Maize", "Wheat, Potatoes, Citrus", 
            "Wheat, Rice, Potatoes", "Wheat, Maize, Potatoes", "Vegetables, Fruits, Maize", 
            "Rice, Sugar Beet, Wheat", "Rice, Wheat, Guava", "Wheat, Sugar Beet, Maize", 
            "Wheat, Maize, Cotton", "Wheat, Sugar Cane, Maize", "Sugar Cane, Wheat, Tomatoes", 
            "Sugar Cane, Wheat, Tomatoes", "Sugar Cane, Wheat, Dates", "Wheat, Maize, Cotton", 
            "Wheat, Maize, Vegetables", "Dates, Wheat, Medicinal Plants", "Olives, Figs, Barley", 
            "Olives, Dates, Vegetables", "Medicinal Plants, Olives, Dates", "Mango, Citrus, Vegetables")
)

# 3. Create a Color Palette based on Regions
pal <- colorFactor(palette = "Set1", domain = egypt_agri_data$region)

# 4. Format labels
hover_labels <- sprintf(
  "<strong>%s (%s)</strong><br/>Top Crops: %s",
  egypt_agri_data$gov, egypt_agri_data$region, egypt_agri_data$crops
) %>% lapply(htmltools::HTML)

# 5. Build the Map
map_viz <- leaflet(data = egypt_agri_data) %>%
  addProviderTiles(providers$CartoDB.Voyager) %>%
  setView(lng = 31.0, lat = 27.5, zoom = 6) %>%
  addCircleMarkers(
    lng = ~lng, lat = ~lat,
    # Radius is fixed here, but could be tied to data (e.g., radius = ~sqrt(production_value))
    radius = 10,
    # Color is now meaningful (mapped to the region)
    color = "white",
    weight = 1,
    fillColor = ~pal(region),
    fillOpacity = 0.8,
    label = hover_labels,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "13px",
      direction = "auto"
    )
  ) %>%
  # Add a Legend so the colors make sense
  addLegend(
    pal = pal, 
    values = ~region, 
    title = "Agricultural Region",
    position = "bottomright"
  )

# 6. Export
saveWidget(map_viz, file = "egypt_meaningful_map.html", selfcontained = TRUE)
mapshot(map_viz, file = "egypt_meaningful_map.png")

# Preview
map_viz