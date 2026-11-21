-- C2: clip roads to Berlin and split into equal pieces of at most 100 m -> accidents.road_segments
-- Lines fully inside Berlin are used as they are; only boundary-crossing lines are intersected.
CREATE TABLE accidents.road_segments AS
WITH clipped AS (
  SELECT r.road_id, r.osm_id, r.highway, r.road_class, r.name, r.service, r.bicycle, r.maxspeed,
         CASE WHEN ST_Within(r.geom, b.geom) THEN r.geom
              ELSE ST_CollectionExtract(ST_Intersection(r.geom, b.geom), 2) END AS geom
  FROM accidents.roads r
  JOIN accidents.berlin b ON ST_Intersects(r.geom, b.geom)
), parts AS (
  SELECT c.road_id, c.osm_id, c.highway, c.road_class, c.name, c.service, c.bicycle, c.maxspeed,
         d.path[1] AS part_no, d.geom
  FROM clipped c, ST_Dump(c.geom) d
  WHERE ST_Length(d.geom) > 0.01
), pieces AS (
  SELECT p.*, ceil(ST_Length(p.geom) / 100.0)::int AS n_pieces FROM parts p
)
SELECT row_number() OVER (ORDER BY road_id, part_no, i)::int AS seg_id,
       road_id, osm_id, highway, road_class, name, service, bicycle, maxspeed,
       COALESCE(part_no, 1) AS part_no, i AS piece_no, n_pieces,
       ST_LineSubstring(geom, (i - 1)::float8 / n_pieces, i::float8 / n_pieces)::geometry(LineString, 25833) AS geom
FROM pieces, generate_series(1, n_pieces) AS i;

ALTER TABLE accidents.road_segments ADD COLUMN length_m double precision;
UPDATE accidents.road_segments SET length_m = ST_Length(geom);
ALTER TABLE accidents.road_segments ADD PRIMARY KEY (seg_id);
CREATE INDEX road_segments_geom_gix ON accidents.road_segments USING gist (geom);
CREATE INDEX road_segments_road_idx ON accidents.road_segments (road_id);
ANALYZE accidents.road_segments;

-- checks
SELECT count(*) AS n_segments, count(DISTINCT road_id) AS n_roads,
       round(min(length_m)::numeric, 2) AS min_m, round(avg(length_m)::numeric, 1) AS mean_m,
       round(max(length_m)::numeric, 3) AS max_m, count(*) FILTER (WHERE length_m > 100.001) AS over_100m,
       round((sum(length_m) / 1000)::numeric, 0) AS total_km
FROM accidents.road_segments;
SELECT road_class, count(*) n, round((sum(length_m)/1000)::numeric) km FROM accidents.road_segments GROUP BY ROLLUP (road_class) ORDER BY 1;
-- length conservation: roads inside Berlin vs segments
SELECT round((sum(ST_Length(ST_Intersection(r.geom, b.geom)))/1000)::numeric, 1) AS roads_inside_km
FROM accidents.roads r JOIN accidents.berlin b ON ST_Intersects(r.geom, b.geom);
SELECT count(*) FILTER (WHERE NOT ST_IsValid(geom)) AS invalid, count(*) FILTER (WHERE ST_IsEmpty(geom)) AS empty FROM accidents.road_segments;
