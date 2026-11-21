-- C4: bike accident statistics per road segment -> accidents.segment_stats (all segments, zeros included)
CREATE TABLE accidents.segment_stats AS
SELECT s.seg_id, s.road_id, s.osm_id, s.highway, s.road_class, s.name, s.service, s.length_m,
       count(b.id)::int                                         AS n_bike,
       count(b.id) FILTER (WHERE b.ukategorie IN (1, 2))::int   AS n_killed_serious,
       count(b.id) FILTER (WHERE b.ukategorie = 1)::int         AS n_killed,
       round((count(b.id) / (s.length_m / 1000.0))::numeric, 1) AS accidents_per_km,
       count(b.id) FILTER (WHERE b.ujahr = 2018)::int AS n_2018,
       count(b.id) FILTER (WHERE b.ujahr = 2019)::int AS n_2019,
       count(b.id) FILTER (WHERE b.ujahr = 2020)::int AS n_2020,
       count(b.id) FILTER (WHERE b.ujahr = 2021)::int AS n_2021,
       count(b.id) FILTER (WHERE b.ujahr = 2022)::int AS n_2022,
       count(b.id) FILTER (WHERE b.ujahr = 2023)::int AS n_2023,
       count(b.id) FILTER (WHERE b.ujahr = 2024)::int AS n_2024,
       count(b.id) FILTER (WHERE b.ujahr = 2025)::int AS n_2025,
       s.geom
FROM accidents.road_segments s
LEFT JOIN accidents.bike_snap b ON b.seg_id = s.seg_id
GROUP BY s.seg_id;
ALTER TABLE accidents.segment_stats ADD PRIMARY KEY (seg_id);
CREATE INDEX segment_stats_geom_gix ON accidents.segment_stats USING gist (geom);
CREATE INDEX segment_stats_nbike_idx ON accidents.segment_stats (n_bike DESC);
ANALYZE accidents.segment_stats;

-- checks
SELECT sum(n_bike) AS sum_n_bike, (SELECT count(seg_id) FROM accidents.bike_snap) AS matched,
       sum(n_2018+n_2019+n_2020+n_2021+n_2022+n_2023+n_2024+n_2025) AS sum_years,
       sum(n_killed_serious) AS killed_serious, sum(n_killed) AS killed,
       count(*) FILTER (WHERE n_bike > 0) AS segs_with_accident,
       round(100.0 * count(*) FILTER (WHERE n_bike > 0) / count(*), 1) AS pct_segs_with_accident
FROM accidents.segment_stats;
SELECT n_bike, count(*) AS segments FROM accidents.segment_stats WHERE n_bike > 0
GROUP BY 1 ORDER BY 1 DESC LIMIT 12;
-- top by count, and the short-segment problem in accidents_per_km
SELECT seg_id, name, road_class, round(length_m::numeric,1) len_m, n_bike, n_killed_serious, accidents_per_km
FROM accidents.segment_stats ORDER BY n_bike DESC, seg_id LIMIT 10;
SELECT seg_id, name, road_class, round(length_m::numeric,2) len_m, n_bike, accidents_per_km
FROM accidents.segment_stats WHERE n_bike > 0 ORDER BY accidents_per_km DESC LIMIT 5;
