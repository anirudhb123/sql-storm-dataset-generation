SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND ct.kind LIKE '%tri%' AND mi.id > 9367130 AND t.imdb_index LIKE '%I%' AND mc.note < '(2006) (Romania) (TV) (original airing)';