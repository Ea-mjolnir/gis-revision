-- D2: 250 m hexagon grid (centre spacing 250 m = QGIS native:creategrid HSPACING 250; edge 250/sqrt(3) = 144.34 m, area 54,127 m2)
-- Full hexagons intersecting Berlin are the analysis units; geom_clip is for display only.
CREATE TABLE accidents.hex250 AS
SELECT row_number() OVER (ORDER BY h.i, h.j)::int AS hex_id, h.i, h.j,
       h.geom::geometry(Polygon, 25833) AS geom,
       ST_Multi(ST_CollectionExtract(ST_Intersection(h.geom, b.geom), 3))::geometry(MultiPolygon, 25833) AS geom_clip,
       ST_Area(ST_Intersection(h.geom, b.geom)) / ST_Area(h.geom) AS share_in_berlin
FROM accidents.berlin b,
     LATERAL ST_HexagonGrid(250 / sqrt(3), b.geom) AS h
WHERE ST_Intersects(h.geom, b.geom);
ALTER TABLE accidents.hex250 ADD PRIMARY KEY (hex_id);
CREATE INDEX hex250_geom_gix ON accidents.hex250 USING gist (geom);
ANALYZE accidents.hex250;

-- each bike point in exactly one hex (points on a shared edge go to the lowest hex_id)
CREATE TABLE accidents.bike_hex AS
SELECT DISTINCT ON (a.id) a.id, h.hex_id
FROM accidents.bike a JOIN accidents.hex250 h ON ST_Intersects(a.geom, h.geom)
ORDER BY a.id, h.hex_id;
ALTER TABLE accidents.bike_hex ADD PRIMARY KEY (id);
ALTER TABLE accidents.bike_hex ADD CONSTRAINT bike_hex_accident_fk FOREIGN KEY (id) REFERENCES accidents.accidents (id);
ALTER TABLE accidents.bike_hex ADD CONSTRAINT bike_hex_hex_fk FOREIGN KEY (hex_id) REFERENCES accidents.hex250 (hex_id);

ALTER TABLE accidents.hex250 ADD COLUMN n_bike int;
UPDATE accidents.hex250 h SET n_bike = COALESCE(c.n, 0)
FROM (SELECT hx.hex_id, count(bh.id) AS n FROM accidents.hex250 hx LEFT JOIN accidents.bike_hex bh USING (hex_id) GROUP BY hx.hex_id) c
WHERE c.hex_id = h.hex_id;

-- neighbours by centroid distance (centre spacing 250 m; tolerance 1 %) = queen contiguity on a hex grid
CREATE TABLE accidents.hex250_nb AS
SELECT a.hex_id, b.hex_id AS nb_id
FROM accidents.hex250 a JOIN accidents.hex250 b
  ON a.hex_id <> b.hex_id AND ST_DWithin(ST_Centroid(a.geom), ST_Centroid(b.geom), 252.5);
ALTER TABLE accidents.hex250_nb ADD PRIMARY KEY (hex_id, nb_id);

-- checks
SELECT count(*) AS n_hex, round(min(ST_Area(geom))::numeric) AS area_min, round(max(ST_Area(geom))::numeric) AS area_max,
       count(*) FILTER (WHERE share_in_berlin < 0.999) AS edge_hexes,
       round((sum(ST_Area(geom_clip)) / 1e6)::numeric, 1) AS clipped_km2
FROM accidents.hex250;
SELECT sum(n_bike) AS sum_n_bike, (SELECT count(*) FROM accidents.bike) AS bike_total,
       (SELECT count(*) FROM accidents.bike a WHERE NOT EXISTS (SELECT 1 FROM accidents.bike_hex b WHERE b.id = a.id)) AS not_in_any_hex,
       count(*) FILTER (WHERE n_bike = 0) AS hex_zero, round(avg(n_bike)::numeric, 2) AS mean, max(n_bike) AS max
FROM accidents.hex250;
SELECT n_nb, count(*) FROM (SELECT h.hex_id, count(n.nb_id) AS n_nb FROM accidents.hex250 h LEFT JOIN accidents.hex250_nb n USING (hex_id) GROUP BY 1) x GROUP BY 1 ORDER BY 1;
