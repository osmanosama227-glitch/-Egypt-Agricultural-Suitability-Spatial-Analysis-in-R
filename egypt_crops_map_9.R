# ============================================================
#  Egypt Agricultural Suitability Map
#  Primary recommended crop per governorate
#  Student: Osman Osama | Egyptian Chinese University
#  Course:  Spatial Statistics - Dr. Mahmoud Eissa
# ============================================================
# HOW TO RUN:
#   1. Install packages below if not installed
#   2. Make sure you have internet for geodata::gadm()
#   3. Run the whole script — all files are saved in your working directory
# ============================================================

# ── 0. Packages ──────────────────────────────────────────────
required <- c("sf","ggplot2","dplyr","stringr","scales",
              "plotly","htmlwidgets","tidyr","geodata")

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

library(sf); library(ggplot2); library(dplyr); library(stringr)
library(scales); library(plotly); library(htmlwidgets)
library(tidyr); library(geodata)

# ── 1. Download Shapefile ────────────────────────────────────
cat("Downloading Egypt shapefile (GADM)...\n")
egypt_sf <- gadm("EGY", level = 1, path = tempdir()) |> st_as_sf()
cat("Loaded:", nrow(egypt_sf), "governorates\n")

# ── 2. Detect name column & export names CSV ─────────────────
name_col <- intersect(c("NAME_1","name","NAME"), names(egypt_sf))[1]
cat("Name column:", name_col, "\n")
cat("Governorates in shapefile:\n")
print(sort(egypt_sf[[name_col]]))

write.csv(data.frame(Governorate = egypt_sf[[name_col]]),
          "governorate_names.csv", row.names = FALSE)
cat("Saved: governorate_names.csv\n")

# ── 3. Agricultural Data ─────────────────────────────────────
crop_data <- tribble(
  ~Governorate,      ~Primary_Crop,    ~Secondary_Crop,   ~Tertiary_Crop,    ~Suitability_Score, ~Main_Factor,
  "Cairo",           "Vegetables",     "Herbs",           "Flowers",          45,  "Urban Agriculture",
  "Alexandria",      "Cotton",         "Vegetables",      "Citrus",           72,  "Mediterranean Climate",
  "Bur Sa`id",       "Rice",           "Fish Farming",    "Vegetables",       68,  "Water Availability",
  "Suez",            "Dates",          "Medicinal Herbs", "Drought Crops",    55,  "Desert Adaptation",
  "Dumyat",          "Rice",           "Cotton",          "Vegetables",       85,  "Nile Delta Fertility",
  "Ad Daqahliyah",   "Rice",           "Maize",           "Cotton",           90,  "Rich Delta Soil",
  "Ash Sharqiyah",   "Cotton",         "Wheat",           "Rice",             88,  "Delta Agriculture",
  "Al Qalyubiyah",   "Vegetables",     "Citrus",          "Cotton",           82,  "Nile Valley Soil",
  "Kafr ash Shaykh", "Rice",           "Cotton",          "Wheat",            87,  "Delta Water Supply",
  "Al Gharbiyah",    "Cotton",         "Rice",            "Maize",            89,  "Core Delta Region",
  "Al Minufiyah",    "Cotton",         "Vegetables",      "Wheat",            84,  "Delta Agriculture",
  "Al Buhayrah",     "Rice",           "Cotton",          "Wheat",            86,  "Western Delta Soil",
  "Al Isma'iliyah",  "Citrus",         "Vegetables",      "Grapes",           70,  "Sandy Reclaimed Land",
  "Giza",            "Vegetables",     "Cotton",          "Maize",            75,  "Nile Valley",
  "Bani Suwayf",     "Sugarcane",      "Wheat",           "Cotton",           78,  "Upper Egypt Soil",
  "Al Fayyum",       "Grapes",         "Olives",          "Vegetables",       80,  "Oasis Agriculture",
  "Al Minya",        "Sugarcane",      "Wheat",           "Maize",            77,  "Upper Egypt",
  "Asyut",           "Sugarcane",      "Wheat",           "Cotton",           74,  "Upper Egypt Valley",
  "Suhaj",           "Sugarcane",      "Wheat",           "Vegetables",       73,  "Nile Valley Soil",
  "Qina",            "Sugarcane",      "Dates",           "Wheat",            71,  "Upper Egypt Climate",
  "Aswan",           "Dates",          "Sugarcane",       "Tropical Fruits",  76,  "Tropical Climate",
  "Luxor",           "Sugarcane",      "Dates",           "Vegetables",       72,  "Hot Dry Climate",
  "Al Bahr al Ahmar","Dates",          "Medicinal Herbs", "Drought Crops",    40,  "Desert / Coastal",
  "Al Wadi at Jadid","Dates",          "Olives",          "Wheat",            58,  "Oasis Farming",
  "Matrouh",         "Olives",         "Barley",          "Dates",            60,  "Mediterranean Coast",
  "Shamal Sina'",    "Olives",         "Citrus",          "Wheat",            62,  "Sinai Reclaimed Land",
  "Janub Sina'",     "Dates",          "Medicinal Herbs", "Drought Crops",    38,  "Arid Desert"
)

write.csv(crop_data, "egypt_crops_data.csv", row.names = FALSE)
cat("Saved: egypt_crops_data.csv\n")

# ── 4. Smart Merge ───────────────────────────────────────────
clean <- function(x) {
  x |> str_to_lower() |>
    str_replace_all("[^a-z ]", " ") |>
    str_squish()
}

shp_clean  <- clean(egypt_sf[[name_col]])
crop_clean <- clean(crop_data$Governorate)

match_idx <- sapply(shp_clean, function(s) {
  m <- which(crop_clean == s)
  if (length(m)) return(m[1])
  # partial: first word match
  sw <- str_split(s, " ")[[1]][1]
  m2 <- which(str_starts(crop_clean, sw))
  if (length(m2)) return(m2[1])
  return(NA_integer_)
})

egypt_sf$Governorate       <- egypt_sf[[name_col]]
egypt_sf$Primary_Crop      <- crop_data$Primary_Crop[match_idx]
egypt_sf$Secondary_Crop    <- crop_data$Secondary_Crop[match_idx]
egypt_sf$Tertiary_Crop     <- crop_data$Tertiary_Crop[match_idx]
egypt_sf$Suitability_Score <- crop_data$Suitability_Score[match_idx]
egypt_sf$Main_Factor       <- crop_data$Main_Factor[match_idx]

egypt_merged <- st_make_valid(egypt_sf)

matched <- sum(!is.na(egypt_merged$Primary_Crop))
cat("Matched:", matched, "/", nrow(egypt_merged), "\n")
if (matched < nrow(egypt_merged)) {
  cat("Unmatched (check spelling):\n")
  print(egypt_merged$Governorate[is.na(egypt_merged$Primary_Crop)])
}

# ── 5. Centroids (plain data.frame — avoids sfc_GEOMETRY error) ──
pts <- st_point_on_surface(st_geometry(egypt_merged))
centroids_df <- data.frame(
  Governorate       = egypt_merged$Governorate,
  Suitability_Score = egypt_merged$Suitability_Score,
  lon = vapply(pts, `[[`, numeric(1), 1),
  lat = vapply(pts, `[[`, numeric(1), 2),
  stringsAsFactors  = FALSE
)

# ── 6. Color Palette ─────────────────────────────────────────
crop_colors <- c(
  "Rice"            = "#4CAF50",
  "Cotton"          = "#C8A97E",
  "Sugarcane"       = "#8BC34A",
  "Dates"           = "#FF8F00",
  "Wheat"           = "#FDD835",
  "Vegetables"      = "#26C6DA",
  "Citrus"          = "#FFA726",
  "Grapes"          = "#7B1FA2",
  "Olives"          = "#827717",
  "Maize"           = "#F9A825",
  "Medicinal Herbs" = "#66BB6A",
  "Drought Crops"   = "#BCAAA4",
  "Fish Farming"    = "#0288D1",
  "Tropical Fruits" = "#E91E63",
  "Flowers"         = "#F48FB1",
  "Herbs"           = "#A5D6A7",
  "Barley"          = "#D4A017"
)

# ── 7. Static Map ────────────────────────────────────────────
cat("Creating static map...\n")
p_static <- ggplot(egypt_merged) +
  geom_sf(aes(fill = Primary_Crop), color = "white", linewidth = 0.4) +
  scale_fill_manual(values = crop_colors, na.value = "#DDDDDD",
                    name = "Primary Crop") +
  # BONUS: governorate labels
  geom_text(data = centroids_df,
            aes(x = lon, y = lat, label = Governorate),
            size = 1.7, color = "#111111", fontface = "bold",
            check_overlap = TRUE) +
  labs(
    title    = "Agricultural Suitability Map of Egypt",
    subtitle = "Primary recommended crop per governorate | climate, soil & water resources",
    caption  = "Data: CAPMAS / FAO Egypt | Spatial: GADM | Student: Osman Osama - ECU"
  ) +
  theme_void(base_size = 12) +
  theme(
    plot.title      = element_text(size = 16, face = "bold", hjust = 0.5,
                                   margin = margin(b = 5)),
    plot.subtitle   = element_text(size = 9, color = "grey40", hjust = 0.5,
                                   margin = margin(b = 10)),
    plot.caption    = element_text(size = 7, color = "grey60"),
    legend.position = "right",
    legend.title    = element_text(face = "bold", size = 10),
    legend.text     = element_text(size = 8),
    plot.background = element_rect(fill = "#F9F6EF", color = NA),
    plot.margin     = margin(15, 15, 15, 15)
  )

ggsave("egypt_crops_map.png", p_static,
       width = 12, height = 10, dpi = 300, bg = "#F9F6EF")
cat("Saved: egypt_crops_map.png\n")

# ── 8. Interactive Map with governorate labels ──
cat("Creating interactive map...\n")
egypt_merged <- egypt_merged |>
  mutate(tooltip = paste0(
    "<b>", Governorate, "</b><br>",
    "Primary Crop: ",      Primary_Crop,      "<br>",
    "Secondary Crop: ",    Secondary_Crop,    "<br>",
    "Tertiary Crop: ",     Tertiary_Crop,     "<br>",
    "Suitability Score: ", Suitability_Score, "/100<br>",
    "Key Factor: ",        Main_Factor
  ))

p_inter <- ggplot(egypt_merged) +
  geom_sf(aes(fill = Primary_Crop, text = tooltip),
          color = "white", linewidth = 0.3) +
  scale_fill_manual(values = crop_colors, na.value = "#DDDDDD",
                    name = "Primary Crop") +
  # Governorate labels on interactive map
  geom_text(data = centroids_df,
            aes(x = lon, y = lat, label = Governorate),
            size = 1.7, color = "#111111", fontface = "bold",
            check_overlap = TRUE, inherit.aes = FALSE) +
  labs(title = "Agricultural Suitability Map of Egypt") +
  theme_void() +
  theme(plot.background = element_rect(fill = "#F9F6EF", color = NA))

p_plotly <- ggplotly(p_inter, tooltip = "text") |>
  layout(
    title      = list(text = "<b>Egypt Agricultural Suitability Map</b>",
                      font = list(size = 18)),
    hoverlabel = list(bgcolor = "white", font = list(size = 12),
                      bordercolor = "#4CAF50"),
    paper_bgcolor = "#F9F6EF"
  )

saveWidget(p_plotly, "egypt_crops_map.html", selfcontained = TRUE)
cat("Saved: egypt_crops_map.html\n")

# ── 9. BONUS: Suitability Score Map ──────────────────────────
p_score <- ggplot(egypt_merged) +
  geom_sf(aes(fill = Suitability_Score), color = "white", linewidth = 0.4) +
  scale_fill_gradientn(
    colors   = c("#D32F2F","#FF8F00","#FDD835","#66BB6A","#1B5E20"),
    values   = scales::rescale(c(30, 50, 65, 80, 95)),
    name     = "Score\n(0-100)", na.value = "#DDDDDD"
  ) +
  # BONUS: score labels per governorate
  geom_text(data = centroids_df,
            aes(x = lon, y = lat, label = Suitability_Score),
            size = 2, color = "white", fontface = "bold",
            check_overlap = TRUE) +
  labs(
    title    = "Agricultural Suitability Score by Governorate",
    subtitle = "Score 0-100: soil quality, water access & climate conditions",
    caption  = "Student: Osman Osama - Egyptian Chinese University"
  ) +
  theme_void(base_size = 11) +
  theme(
    plot.title      = element_text(size = 14, face = "bold",
                                   hjust = 0.5, color = "white"),
    plot.subtitle   = element_text(size = 8, color = "grey70", hjust = 0.5),
    plot.background = element_rect(fill = "#1A1A2E", color = NA),
    legend.title    = element_text(color = "white", face = "bold"),
    legend.text     = element_text(color = "white"),
    plot.caption    = element_text(color = "grey60", size = 7),
    plot.margin     = margin(15, 15, 15, 15)
  )

ggsave("egypt_suitability_score.png", p_score,
       width = 12, height = 10, dpi = 300, bg = "#1A1A2E")
cat("Saved: egypt_suitability_score.png\n")

# ── 10. Export Shapefile ──────────────────────────────────────
st_write(egypt_merged, "egypt_crops.shp", delete_dsn = TRUE)
cat("Saved: egypt_crops.shp\n")

cat("\nDone! All 6 files created:\n")
cat("  governorate_names.csv\n")
cat("  egypt_crops_data.csv\n")
cat("  egypt_crops_map.png       <- Static map\n")
cat("  egypt_suitability_score.png <- Bonus score map\n")
cat("  egypt_crops_map.html      <- Interactive map\n")
cat("  egypt_crops.shp           <- Shapefile\n")
