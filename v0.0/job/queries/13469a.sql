SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.series_years > '1964-1981' AND ct.id < 4 AND mi.movie_id < 1245097 AND mi.note > 'Stoffa Productions' AND t.phonetic_code > 'Q2565' AND t.production_year IN (1920, 1924, 1937, 1970, 1992, 2005, 2014, 2015);