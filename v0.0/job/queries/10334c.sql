SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.info < 'Rediscovered After Over 60 Years!' AND t.season_nr IN (17, 1984, 1987, 1997, 2013, 32, 46, 62, 71) AND mc.company_type_id IN (1) AND t.production_year < 2012;