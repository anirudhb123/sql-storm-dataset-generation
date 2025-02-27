SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.id < 2013258 AND ct.kind IN ('distributors', 'miscellaneous companies', 'special effects companies') AND t.phonetic_code IS NOT NULL AND mi.info < 'Duo Maxwell: Damn! What a dinky way to kill us all off.';