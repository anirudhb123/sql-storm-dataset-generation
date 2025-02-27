SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND ct.id IN (1, 2, 3, 4) AND t.episode_nr > 248 AND t.md5sum < 'd5ae635244585d970adcb5fe352d2cee';