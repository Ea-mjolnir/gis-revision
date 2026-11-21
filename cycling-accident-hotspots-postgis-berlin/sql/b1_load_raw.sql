-- B1/B2: load harmonised Berlin accidents (data/berlin_accidents_2018_2025.csv, from _work/b2_harmonise.py)
-- Run from the project folder: psql ... -f sql/b1_load_raw.sql
-- Geometry from WGS84 columns -> EPSG:25833. LINREFX/LINREFY are UTM zone 32N (EPSG:25832) and are NOT used.
CREATE TABLE accidents.raw (
  id                 integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  file_year          smallint NOT NULL,
  uidentstlae        text,
  uland              smallint NOT NULL,
  uregbez            smallint,
  ukreis             smallint,
  ugemeinde          smallint,
  ujahr              smallint NOT NULL,
  umonat             smallint NOT NULL,
  ustunde            smallint,
  uwochentag         smallint,
  ukategorie         smallint NOT NULL,
  uart               smallint,
  utyp1              smallint,
  ulichtverh         smallint,
  iststrassenzustand smallint,
  istrad             smallint NOT NULL,
  istpkw             smallint,
  istfuss            smallint,
  istkrad            smallint,
  istgkfz            smallint,
  istsonstige        smallint,
  plst               smallint,
  linrefx_utm32      double precision,
  linrefy_utm32      double precision,
  x_wgs84            double precision NOT NULL,
  y_wgs84            double precision NOT NULL
);
\copy accidents.raw (file_year,uidentstlae,uland,uregbez,ukreis,ugemeinde,ujahr,umonat,ustunde,uwochentag,ukategorie,uart,utyp1,ulichtverh,iststrassenzustand,istrad,istpkw,istfuss,istkrad,istgkfz,istsonstige,plst,linrefx_utm32,linrefy_utm32,x_wgs84,y_wgs84) FROM 'data/berlin_accidents_2018_2025.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, NULL '')

ALTER TABLE accidents.raw ADD COLUMN geom geometry(Point, 25833);
UPDATE accidents.raw SET geom = ST_Transform(ST_SetSRID(ST_MakePoint(x_wgs84, y_wgs84), 4326), 25833);
CREATE INDEX raw_geom_gix ON accidents.raw USING gist (geom);

-- check constraints (fail loudly if the data breaks the code lists)
ALTER TABLE accidents.raw
  ADD CONSTRAINT raw_uland_berlin CHECK (uland = 11),
  ADD CONSTRAINT raw_year_range   CHECK (ujahr BETWEEN 2018 AND 2025 AND ujahr = file_year),
  ADD CONSTRAINT raw_month        CHECK (umonat BETWEEN 1 AND 12),
  ADD CONSTRAINT raw_hour         CHECK (ustunde BETWEEN 0 AND 23),
  ADD CONSTRAINT raw_weekday      CHECK (uwochentag BETWEEN 1 AND 7),
  ADD CONSTRAINT raw_kategorie    CHECK (ukategorie IN (1, 2, 3)),
  ADD CONSTRAINT raw_istrad       CHECK (istrad IN (0, 1)),
  ADD CONSTRAINT raw_geom_notnull CHECK (geom IS NOT NULL);
ANALYZE accidents.raw;

-- checks
SELECT ujahr, count(*) AS n, sum(istrad) AS n_bike, round(100.0 * sum(istrad) / count(*), 1) AS pct_bike
FROM accidents.raw GROUP BY ROLLUP (ujahr) ORDER BY ujahr;
SELECT round(min(x_wgs84)::numeric,4) xmin, round(max(x_wgs84)::numeric,4) xmax, round(min(y_wgs84)::numeric,4) ymin, round(max(y_wgs84)::numeric,4) ymax FROM accidents.raw;
-- CRS trap demonstration: distance between our zone-33 point and the official zone-32 coordinates transformed to 25833
SELECT round(avg(ST_Distance(geom, ST_Transform(ST_SetSRID(ST_MakePoint(linrefx_utm32, linrefy_utm32), 25832), 25833)))::numeric, 2) AS mean_dist_m,
       round(max(ST_Distance(geom, ST_Transform(ST_SetSRID(ST_MakePoint(linrefx_utm32, linrefy_utm32), 25832), 25833)))::numeric, 2) AS max_dist_m,
       round(avg(ST_Distance(geom, ST_SetSRID(ST_MakePoint(linrefx_utm32, linrefy_utm32), 25833)))::numeric, 0) AS mean_dist_if_misread_as_zone33_m
FROM accidents.raw WHERE linrefx_utm32 IS NOT NULL;
