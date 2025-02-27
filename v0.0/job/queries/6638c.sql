SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.md5sum < '4a4b4475f0c8fe70200a681c3eb56972' AND it.info < 'LD supplement' AND t.production_year < 1931 AND mc.company_type_id = 1;