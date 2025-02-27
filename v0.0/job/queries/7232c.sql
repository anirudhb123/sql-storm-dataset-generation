SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.phonetic_code > 'C465' AND t.episode_nr IS NOT NULL AND ct.kind IN ('distributors') AND mc.id IN (114152, 1575624, 1771732, 2015551, 2112317, 2499672, 2552252, 293378, 902856);