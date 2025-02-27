SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mi.movie_id IN (1023644, 1562326, 1865765, 1895752, 19794, 2199124, 2391121, 2397975, 37907, 549465) AND t.id > 1874616;