SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND mc.company_id < 55173 AND t.episode_of_id IS NOT NULL AND it.info > 'LD audio quality' AND t.season_nr IN (2009, 2011, 42, 51, 61, 62, 8);