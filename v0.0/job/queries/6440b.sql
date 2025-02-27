SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.episode_of_id < 1472965 AND t.title < 'Imperial Grand Strategy' AND t.episode_nr IN (12708, 12782, 1323, 15556, 2103, 5083, 7513, 8582);