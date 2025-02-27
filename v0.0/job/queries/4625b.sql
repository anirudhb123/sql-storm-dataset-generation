SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.phonetic_code IN ('B263', 'E5165', 'F1252', 'F6563', 'L323', 'U6534', 'V231', 'Z252', 'Z5635') AND mc.company_id > 174983;