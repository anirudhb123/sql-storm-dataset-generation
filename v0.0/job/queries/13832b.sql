SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.imdb_index IN ('I', 'VII', 'XI', 'XIX', 'XV', 'XX', 'XXII', 'XXIV') AND t.id < 2276752 AND mi.note IS NOT NULL AND ct.id IN (1, 4) AND it.info < 'portrayed in' AND t.production_year = 1977;