SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.series_years IS NOT NULL AND t.phonetic_code LIKE '%2%' AND ct.kind IN ('distributors', 'miscellaneous companies', 'production companies', 'special effects companies') AND mi.info_type_id IN (13, 95) AND mc.note < '(2011) (Turkey) (DVD)';