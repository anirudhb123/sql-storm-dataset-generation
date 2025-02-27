SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mc.note < '(1989) (West Germany) (TV) (subtitled)' AND t.series_years IN ('1951-1956', '1951-1957', '1963-1982', '1964-1986', '1970-1971', '1979-1992', '1982-2001', '1994-2003');