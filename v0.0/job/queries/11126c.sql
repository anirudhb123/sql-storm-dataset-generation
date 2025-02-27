SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.md5sum > '890356493c8ee3d1b0939725337a02c8' AND it.info LIKE '%process%' AND mi.info > 'Finland:17 September 1939' AND t.series_years IS NOT NULL;