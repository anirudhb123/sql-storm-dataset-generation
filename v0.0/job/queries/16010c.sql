SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.season_nr > 26 AND t.kind_id IN (0, 2, 3, 4, 7) AND t.episode_of_id IS NOT NULL AND t.episode_nr < 4548;