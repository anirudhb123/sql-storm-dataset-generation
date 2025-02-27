SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.episode_of_id > 1574787 AND t.season_nr IN (15, 16, 1998, 2011, 2012, 32, 42, 47, 65, 7) AND t.episode_nr IS NOT NULL;