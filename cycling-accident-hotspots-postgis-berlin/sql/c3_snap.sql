-- C3: snap each bike accident to the nearest road segment within 25 m (KNN in a LATERAL join)
CREATE TABLE accidents.bike_snap AS
SELECT a.id, a.ujahr, a.ukategorie, s.seg_id, s.dist_m,
       CASE WHEN s.seg_id IS NOT NULL THEN ST_ClosestPoint(s.geom, a.geom) END::geometry(Point, 25833) AS snap_geom
FROM accidents.bike a
LEFT JOIN LATERAL (
  SELECT r.seg_id, r.geom, ST_Distance(a.geom, r.geom) AS dist_m
  FROM accidents.road_segments r
  WHERE ST_DWithin(a.geom, r.geom, 25)
  ORDER BY a.geom <-> r.geom
  LIMIT 1
) s ON true;
ALTER TABLE accidents.bike_snap ADD PRIMARY KEY (id);
CREATE INDEX bike_snap_seg_idx ON accidents.bike_snap (seg_id);
CREATE INDEX bike_snap_geom_gix ON accidents.bike_snap USING gist (snap_geom);
ANALYZE accidents.bike_snap;

-- checks
SELECT count(*) AS bike_total, count(seg_id) AS matched, count(*) - count(seg_id) AS unmatched,
       round(100.0 * (count(*) - count(seg_id)) / count(*), 2) AS pct_unmatched
FROM accidents.bike_snap;
SELECT round(percentile_cont(0.5) WITHIN GROUP (ORDER BY dist_m)::numeric, 2) AS p50_m,
       round(percentile_cont(0.9) WITHIN GROUP (ORDER BY dist_m)::numeric, 2) AS p90_m,
       round(percentile_cont(0.99) WITHIN GROUP (ORDER BY dist_m)::numeric, 2) AS p99_m,
       count(*) FILTER (WHERE dist_m < 0.01) AS exactly_on_line
FROM accidents.bike_snap WHERE seg_id IS NOT NULL;
SELECT r.road_class, count(*) AS n, round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct
FROM accidents.bike_snap b JOIN accidents.road_segments r USING (seg_id) GROUP BY 1 ORDER BY 1;
SELECT r.service, count(*) FROM accidents.bike_snap b JOIN accidents.road_segments r USING (seg_id)
WHERE r.highway = 'service' GROUP BY 1 ORDER BY 2 DESC LIMIT 5;
-- unmatched: how far to the nearest segment at all
SELECT width_bucket(d, array[25, 50, 100, 250]) AS bucket, count(*)
FROM (SELECT b.id, (SELECT ST_Distance(a.geom, r.geom) FROM accidents.road_segments r ORDER BY a.geom <-> r.geom LIMIT 1) AS d
      FROM accidents.bike_snap b JOIN accidents.accidents a USING (id) WHERE b.seg_id IS NULL) u
GROUP BY 1 ORDER BY 1;
