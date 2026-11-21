-- C5: declare the ID links as foreign keys (the database then guarantees them; QGIS can discover relations)
-- Creating each key validates all existing rows.
ALTER TABLE accidents.accidents     ADD CONSTRAINT accidents_raw_fk       FOREIGN KEY (id)      REFERENCES accidents.raw (id);
ALTER TABLE accidents.accidents     ADD CONSTRAINT accidents_ortsteil_fk  FOREIGN KEY (ot_id)   REFERENCES accidents.ortsteile (ot_id);
ALTER TABLE accidents.bike_snap     ADD CONSTRAINT bike_snap_accident_fk  FOREIGN KEY (id)      REFERENCES accidents.accidents (id);
ALTER TABLE accidents.bike_snap     ADD CONSTRAINT bike_snap_segment_fk   FOREIGN KEY (seg_id)  REFERENCES accidents.road_segments (seg_id);
ALTER TABLE accidents.road_segments ADD CONSTRAINT road_segments_road_fk  FOREIGN KEY (road_id) REFERENCES accidents.roads (road_id);
ALTER TABLE accidents.segment_stats ADD CONSTRAINT segment_stats_seg_fk   FOREIGN KEY (seg_id)  REFERENCES accidents.road_segments (seg_id);
-- index the referencing column that has none yet (joins on Ortsteil)
CREATE INDEX accidents_ot_idx ON accidents.accidents (ot_id);

SELECT conrelid::regclass AS table_name, conname, pg_get_constraintdef(oid) AS definition
FROM pg_constraint WHERE contype = 'f' AND connamespace = 'accidents'::regnamespace ORDER BY 1, 2;
