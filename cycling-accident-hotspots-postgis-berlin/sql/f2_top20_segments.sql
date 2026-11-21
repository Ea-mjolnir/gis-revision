-- F2: top 20 road segments by bike accidents per km (2018-2025), names from OSM.
-- Rule: only segments >= 50 m (shorter stubs at junctions give meaningless per-km values, e.g. 1.9 m -> 3,101/km).
CREATE TABLE accidents.top20_segments AS
SELECT row_number() OVER (ORDER BY s.accidents_per_km DESC, s.n_bike DESC, s.seg_id)::int AS rank,
       s.seg_id, COALESCE(s.name, '(unnamed ' || s.highway || ')') AS street, s.road_class,
       o.ortsteil, o.bezirk, round(s.length_m::numeric, 1) AS length_m,
       s.n_bike, s.n_killed_serious, s.accidents_per_km,
       s.n_2018, s.n_2019, s.n_2020, s.n_2021, s.n_2022, s.n_2023, s.n_2024, s.n_2025, s.geom
FROM accidents.segment_stats s
LEFT JOIN accidents.ortsteile o ON ST_Intersects(o.geom, ST_LineInterpolatePoint(s.geom, 0.5))
WHERE s.length_m >= 50 AND s.n_bike > 0
ORDER BY s.accidents_per_km DESC, s.n_bike DESC, s.seg_id
LIMIT 20;
ALTER TABLE accidents.top20_segments ADD PRIMARY KEY (rank);
ALTER TABLE accidents.top20_segments ADD CONSTRAINT top20_seg_fk FOREIGN KEY (seg_id) REFERENCES accidents.road_segments (seg_id);

\copy (SELECT rank, seg_id, street, road_class, ortsteil, bezirk, length_m, n_bike, n_killed_serious, accidents_per_km, n_2018, n_2019, n_2020, n_2021, n_2022, n_2023, n_2024, n_2025 FROM accidents.top20_segments ORDER BY rank) TO 'output/f2_top20_segments.csv' WITH (FORMAT csv, HEADER)

SELECT rank, street, ortsteil, length_m, n_bike, n_killed_serious AS ksi, accidents_per_km FROM accidents.top20_segments ORDER BY rank;
-- effect of the 50 m rule: how many of the unfiltered top 20 are < 50 m?
SELECT count(*) FILTER (WHERE length_m < 50) AS short_in_unfiltered_top20, round(min(length_m)::numeric, 1) AS shortest_m
FROM (SELECT length_m FROM accidents.segment_stats WHERE n_bike > 0 ORDER BY accidents_per_km DESC LIMIT 20) t;
-- how many top-20 segments lie in a Gi* hot hex (>= 95 %)?
SELECT count(DISTINCT t.rank) AS top20_in_hot_hex
FROM accidents.top20_segments t
JOIN accidents.hex250 h ON ST_Intersects(h.geom, ST_LineInterpolatePoint(t.geom, 0.5))
JOIN accidents.hex250_gistar g USING (hex_id) WHERE g.gi_z >= 1.96;
