SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.imdb_index LIKE '%IV%' AND mi.info_type_id IN (15, 17, 43, 46, 51, 61, 63, 65, 82, 86) AND t.phonetic_code LIKE '%4%';