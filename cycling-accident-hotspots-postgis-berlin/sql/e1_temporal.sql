-- E1/E2/E4: temporal analysis of bike accidents (Berlin, 2018-2025). Views + CSV exports to output/.
-- E1 city-wide trend, with all injury accidents for context and bike share
CREATE VIEW accidents.e1_trend_city AS
SELECT ujahr AS year, count(*) FILTER (WHERE istrad = 1) AS bike, count(*) AS all_accidents,
       round(100.0 * count(*) FILTER (WHERE istrad = 1) / count(*), 1) AS bike_share_pct
FROM accidents.accidents GROUP BY ujahr ORDER BY ujahr;
-- E1 per Bezirk (all 12 x 8 combinations, zeros kept)
CREATE VIEW accidents.e1_trend_bezirk AS
SELECT b.bezirk, y.year, count(a.id) AS bike
FROM (SELECT DISTINCT bezirk FROM accidents.ortsteile) b
CROSS JOIN generate_series(2018, 2025) AS y(year)
LEFT JOIN accidents.bike a ON a.bezirk = b.bezirk AND a.ujahr = y.year
GROUP BY b.bezirk, y.year ORDER BY 1, 2;
-- E2 hour x weekday (weekday 1 = Sunday in Unfallatlas; wd_order 1 = Monday for display)
CREATE VIEW accidents.e2_hour_weekday AS
SELECT uwochentag AS weekday_code,
       CASE uwochentag WHEN 1 THEN 7 ELSE uwochentag - 1 END AS wd_order,
       (ARRAY['Sun','Mon','Tue','Wed','Thu','Fri','Sat'])[uwochentag] AS weekday,
       ustunde AS hour, count(*) AS bike
FROM accidents.bike GROUP BY 1, 2, 3, 4 ORDER BY 2, 4;
-- E2 light conditions per year
CREATE VIEW accidents.e2_light AS
SELECT ujahr AS year,
       (ARRAY['daylight','twilight','darkness'])[ulichtverh + 1] AS light, count(*) AS bike,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY ujahr), 1) AS pct
FROM accidents.bike GROUP BY 1, 2 ORDER BY 1, 2;
-- E4 severity per year
CREATE VIEW accidents.e4_severity AS
SELECT ujahr AS year, count(*) AS bike,
       count(*) FILTER (WHERE ukategorie = 1) AS killed,
       count(*) FILTER (WHERE ukategorie = 2) AS seriously_injured,
       count(*) FILTER (WHERE ukategorie IN (1, 2)) AS killed_or_serious,
       round(100.0 * count(*) FILTER (WHERE ukategorie IN (1, 2)) / count(*), 1) AS ksi_pct
FROM accidents.bike GROUP BY 1 ORDER BY 1;

\copy (SELECT * FROM accidents.e1_trend_city) TO 'output/e1_trend_city.csv' WITH (FORMAT csv, HEADER)
\copy (SELECT * FROM accidents.e1_trend_bezirk) TO 'output/e1_trend_bezirk.csv' WITH (FORMAT csv, HEADER)
\copy (SELECT * FROM accidents.e2_hour_weekday) TO 'output/e2_hour_weekday.csv' WITH (FORMAT csv, HEADER)
\copy (SELECT * FROM accidents.e2_light) TO 'output/e2_light.csv' WITH (FORMAT csv, HEADER)
\copy (SELECT * FROM accidents.e4_severity) TO 'output/e4_severity.csv' WITH (FORMAT csv, HEADER)

-- checks / headline numbers
SELECT * FROM accidents.e1_trend_city;
SELECT sum(bike) AS sum_bezirk_trend FROM accidents.e1_trend_bezirk;
SELECT bezirk, sum(bike) FILTER (WHERE year = 2018) AS y2018, sum(bike) FILTER (WHERE year = 2025) AS y2025,
       round(100.0 * (sum(bike) FILTER (WHERE year = 2025) - sum(bike) FILTER (WHERE year = 2018)) / sum(bike) FILTER (WHERE year = 2018), 1) AS chg_18_25_pct,
       round(100.0 * (sum(bike) FILTER (WHERE year IN (2024, 2025)) - sum(bike) FILTER (WHERE year IN (2018, 2019))) / sum(bike) FILTER (WHERE year IN (2018, 2019)), 1) AS chg_1819_2425_pct
FROM accidents.e1_trend_bezirk GROUP BY 1 ORDER BY 5;
SELECT * FROM accidents.e4_severity;
SELECT light, sum(bike) AS n, round(100.0 * sum(bike) / sum(sum(bike)) OVER (), 1) AS pct FROM accidents.e2_light GROUP BY 1 ORDER BY 2 DESC;
SELECT weekday, hour, bike FROM accidents.e2_hour_weekday ORDER BY bike DESC LIMIT 5;
SELECT CASE WHEN wd_order <= 5 THEN 'Mon-Fri' ELSE 'Sat-Sun' END AS days, sum(bike) AS n FROM accidents.e2_hour_weekday GROUP BY 1;
