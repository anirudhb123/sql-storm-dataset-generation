SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.movie_id < 1115286 AND mi.info_type_id > 61 AND mc.company_type_id > 1 AND mi.note IS NOT NULL AND t.production_year > 1914;