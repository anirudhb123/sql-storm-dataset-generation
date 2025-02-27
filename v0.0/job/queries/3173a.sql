SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND it.id IN (110, 15, 28, 4, 45, 65, 71, 73, 90, 93) AND t.md5sum IS NOT NULL AND mi.info > 'Ukraine:14 May 2009';