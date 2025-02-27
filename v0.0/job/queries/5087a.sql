SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.title IN ('AD/BC: A Rock Opera', 'Ashita he no kaze', 'Cirque du sex 3', 'Ginban Kaleidoscope', 'Norm Macdonald: Me Doing Standup', 'Raymond Ceulemans', 'Squirt Hunter Vol. 1', 'The Man from Gadget', 'Una bellísima persona');