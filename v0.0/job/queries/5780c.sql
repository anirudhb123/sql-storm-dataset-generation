SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.imdb_index LIKE '%V%' AND mi.info_type_id IN (106, 110, 15, 42, 47, 64, 78, 8, 87, 93) AND mc.company_id < 134564 AND mc.company_type_id IN (1, 2);