SELECT min(t.title) AS american_vhs_movie
FROM company_type AS ct, info_type AS it, movie_companies AS mc, movie_info AS mi, title AS t
WHERE t.id = mi.movie_id AND t.id = mc.movie_id AND mc.movie_id = mi.movie_id AND ct.id = mc.company_type_id AND it.id = mi.info_type_id
AND t.phonetic_code IS NOT NULL AND mc.movie_id IN (1179462, 1425036, 1754402, 1763839, 1853224, 2034830, 2053849, 2297224, 2476202, 910042) AND t.episode_of_id IS NOT NULL;