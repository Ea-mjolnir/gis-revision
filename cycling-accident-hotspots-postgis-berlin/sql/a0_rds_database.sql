-- A0 (RDS): replace the initial database p4 by berlin_road_safety. Run connected to db "postgres".
CREATE DATABASE berlin_road_safety;
COMMENT ON DATABASE berlin_road_safety IS 'Project 4: cycling accident hotspots Berlin (Unfallatlas 2018-2025)';
DROP DATABASE p4;
SELECT datname FROM pg_database WHERE NOT datistemplate ORDER BY 1;
