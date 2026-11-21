-- A1: database setup (db p4 is created by the container via POSTGRES_DB)
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE SCHEMA IF NOT EXISTS accidents;
SELECT postgis_full_version();
SELECT current_database(), current_user, version();
