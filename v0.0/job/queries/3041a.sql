SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.info_type_id > 4 AND ct.kind IN ('distributors', 'miscellaneous companies', 'production companies', 'special effects companies') AND mi.info < '$7,139 (USA) (7 September 2003) (1 screen)' AND ct.id = 2;