SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.info < 'Japan:18 August 1983' AND mc.company_type_id = 1 AND mc.movie_id > 1593091 AND mc.company_id IN (191633, 196252, 227239, 36015, 39362, 424, 70735, 73836, 9408);