SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mc.id > 789627 AND t.md5sum < '5b3b9e7a449cb6208f75cf2ae055e19b' AND t.phonetic_code IS NOT NULL AND mc.company_id IN (106391, 11603, 138731, 15058, 175291, 40402, 6352, 69410, 85489);