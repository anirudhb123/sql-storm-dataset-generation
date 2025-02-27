SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mc.company_type_id > 1 AND t.season_nr < 1998 AND t.episode_of_id < 1131757 AND mc.movie_id < 2075612 AND t.series_years IS NOT NULL AND mc.company_id < 7092;