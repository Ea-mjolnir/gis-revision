# GIS revision projects (QGIS 4.2)

## Projects
- [Project 1 – Green Space Equity in Berlin](p1-green-space/README.md)
- [Project 2 – Urban Heat and Vegetation Change Detection](urban-heat-and-vegetation-change-detection/README.md)
- [Project 3 – Terrain, Heavy Rain and 3D City (Berlin)](terrain-heavy-rain-3d-city-berlin/README.md)
- [Project 4 – Cycling Accident Hotspots with PostGIS (Berlin)](cycling-accident-hotspots-postgis-berlin/README.md)
- [Project 5 – Automated GEOINT Site Monitoring](p5-site-monitoring/README.md)

## Data sources and licences
Data files over 50 MB are not in this repository; each project README says where to download them.

| Data | Source | Licence | Used in |
|---|---|---|---|
| Roads, land use, buildings, water | © OpenStreetMap contributors (Geofabrik Berlin extract, 2026-11-02) | [ODbL 1.0](https://opendatacommons.org/licenses/odbl/) | P1–P4, practice project |
| Neighbourhood boundaries (Ortsteile), ALKIS | Geoportal Berlin / [gdi.berlin.de](https://gdi.berlin.de) | dl-de/zero-2-0 | P1, P2, P4 |
| DGM1 terrain, ALS point cloud 2021, LoD2 buildings | Geoportal Berlin ATOM feeds ([gdi.berlin.de](https://gdi.berlin.de)) | dl-de/zero-2-0 | P3 |
| Orthophotos 2018 and 2024 (reference only) | Geoportal Berlin WMS | Geoportal Berlin terms | P2, P3 |
| Population, 100 m grid (Zensus 2022) | Statistisches Bundesamt (Destatis) | dl-de/by-2-0 | P1 |
| Road accidents with injuries 2018–2025 (Unfallatlas) | Statistische Ämter des Bundes und der Länder | dl-de/by-2-0 | P4 |
| Sentinel-2 L2A | Copernicus, via Earth Search STAC | Copernicus open data | P2 |
| Landsat 8/9 Collection 2 Level-2 | USGS, via Microsoft Planetary Computer | USGS public data | P2 |
| ESA WorldCover 2021 | © ESA WorldCover project, via Planetary Computer | CC BY 4.0 | P2 |
| Copernicus DEM GLO-30 | © DLR e.V. 2010–2014 and © Airbus Defence and Space GmbH 2014–2018, provided under COPERNICUS by the European Union and ESA | Copernicus DEM licence | P2, practice project |
| Air temperature, Berlin-Tempelhof | Deutscher Wetterdienst (DWD), via Bright Sky API | DWD open data (CC BY 4.0) | P2 |

The practice project (`try_project/`, Tema) uses OSM data and **synthetic** LoD2 buildings made for practice; they are not official data.

Licence texts: [dl-de/zero-2-0](https://www.govdata.de/dl-de/zero-2-0), [dl-de/by-2-0](https://www.govdata.de/dl-de/by-2-0), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
