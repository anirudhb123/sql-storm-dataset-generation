SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND ct.kind IN ('miscellaneous companies', 'production companies') AND mi.info > 'Filmed over two weekends in Wicklow, Ireland' AND t.imdb_index IS NOT NULL;