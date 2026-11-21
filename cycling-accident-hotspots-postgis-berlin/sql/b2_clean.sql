-- B3/B4: Ortsteile with Bezirk, Berlin boundary, accidents inside Berlin, bike view
CREATE TABLE accidents.ortsteile AS
SELECT fid AS ot_id, sch AS ot_key, nam AS ortsteil, substr(sch, 7, 2) AS bez_code,
       CASE substr(sch, 7, 2)
         WHEN '01' THEN 'Mitte' WHEN '02' THEN 'Friedrichshain-Kreuzberg' WHEN '03' THEN 'Pankow'
         WHEN '04' THEN 'Charlottenburg-Wilmersdorf' WHEN '05' THEN 'Spandau' WHEN '06' THEN 'Steglitz-Zehlendorf'
         WHEN '07' THEN 'Tempelhof-Schöneberg' WHEN '08' THEN 'Neukölln' WHEN '09' THEN 'Treptow-Köpenick'
         WHEN '10' THEN 'Marzahn-Hellersdorf' WHEN '11' THEN 'Lichtenberg' WHEN '12' THEN 'Reinickendorf' END AS bezirk,
       ST_Area(geom) / 1e6 AS area_km2,
       geom::geometry(MultiPolygon, 25833) AS geom
FROM accidents.ortsteile_src;
ALTER TABLE accidents.ortsteile ADD PRIMARY KEY (ot_id);
CREATE INDEX ortsteile_geom_gix ON accidents.ortsteile USING gist (geom);

CREATE TABLE accidents.berlin AS
SELECT 1 AS id, ST_Multi(ST_Union(geom))::geometry(MultiPolygon, 25833) AS geom FROM accidents.ortsteile;
CREATE INDEX berlin_geom_gix ON accidents.berlin USING gist (geom);

-- accidents inside Berlin, with Ortsteil/Bezirk (DISTINCT ON handles points exactly on a shared Ortsteil border)
CREATE TABLE accidents.accidents AS
SELECT DISTINCT ON (r.id) r.*, o.ot_id, o.ortsteil, o.bez_code, o.bezirk
FROM accidents.raw r
JOIN accidents.ortsteile o ON ST_Intersects(r.geom, o.geom)
ORDER BY r.id, o.ot_id;
ALTER TABLE accidents.accidents ADD PRIMARY KEY (id);
ALTER TABLE accidents.accidents ALTER COLUMN geom TYPE geometry(Point, 25833);
CREATE INDEX accidents_geom_gix ON accidents.accidents USING gist (geom);
ANALYZE accidents.accidents;

CREATE VIEW accidents.bike AS SELECT * FROM accidents.accidents WHERE istrad = 1;

-- checks
SELECT bez_code, count(*) FROM accidents.ortsteile GROUP BY 1 ORDER BY 1;
SELECT (SELECT count(*) FROM accidents.raw) AS raw_n,
       (SELECT count(*) FROM accidents.accidents) AS inside_n,
       (SELECT count(*) FROM accidents.raw) - (SELECT count(*) FROM accidents.accidents) AS dropped,
       (SELECT count(*) FROM accidents.raw r, accidents.berlin b WHERE NOT ST_Within(r.geom, b.geom)) AS not_strictly_within;
SELECT r.id, r.ujahr, r.istrad, round(ST_Distance(r.geom, b.geom)::numeric, 1) AS dist_outside_m
FROM accidents.raw r, accidents.berlin b
WHERE NOT ST_Intersects(r.geom, b.geom) ORDER BY 4 DESC;
SELECT ujahr, count(*) n, sum(istrad) n_bike, round(100.0*sum(istrad)/count(*),1) pct_bike
FROM accidents.accidents GROUP BY ROLLUP (ujahr) ORDER BY 1;
