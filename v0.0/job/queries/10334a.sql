SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.phonetic_code IN ('B6241', 'D6324', 'E2415', 'E4145', 'J1414', 'J5253', 'L4216', 'O1452', 'P231', 'U641');