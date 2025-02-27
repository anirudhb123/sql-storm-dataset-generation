SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND it.info < 'birth notes' AND mc.company_type_id = 2 AND t.md5sum > 'ec809a88089b14e8be4fc03c79a47466' AND it.id > 105;