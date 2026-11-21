-- F1: bike accidents per Ortsteil - absolute, per 10,000 residents, per km of road (all rates per year, 2018-2025 = 8 years)
-- Residents = Zensus 2022 100 m grid (from P1), cell assigned by point on surface. Road km = road_segments by midpoint.
-- NOTE: residents are not exposure (no cycling volume data); per-resident rates are inflated where many non-residents cycle (centre).
CREATE TABLE accidents.ortsteil_stats AS
WITH pop AS (
  SELECT o.ot_id, sum(p.einwohner) AS residents
  FROM accidents.pop_grid_src p JOIN accidents.ortsteile o ON ST_Intersects(o.geom, ST_PointOnSurface(p.geom))
  GROUP BY o.ot_id
), road AS (
  SELECT o.ot_id, sum(s.length_m) / 1000 AS road_km_all,
         sum(s.length_m) FILTER (WHERE s.highway <> 'service') / 1000 AS road_km_no_service
  FROM accidents.road_segments s JOIN accidents.ortsteile o ON ST_Intersects(o.geom, ST_LineInterpolatePoint(s.geom, 0.5))
  GROUP BY o.ot_id
), acc AS (
  SELECT ot_id, count(*) AS n_bike, count(*) FILTER (WHERE ukategorie IN (1, 2)) AS n_ksi
  FROM accidents.bike GROUP BY ot_id
)
SELECT o.ot_id, o.ortsteil, o.bezirk, round(o.area_km2::numeric, 2) AS area_km2,
       COALESCE(p.residents, 0) AS residents,
       round(r.road_km_all::numeric, 1) AS road_km_all, round(r.road_km_no_service::numeric, 1) AS road_km_no_service,
       COALESCE(a.n_bike, 0) AS n_bike, COALESCE(a.n_ksi, 0) AS n_ksi,
       round((COALESCE(a.n_bike, 0) / 8.0)::numeric, 1) AS bike_per_year,
       round((COALESCE(a.n_bike, 0) / 8.0 / NULLIF(p.residents, 0) * 10000)::numeric, 2) AS per_10k_res_year,
       round((COALESCE(a.n_bike, 0) / 8.0 / NULLIF(r.road_km_all, 0))::numeric, 3) AS per_km_all_year,
       round((COALESCE(a.n_bike, 0) / 8.0 / NULLIF(r.road_km_no_service, 0))::numeric, 3) AS per_km_noservice_year,
       (COALESCE(p.residents, 0) < 5000) AS small_population,
       o.geom
FROM accidents.ortsteile o
LEFT JOIN pop p USING (ot_id) LEFT JOIN road r USING (ot_id) LEFT JOIN acc a USING (ot_id);
ALTER TABLE accidents.ortsteil_stats ADD PRIMARY KEY (ot_id);
ALTER TABLE accidents.ortsteil_stats ADD CONSTRAINT ortsteil_stats_ot_fk FOREIGN KEY (ot_id) REFERENCES accidents.ortsteile (ot_id);
CREATE INDEX ortsteil_stats_geom_gix ON accidents.ortsteil_stats USING gist (geom);

\copy (SELECT ot_id, ortsteil, bezirk, area_km2, residents, road_km_all, road_km_no_service, n_bike, n_ksi, bike_per_year, per_10k_res_year, per_km_all_year, per_km_noservice_year, small_population FROM accidents.ortsteil_stats ORDER BY n_bike DESC) TO 'output/f1_ortsteil_stats.csv' WITH (FORMAT csv, HEADER)

-- checks: totals must match
SELECT sum(residents) AS residents, (SELECT sum(einwohner) FROM accidents.pop_grid_src) AS grid_residents,
       sum(n_bike) AS n_bike, round(sum(road_km_all)) AS road_km_all, round(sum(road_km_no_service)) AS road_km_no_service,
       count(*) FILTER (WHERE small_population) AS small_pop_ortsteile
FROM accidents.ortsteil_stats;
-- top 10 by each measure
SELECT 'absolute' AS measure, ortsteil, bezirk, n_bike AS value FROM accidents.ortsteil_stats ORDER BY n_bike DESC LIMIT 10;
SELECT 'per 10k residents/yr' AS measure, ortsteil, bezirk, residents, per_10k_res_year AS value FROM accidents.ortsteil_stats ORDER BY per_10k_res_year DESC NULLS LAST LIMIT 10;
SELECT 'per road km/yr (no service)' AS measure, ortsteil, bezirk, per_km_noservice_year AS value, per_km_all_year FROM accidents.ortsteil_stats ORDER BY per_km_noservice_year DESC NULLS LAST LIMIT 10;
-- how much do the rankings agree? (Spearman = Pearson on ranks)
WITH r AS (SELECT rank() OVER (ORDER BY n_bike) ra, rank() OVER (ORDER BY per_10k_res_year) rp,
                  rank() OVER (ORDER BY per_km_noservice_year) rk, rank() OVER (ORDER BY per_km_all_year) rka
           FROM accidents.ortsteil_stats WHERE residents > 0)
SELECT round(corr(ra, rp)::numeric, 2) AS abs_vs_resident, round(corr(ra, rk)::numeric, 2) AS abs_vs_roadkm,
       round(corr(rp, rk)::numeric, 2) AS resident_vs_roadkm, round(corr(rk, rka)::numeric, 2) AS roadkm_noservice_vs_all FROM r;
SELECT ortsteil, residents, n_bike, per_10k_res_year FROM accidents.ortsteil_stats WHERE small_population ORDER BY residents;
