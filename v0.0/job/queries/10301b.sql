SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mc.note < '(2008) (Germany) (DVD) (Blu-ray) (HD DVD)' AND t.imdb_index IN ('II', 'IV', 'VI', 'VII', 'XIX', 'XXI') AND it.id IN (105, 30, 37, 46, 68, 70, 72);