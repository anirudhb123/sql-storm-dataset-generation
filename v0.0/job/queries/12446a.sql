SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.info_type_id IN (104, 107, 3, 40, 77, 84, 93, 95) AND it.info > 'LD close captions-teletext-ld-g' AND t.phonetic_code IN ('A65', 'D1434', 'G341', 'I326', 'U4351');