SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.note > '(Festival international du film de Boulogne-Billancourt)' AND t.phonetic_code IN ('D1365', 'K4341', 'L2353', 'O512', 'Z5412');