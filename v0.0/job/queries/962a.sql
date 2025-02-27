SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mc.company_type_id = 2 AND ct.id < 4 AND t.season_nr IN (1, 2006, 34, 53, 61, 63) AND mi.info > '$125,441,155 (USA) (30 July 2000)' AND ct.kind < 'special effects companies' AND it.id = 11;