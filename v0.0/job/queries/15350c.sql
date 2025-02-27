SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.title < 'On a Heroic Scale' AND t.episode_nr IN (11886, 13027, 13559, 173, 2671, 5920, 5988, 6461, 932, 984) AND ct.id > 1;