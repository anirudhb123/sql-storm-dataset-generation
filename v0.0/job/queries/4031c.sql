SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.info IN ('62 hours of footage were shot for the film.') AND mc.note LIKE '%(1992%' AND mc.company_type_id IN (1, 2) AND t.kind_id > 0;