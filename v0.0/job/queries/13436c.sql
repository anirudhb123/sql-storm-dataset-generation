SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND ct.kind LIKE '%tribu%' AND t.production_year IN (1905, 1911, 1914, 1924, 1933, 1956, 1996, 2015) AND it.id > 22 AND mi.movie_id > 1723278 AND mc.note IS NOT NULL AND mi.info_type_id > 1;