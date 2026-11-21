-- C1: roads from OSM staging (accidents.osm_lines_src, loaded by ogr2ogr from berlin-261102.osm.pbf, EPSG:25833)
-- Brief list + shared foot/cycle paths with bicycle=designated|yes (user decision 2026-11-12).
CREATE TABLE accidents.roads AS
SELECT fid AS road_id,
       osm_id,
       highway,
       name,
       substring(other_tags from '"bicycle"=>"([^"]*)"')  AS bicycle,
       substring(other_tags from '"service"=>"([^"]*)"')  AS service,
       substring(other_tags from '"maxspeed"=>"([^"]*)"') AS maxspeed,
       CASE
         WHEN highway IN ('motorway','motorway_link','trunk','trunk_link')        THEN '1 motorway/trunk'
         WHEN highway IN ('primary','primary_link','secondary','secondary_link') THEN '2 primary/secondary'
         WHEN highway IN ('tertiary','tertiary_link','unclassified')             THEN '3 tertiary/unclassified'
         WHEN highway IN ('residential','living_street')                         THEN '4 residential'
         WHEN highway = 'service'                                                 THEN '5 service'
         WHEN highway = 'cycleway'                                                THEN '6 cycleway'
         ELSE '7 shared path (bicycle designated/yes)'
       END AS road_class,
       ST_Length(geom) AS length_m,
       geom::geometry(LineString, 25833) AS geom
FROM accidents.osm_lines_src
WHERE geom IS NOT NULL AND ST_Length(geom) > 0;
ALTER TABLE accidents.roads ADD PRIMARY KEY (road_id);
CREATE INDEX roads_geom_gix ON accidents.roads USING gist (geom);
ANALYZE accidents.roads;

-- checks
SELECT road_class, count(*) AS n, round((sum(length_m)/1000)::numeric, 0) AS km
FROM accidents.roads GROUP BY ROLLUP (road_class) ORDER BY 1;
SELECT bicycle, count(*) FROM accidents.roads WHERE road_class LIKE '7%' GROUP BY 1 ORDER BY 2 DESC;
SELECT service, count(*), round((sum(length_m)/1000)::numeric) km FROM accidents.roads WHERE highway='service' GROUP BY 1 ORDER BY 2 DESC LIMIT 6;
SELECT count(*) FILTER (WHERE NOT ST_IsValid(geom)) AS invalid,
       count(*) FILTER (WHERE name IS NULL) AS no_name,
       round(min(length_m)::numeric,2) AS min_len, round(max(length_m)::numeric) AS max_len
FROM accidents.roads;
-- share outside Berlin (Geofabrik extract edges)
SELECT round((100.0 * sum(r.length_m) FILTER (WHERE NOT ST_Intersects(r.geom, b.geom)) / sum(r.length_m))::numeric, 2) AS pct_len_outside
FROM accidents.roads r, accidents.berlin b;
