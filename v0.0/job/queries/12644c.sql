SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.imdb_index = 'XX' AND mc.id > 1399993 AND ct.kind > 'miscellaneous companies' AND mi.id > 11144414 AND it.id < 92 AND mi.info > 'ESP 317,513 (Spain)';