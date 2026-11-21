-- D5: display view for QGIS (clipped hexes + counts + Gi* class) and the strongest hot spots
CREATE VIEW accidents.hex250_hotspots AS
SELECT h.hex_id, h.n_bike, g.gi_z, g.p_norm_2s, g.p_sim, g.gi_class, h.share_in_berlin,
       h.geom_clip AS geom
FROM accidents.hex250 h JOIN accidents.hex250_gistar g USING (hex_id);

SELECT gi_class, count(*) AS hexes, sum(n_bike) AS bike_accidents,
       round(100.0 * sum(n_bike) / (SELECT count(*) FROM accidents.bike), 1) AS pct_of_bike_accidents
FROM accidents.hex250_hotspots GROUP BY 1 ORDER BY 1;
-- top 10 hexes by Gi* z, with the Ortsteil at the hex centre
SELECT g.hex_id, round(g.gi_z::numeric, 1) AS z, h.n_bike, o.ortsteil, o.bezirk
FROM accidents.hex250_gistar g JOIN accidents.hex250 h USING (hex_id)
LEFT JOIN accidents.ortsteile o ON ST_Intersects(o.geom, ST_Centroid(h.geom))
ORDER BY g.gi_z DESC LIMIT 10;
-- hot spots (>= 95 %) by Bezirk
SELECT o.bezirk, count(*) AS hot_hexes
FROM accidents.hex250_gistar g JOIN accidents.hex250 h USING (hex_id)
JOIN accidents.ortsteile o ON ST_Intersects(o.geom, ST_Centroid(h.geom))
WHERE g.gi_z >= 1.96 GROUP BY 1 ORDER BY 2 DESC;
