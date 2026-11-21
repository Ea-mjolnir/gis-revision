# Project 1 – Green Space Equity in Berlin

**Status:** in progress (population map complete; green-space access analysis next)
**Tools:** QGIS 4.2 LTR · GDAL/OGR (ogr2ogr, ogrinfo) · GeoPackage · Git
**Question:** Which Berlin neighbourhoods have the poorest walking access to green space, relative to how many people live there?

## Data
| Dataset | Source | Licence |
|---|---|---|
| Neighbourhood boundaries (96 Ortsteile) | ALKIS Berlin via WFS (gdi.berlin.de) | dl-de/zero-2-0 |
| Population, 100 m grid (Zensus 2022) | Statistisches Bundesamt (Destatis) | dl-de/by-2-0 |
| Locator basemap | © OpenStreetMap contributors | ODbL |

## Work completed
1. Loaded Ortsteile from an OGC WFS and stored them in a GeoPackage (EPSG:25833).
2. Ingested the nationwide 100 m census CSV with ogr2ogr: assigned EPSG:3035, spatially pre-filtered to a Berlin bounding box (83,322 points).
3. Trimmed to Berlin with Extract by location (40,662 populated cells).
4. Built 100 m cells in their native CRS (EPSG:3035), then reprojected to EPSG:25833.
5. Validated: grid total 3,595,260 residents vs. official ~3.6 M (>99.9 %).
6. Produced a print layout: Jenks-classified population map, Germany locator inset with overview frame, UTM 10 km grid, legend, scale bar, true-north arrow, credits, neatline. Exported to PDF and 300 dpi PNG.

## Skills practised
- **CRS & geodesy:** projected vs geographic/compound CRS; assign vs transform; native-grid geometry; meridian convergence (true vs grid north); per-frame CRS in layouts
- **Data acquisition:** WFS, XYZ tiles, open-data licensing and attribution, troubleshooting unreachable services
- **Data processing:** GeoPackage, GDAL CLI (`-spat`, `/vsizip/`, CSV open options), Extract by location vs Clip, reprojection, data validation
- **Cartography:** graduated symbology (Natural Breaks), map themes, print layouts, locator/overview maps, coordinate grids, PDF/PNG export

## CV-ready bullets
- Built a reproducible GIS workflow in QGIS 4.2 and GDAL combining the Zensus 2022 100 m population grid (40,662 cells) with ALKIS boundaries retrieved via OGC WFS.
- Managed multi-CRS data (EPSG:3035 → EPSG:25833), preserving official grid geometry, and validated results against official census totals (>99.9 % agreement).
- Produced publication-quality cartography: Jenks classification, map themes, locator inset with overview frame, UTM coordinate grid and licence-compliant attribution.
- Automated data ingestion with ogr2ogr (spatial filtering, virtual file systems) and version-controlled the project with Git.

## Outputs
- `output/p1_berlin_population.pdf`, `output/p1_berlin_population.png`
- `data/p1.gpkg`: ortsteile, pop_points_3035, pop_grid_100m
- `p1.qgz`: QGIS project (styles, map themes, layout)

## Still to do
- [ ] Load green spaces (Geoportal Berlin / OSM via QuickOSM); validate and fix geometries
- [ ] Buffer vs network-based walking access (service areas)
- [ ] Spatial join: population within / outside access per neighbourhood
- [ ] Access-equity map and Atlas export per neighbourhood
